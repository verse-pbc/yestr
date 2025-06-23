import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'event_signer.dart';
import '../models/nostr_event.dart';

class ReactionService {
  final KeyManagementService _keyService = KeyManagementService();
  final NostrService _nostrService = NostrService();

  // Create a reaction event (kind 7) for a like
  Future<bool> likePost(NostrEvent targetEvent) async {
    try {
      // Check if user is logged in
      final privateKeyHex = await _keyService.getPrivateKeyHex();
      final publicKeyHex = await _keyService.getPublicKeyHex();
      
      if (privateKeyHex == null || publicKeyHex == null) {
        print('ReactionService: User not logged in');
        return false;
      }

      // Create reaction event data
      final eventData = {
        'pubkey': publicKeyHex,
        'kind': 7, // Reaction event
        'tags': [
          ['e', targetEvent.id], // Reference to the event being reacted to
          ['p', targetEvent.pubkey], // Reference to the author of the event
        ],
        'content': '+', // '+' is the standard for likes in Nostr
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      // Sign the event
      final signedEvent = await EventSigner.createSignedEvent(
        privateKeyHex: privateKeyHex,
        publicKeyHex: publicKeyHex,
        kind: 7,
        content: '+',
        tags: eventData['tags'] as List<List<String>>,
      );

      if (signedEvent == null) {
        print('ReactionService: Failed to sign reaction event');
        return false;
      }

      // Publish the reaction event
      final success = await _nostrService.publishEvent(signedEvent);
      
      if (success) {
        print('ReactionService: Successfully published like for event ${targetEvent.id}');
      } else {
        print('ReactionService: Failed to publish like');
      }
      
      return success;
    } catch (e) {
      print('ReactionService: Error liking post: $e');
      return false;
    }
  }

  // Get reactions for a specific event
  Stream<Map<String, int>> getReactionsForEvent(String eventId) {
    // This would query for kind 7 events that reference the given event ID
    // For now, we'll return an empty stream
    // TODO: Implement reaction counting
    return Stream.value({'likes': 0});
  }

  // Check if current user has liked a specific event
  Future<bool> hasUserLiked(String eventId) async {
    try {
      final publicKeyHex = await _keyService.getPublicKeyHex();
      if (publicKeyHex == null) return false;

      // TODO: Query for existing reaction from current user
      // For now, return false
      return false;
    } catch (e) {
      print('ReactionService: Error checking if user liked: $e');
      return false;
    }
  }
}