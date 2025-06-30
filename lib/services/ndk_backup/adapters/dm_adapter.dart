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
      
      // Wrap the rumor
      final giftWrappedEvent = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientPubkey,
      );
      
      // Broadcast the wrapped event
      await ndk.broadcast.broadcast(
        nostrEvent: giftWrappedEvent,
      );
      
      // Create DirectMessage from the sent rumor
      return DirectMessage(
        id: rumor.id ?? '',
        senderPubkey: ndk.accounts.getPublicKey() ?? '',
        isFromMe: true,
        recipientPubkey: recipientPubkey,
        content: content,
        createdAt: DateTime.now(),
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
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) {
        controller.addError('No logged in user');
        return controller.stream;
      }
      
      // Subscribe to gift wrapped messages
      final filter = Filter(
        kinds: [1059], // Gift wrap kind
        pTags: [currentPubkey], // Messages for current user
      );
      
      final response = ndk.requests.subscription(
        filters: [filter],
        name: 'incoming-gift-wraps',
      );
      
      final subscription = response.stream.listen((event) async {
        try {
          // Extract sender pubkey from tags
          String? senderPubkey;
          for (final tag in event.tags) {
            if (tag.length >= 2 && tag[0] == 'p' && tag[1] != currentPubkey) {
              senderPubkey = tag[1];
              break;
            }
          }
          
          // Unwrap the gift wrap to get the actual message
          final unwrapped = await ndk.giftWrap.fromGiftWrap(
            giftWrap: event,
          );
          
          if (senderPubkey == null) {
            // Use the pubkey from the unwrapped event
            senderPubkey = unwrapped.pubKey;
          }
          
          final message = DirectMessage(
            id: unwrapped.id ?? '',
            senderPubkey: senderPubkey,
            recipientPubkey: currentPubkey,
            content: unwrapped.content,
            createdAt: DateTime.fromMillisecondsSinceEpoch(unwrapped.createdAt * 1000),
            isFromMe: senderPubkey == currentPubkey,
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
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return [];
      
      final messages = <DirectMessage>[];
      
      // Fetch gift wrapped messages
      final filter = Filter(
        kinds: [1059], // Gift wrap kind
        pTags: [currentPubkey, otherPubkey], // Messages involving both users
        limit: limit,
      );
      
      final response = await ndk.requests.query(
        filters: [filter],
        name: 'fetch-gift-wraps',
      );
      
      final events = await response.stream.toList();
      
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
          
          // Unwrap the gift wrap to get the actual message
          final unwrapped = await ndk.giftWrap.fromGiftWrap(
            giftWrap: event,
          );
          
          // Also check if the author is the other pubkey
          if (unwrapped.pubKey == otherPubkey) {
            involvesOtherPubkey = true;
            senderPubkey = otherPubkey;
          }
          
          if (involvesOtherPubkey) {
            final message = DirectMessage(
              id: unwrapped.id ?? '',
              senderPubkey: senderPubkey ?? unwrapped.pubKey,
              isFromMe: (senderPubkey ?? unwrapped.pubKey) == currentPubkey,
              recipientPubkey: currentPubkey,
              content: unwrapped.content,
              createdAt: DateTime.fromMillisecondsSinceEpoch(unwrapped.createdAt * 1000),
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