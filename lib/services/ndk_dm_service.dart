import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as ndk_entities;
import 'package:ndk/domain_layer/entities/filter.dart' as ndk_filter;
import '../models/nostr_profile.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';

/// Direct Message Service using NDK's built-in NIP-17 gift wrap support
class NDKDmService {
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();

  NDKDmService(this._keyManagementService);
  
  /// Get NDK instance from NostrService
  Ndk get _ndk => _nostrService.ndk;

  /// Send a direct message using NIP-17 (gift wrapped)
  Future<bool> sendDirectMessage(String content, NostrProfile recipient) async {
    print('[NDK DM] Starting sendDirectMessage...');
    print('[NDK DM] Content: "$content"');
    print('[NDK DM] Recipient: ${recipient.displayNameOrName} (${recipient.pubkey})');
    
    try {
      // Check if user is logged in
      final hasPrivateKey = await _keyManagementService.hasPrivateKey();
      if (!hasPrivateKey) {
        throw Exception('You must be logged in to send messages');
      }

      // Get sender's keys
      final privateKey = await _keyManagementService.getPrivateKey();
      final publicKey = await _keyManagementService.getPublicKey();
      if (privateKey == null || publicKey == null) {
        throw Exception('Unable to get sender keys');
      }
      
      // Login to NDK with private key
      _ndk.accounts.loginPrivateKey(
        pubkey: publicKey,
        privkey: privateKey,
      );
      
      // Ensure NostrService is connected
      if (!_nostrService.isConnected) {
        await _nostrService.connect();
      }

      // Create the rumor (unsigned chat message)
      print('[NDK DM] Creating rumor event...');
      final rumor = await _ndk.giftWrap.createRumor(
        kind: 14, // Chat message
        content: content,
        tags: [
          ['p', recipient.pubkey],
        ],
        customPubkey: publicKey,
      );
      
      print('[NDK DM] Rumor created');

      // Wrap the rumor for the recipient
      print('[NDK DM] Creating gift wrap for recipient...');
      final giftWrap = await _ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipient.pubkey,
      );
      
      print('[NDK DM] Gift wrap created with id: ${giftWrap.id}');

      // Publish the gift wrap
      print('[NDK DM] Publishing gift wrap...');
      final response = _ndk.broadcast.broadcast(
        nostrEvent: giftWrap,
      );
      
      // Wait for broadcast to complete
      await response.broadcastDoneFuture;
      final published = true;
      
      if (published) {
        print('[NDK DM] ✓ Successfully published gift wrap');
        
        // Also create a copy for the sender (so they can see their sent messages)
        print('[NDK DM] Creating gift wrap for sender...');
        final senderGiftWrap = await _ndk.giftWrap.toGiftWrap(
          rumor: rumor,
          recipientPubkey: publicKey, // Wrap for sender
        );
        
        final senderResponse = _ndk.broadcast.broadcast(
          nostrEvent: senderGiftWrap,
        );
        await senderResponse.broadcastDoneFuture;
        print('[NDK DM] ✓ Published copy for sender');
      }
      
      print('[NDK DM] Message sent successfully');
      return published;
    } catch (e) {
      print('[NDK DM] ERROR in sendDirectMessage: $e');
      print('[NDK DM] Stack trace: ${StackTrace.current}');
      return false;
    }
  }
  
  /// Receive and unwrap gift wrapped messages
  Stream<DirectMessage> receiveDirectMessages() async* {
    try {
      // Get user's public key
      final publicKey = await _keyManagementService.getPublicKey();
      final privateKey = await _keyManagementService.getPrivateKey();
      if (publicKey == null || privateKey == null) {
        throw Exception('No keys available');
      }
      
      // Login to NDK
      _ndk.accounts.loginPrivateKey(
        pubkey: publicKey,
        privkey: privateKey,
      );
      
      // Subscribe to gift wrap events (kind 1059) where we are tagged
      final filter = ndk_filter.Filter(
        kinds: [1059], // Gift wrap
        pTags: [publicKey],
      );
      
      // Query for existing messages
      final response = _ndk.requests.query(
        filters: [filter],
      );
      
      final events = <ndk_entities.Nip01Event>[];
      await for (final event in response.stream) {
        events.add(event);
      }
      await Future.delayed(const Duration(seconds: 5)); // Timeout simulation
      
      print('[NDK DM] Found ${events.length} gift wrap events');
      
      for (final giftWrap in events) {
        try {
          // Unwrap the gift wrap
          final unwrapped = await _ndk.giftWrap.fromGiftWrap(
            giftWrap: giftWrap,
          );
          
          if (unwrapped != null && unwrapped.kind == 14) {
            // Extract sender from p tag (first p tag is the recipient)
            String? senderPubkey;
            for (final tag in unwrapped.tags) {
              if (tag.length >= 2 && tag[0] == 'p' && tag[1] != publicKey) {
                senderPubkey = tag[1];
                break;
              }
            }
            
            yield DirectMessage(
              id: unwrapped.id,
              content: unwrapped.content,
              senderPubkey: senderPubkey ?? unwrapped.pubKey,
              recipientPubkey: publicKey,
              createdAt: unwrapped.createdAt,
            );
          }
        } catch (e) {
          print('[NDK DM] Error unwrapping gift wrap: $e');
        }
      }
      
      // Create a stream controller for new messages
      final StreamController<DirectMessage> messageController = StreamController<DirectMessage>();
      
      // Subscribe to new messages
      final subscription = _ndk.requests.subscription(
        filters: [filter],
      );
      
      subscription.stream.listen((giftWrap) async {
        try {
          if (giftWrap.kind == 1059 && giftWrap.tags.any((tag) => 
              tag.length >= 2 && tag[0] == 'p' && tag[1] == publicKey)) {
            final unwrapped = await _ndk.giftWrap.fromGiftWrap(
              giftWrap: giftWrap,
            );
            
            if (unwrapped != null && unwrapped.kind == 14) {
              String? senderPubkey;
              for (final tag in unwrapped.tags) {
                if (tag.length >= 2 && tag[0] == 'p' && tag[1] != publicKey) {
                  senderPubkey = tag[1];
                  break;
                }
              }
              
              messageController.add(DirectMessage(
                id: unwrapped.id,
                content: unwrapped.content,
                senderPubkey: senderPubkey ?? unwrapped.pubKey,
                recipientPubkey: publicKey,
                createdAt: unwrapped.createdAt,
              ));
            }
          }
        } catch (e) {
          print('[NDK DM] Error unwrapping new gift wrap: $e');
        }
      });
      
      // Handle cleanup when stream is cancelled
      messageController.onCancel = () {
        // Note: NDK handles subscription cleanup automatically
        messageController.close();
      };
      
      // Yield from the message controller stream
      yield* messageController.stream;
    } catch (e) {
      print('[NDK DM] Error in receiveDirectMessages: $e');
      yield* Stream.empty();
    }
  }
}

/// Direct Message model
class DirectMessage {
  final String id;
  final String content;
  final String senderPubkey;
  final String recipientPubkey;
  final int createdAt;
  
  DirectMessage({
    required this.id,
    required this.content,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.createdAt,
  });
  
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
}