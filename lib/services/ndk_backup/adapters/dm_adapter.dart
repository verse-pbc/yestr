import 'dart:async';
import 'package:ndk/ndk.dart';
import '../../../models/direct_message.dart';
import '../ndk_service.dart';

/// Adapter to handle direct messages using NDK's gift wrap functionality
class DmAdapter {
  final NdkService _ndkService;
  final Map<String, StreamSubscription> _subscriptions = {};
  
  DmAdapter(this._ndkService);
  
  /// Send a direct message using NDK's gift wrap (NIP-17)
  Future<DirectMessage?> sendMessage({
    required String recipientPubkey,
    required String content,
  }) async {
    try {
      final ndk = _ndkService.ndk;
      
      // Create and send gift wrapped message
      final rumor = await ndk.giftWrap.createRumor(
        kind: 14, // NIP-17 DM kind
        content: content,
        tags: [
          ['p', recipientPubkey]
        ],
      );
      
      await ndk.giftWrap.wrapAndBroadcast(
        rumor: rumor,
        receiverPubkeys: [recipientPubkey],
      );
      
      // Create DirectMessage from the sent rumor
      return DirectMessage(
        id: rumor.id ?? '',
        pubkey: ndk.accounts.currentAccount!.pubkey,
        recipientPubkey: recipientPubkey,
        content: content,
        createdAt: DateTime.now(),
        tags: rumor.tags,
      );
    } catch (e) {
      print('Error sending direct message: $e');
      return null;
    }
  }
  
  /// Subscribe to incoming messages
  Stream<DirectMessage> subscribeToMessages() {
    final controller = StreamController<DirectMessage>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) {
        controller.addError('No logged in user');
        return controller.stream;
      }
      
      // Subscribe to gift wrapped messages
      final subscription = ndk.giftWrap.subscribeToIncomingEvents(
        kinds: [14], // NIP-17 DM kind
      ).listen((giftWrap) {
        try {
          // Extract sender pubkey from tags
          String? senderPubkey;
          for (final tag in giftWrap.tags) {
            if (tag.length >= 2 && tag[0] == 'p' && tag[1] != currentPubkey) {
              senderPubkey = tag[1];
              break;
            }
          }
          
          if (senderPubkey == null) {
            // If no other pubkey in tags, sender is the gift wrap author
            senderPubkey = giftWrap.author;
          }
          
          final message = DirectMessage(
            id: giftWrap.id ?? '',
            pubkey: senderPubkey,
            recipientPubkey: currentPubkey,
            content: giftWrap.content,
            createdAt: DateTime.fromMillisecondsSinceEpoch(giftWrap.createdAt * 1000),
            tags: giftWrap.tags,
          );
          
          controller.add(message);
        } catch (e) {
          print('Error processing gift wrapped message: $e');
        }
      });
      
      _subscriptions['messages'] = subscription;
    } catch (e) {
      controller.addError('Error subscribing to messages: $e');
    }
    
    controller.onCancel = () {
      _subscriptions['messages']?.cancel();
      _subscriptions.remove('messages');
    };
    
    return controller.stream;
  }
  
  /// Fetch message history with a specific user
  Future<List<DirectMessage>> fetchMessageHistory({
    required String otherPubkey,
    int limit = 50,
  }) async {
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) return [];
      
      final messages = <DirectMessage>[];
      
      // Fetch gift wrapped messages
      final events = await ndk.giftWrap.fetchIncomingEvents(
        kinds: [14], // NIP-17 DM kind
        limit: limit,
      );
      
      for (final event in events) {
        try {
          // Check if this message involves the other pubkey
          bool involvesOtherPubkey = false;
          String? senderPubkey;
          
          for (final tag in event.tags) {
            if (tag.length >= 2 && tag[0] == 'p') {
              if (tag[1] == otherPubkey) {
                involvesOtherPubkey = true;
              }
              if (tag[1] != currentPubkey) {
                senderPubkey = tag[1];
              }
            }
          }
          
          // Also check if the author is the other pubkey
          if (event.author == otherPubkey) {
            involvesOtherPubkey = true;
            senderPubkey = otherPubkey;
          }
          
          if (involvesOtherPubkey) {
            final message = DirectMessage(
              id: event.id ?? '',
              pubkey: senderPubkey ?? event.author,
              recipientPubkey: currentPubkey,
              content: event.content,
              createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
              tags: event.tags,
            );
            messages.add(message);
          }
        } catch (e) {
          print('Error processing historical message: $e');
        }
      }
      
      // Sort by created date
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return messages;
    } catch (e) {
      print('Error fetching message history: $e');
      return [];
    }
  }
  
  /// Dispose all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}