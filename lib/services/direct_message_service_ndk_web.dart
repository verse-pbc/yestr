import 'dart:async';
import 'dart:convert';
import 'package:ndk/ndk.dart';
import 'package:flutter/foundation.dart';
import '../models/direct_message.dart';
import '../models/conversation.dart';
import 'key_management_service.dart';
import 'ndk_backup/ndk_service.dart';
import 'ndk_backup/ndk_service_web.dart';

/// Direct Message Service that works with both regular NDK and web NDK
class DirectMessageServiceNdkWeb {
  final dynamic _ndkService; // Can be NdkService or NdkServiceWeb
  final KeyManagementService _keyManagementService;
  
  // Streams for real-time updates
  final _messageStreamController = StreamController<DirectMessage>.broadcast();
  final _conversationStreamController = StreamController<List<Conversation>>.broadcast();
  
  Stream<DirectMessage> get messageStream => _messageStreamController.stream;
  Stream<List<Conversation>> get conversationStream => _conversationStreamController.stream;
  
  DirectMessageServiceNdkWeb(this._ndkService, this._keyManagementService);
  
  /// Get the NDK instance from either service type
  Ndk get _ndk {
    if (_ndkService is NdkService) {
      return (_ndkService as NdkService).ndk;
    } else if (_ndkService is NdkServiceWeb) {
      return (_ndkService as NdkServiceWeb).ndk;
    }
    throw Exception('Invalid NDK service type');
  }
  
  /// Send a gift-wrapped direct message (NIP-59)
  Future<void> sendDirectMessage(String recipientPubkey, String message) async {
    try {
      final ndk = _ndk;
      final publicKey = await _keyManagementService.getPublicKey();
      
      if (publicKey == null) {
        throw Exception('No public key available');
      }
      
      // Create a rumor (unsigned event) for the DM
      final rumor = await ndk.giftWrap.createRumor(
        kind: 14, // NIP-17 DM kind
        content: message,
        tags: [
          ['p', recipientPubkey]
        ],
      );
      
      // Wrap the rumor as a gift wrap
      final giftWrappedEvent = await ndk.giftWrap.toGiftWrap(
        rumor: rumor,
        recipientPubkey: recipientPubkey,
      );
      
      // Broadcast the gift-wrapped message
      await ndk.broadcast.broadcast(
        nostrEvent: giftWrappedEvent,
      ).broadcastDoneFuture;
      
      // Create a local message object
      final directMessage = DirectMessage(
        id: rumor.id ?? '',
        senderPubkey: publicKey,
        recipientPubkey: recipientPubkey,
        content: message,
        createdAt: DateTime.now(),
        isFromMe: true,
      );
      
      // Emit to stream
      _messageStreamController.add(directMessage);
      
      print('[NDK DM Service] Gift-wrapped message sent successfully');
    } catch (e) {
      print('[NDK DM Service] Error sending gift-wrapped message: $e');
      rethrow;
    }
  }
  
  /// Subscribe to incoming gift-wrapped messages
  Future<void> subscribeToDirectMessages() async {
    try {
      final ndk = _ndk;
      final publicKey = await _keyManagementService.getPublicKey();
      
      if (publicKey == null) {
        throw Exception('No public key available');
      }
      
      // Subscribe to gift wrap events (kind 1059) for current user
      final filter = Filter(
        kinds: [1059], // Gift wrap kind
        pTags: [publicKey], // Messages for current user
      );
      
      final response = ndk.requests.subscription(
        filters: [filter],
        name: 'incoming-gift-wraps',
      );
      
      response.stream.listen((event) async {
        try {
          // Unwrap the gift wrap to get the actual message
          final unwrapped = await ndk.giftWrap.fromGiftWrap(
            giftWrap: event,
          );
          
          // Extract sender from tags or use event author
          String? senderPubkey;
          for (final tag in unwrapped.tags) {
            if (tag.length >= 2 && tag[0] == 'p' && tag[1] != publicKey) {
              senderPubkey = tag[1];
              break;
            }
          }
          senderPubkey ??= unwrapped.pubKey;
          
          // Create DirectMessage object
          final message = DirectMessage(
            id: unwrapped.id ?? '',
            senderPubkey: senderPubkey,
            recipientPubkey: publicKey,
            content: unwrapped.content,
            createdAt: DateTime.fromMillisecondsSinceEpoch(unwrapped.createdAt * 1000),
            isFromMe: false,
          );
          
          // Emit to stream
          _messageStreamController.add(message);
          
          print('[NDK DM Service] Received gift-wrapped message from $senderPubkey');
        } catch (e) {
          print('[NDK DM Service] Error processing gift-wrapped message: $e');
        }
      });
      
      print('[NDK DM Service] Subscribed to gift-wrapped messages');
    } catch (e) {
      print('[NDK DM Service] Error subscribing to messages: $e');
      rethrow;
    }
  }
  
  /// Load conversations (simplified version)
  Future<List<Conversation>> loadConversations() async {
    // This would need to be implemented to fetch and group messages
    // For now, return empty list
    return [];
  }
  
  /// Clean up resources
  void dispose() {
    _messageStreamController.close();
    _conversationStreamController.close();
  }
}