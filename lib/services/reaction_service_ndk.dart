import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:flutter/foundation.dart';
import 'ndk_backup/ndk_service.dart';
import 'key_management_service.dart';
import '../models/nostr_event.dart';

/// NDK-based ReactionService for handling likes, reposts, and other reactions
class ReactionServiceNdk {
  final NdkService _ndkService = NdkService.instance;
  final KeyManagementService _keyService = KeyManagementService();
  
  // Cache for user's reactions
  final Map<String, String> _userReactions = {}; // eventId -> reaction content
  
  // Singleton pattern
  static final ReactionServiceNdk _instance = ReactionServiceNdk._internal();
  factory ReactionServiceNdk() => _instance;
  
  ReactionServiceNdk._internal() {
    _initialize();
  }

  /// Initialize the service
  Future<void> _initialize() async {
    // Initialize NDK if not already done
    if (!_ndkService.isInitialized) {
      await _ndkService.initialize();
    }
  }

  /// Create a reaction event (kind 7) for a like
  Future<bool> likePost(NostrEvent targetEvent) async {
    try {
      // Check if user is logged in
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('ReactionService: User not logged in');
        }
        return false;
      }

      final ndk = _ndkService.ndk;
      
      // Create reaction event
      final reactionEvent = Nip01Event(
        kind: 7, // Reaction event
        content: '+', // '+' is the standard for likes in Nostr
        tags: [
          ['e', targetEvent.id], // Reference to the event being reacted to
          ['p', targetEvent.pubkey], // Reference to the author of the event
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: ndk.accounts.getPublicKey() ?? '',
      );

      if (kDebugMode) {
        print('📤 Broadcasting reaction with outbox model:');
        print('  Event: ${targetEvent.id}');
        print('  Target author: ${targetEvent.pubkey}');
        print('  NDK will broadcast to:');
        print('    - Our write relays (outbox)');
        print('    - Target\'s read relays (inbox)');
      }
      
      // Sign and broadcast the event
      // NDK will automatically use outbox model:
      // 1. Publish to our write relays (outbox)
      // 2. Publish to the target's read relays (inbox) because of p-tag
      final broadcastResult = ndk.broadcast.broadcast(nostrEvent: reactionEvent);
      await broadcastResult.broadcastDoneFuture;
      
      final responses = await broadcastResult.broadcastDoneFuture;
      if (responses.any((r) => r.broadcastSuccessful)) {
        // Cache the reaction
        _userReactions[targetEvent.id] = '+';
        
        if (kDebugMode) {
          print('✅ Successfully published like using outbox model');
          print('  Successful relays: ${responses.where((r) => r.broadcastSuccessful).length}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to publish like');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReactionService: Error liking post: $e');
      }
      return false;
    }
  }

  /// Remove a like (delete reaction event)
  Future<bool> unlikePost(String eventId) async {
    try {
      if (!_ndkService.isLoggedIn) {
        return false;
      }

      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return false;

      // Find the reaction event to delete
      final reactionEvents = await ndk.requests.query(
        filters: [
          Filter(
            authors: [currentPubkey],
            kinds: [7],
            eTags: [eventId],
            limit: 1,
          ),
        ],
      ).stream.toList();

      if (reactionEvents.isEmpty) {
        return true; // No reaction to remove
      }

      // Create deletion event
      final deletionEvent = Nip01Event(
        kind: 5, // Deletion event
        content: 'Deleting reaction',
        tags: [
          ['e', reactionEvents.first.id], // Reference to the reaction event to delete
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: currentPubkey,
      );

      final broadcastResult = ndk.broadcast.broadcast(nostrEvent: deletionEvent);
      await broadcastResult.broadcastDoneFuture;
      
      final responses = await broadcastResult.broadcastDoneFuture;
      if (responses.any((r) => r.broadcastSuccessful)) {
        _userReactions.remove(eventId);
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('ReactionService: Error unliking post: $e');
      }
      return false;
    }
  }

  /// Create a repost event (kind 6) 
  Future<bool> repostNote(NostrEvent targetEvent) async {
    try {
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('ReactionService: User not logged in');
        }
        return false;
      }

      final ndk = _ndkService.ndk;
      
      // Create repost event
      final repostEvent = Nip01Event(
        kind: 6, // Repost event
        content: '', // Content is typically empty for reposts
        tags: [
          ['e', targetEvent.id, ''], // Reference to the event being reposted
          ['p', targetEvent.pubkey], // Reference to the author of the original event
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pubKey: ndk.accounts.getPublicKey() ?? '',
      );

      // Sign and broadcast the event
      final broadcastResult = ndk.broadcast.broadcast(nostrEvent: repostEvent);
      await broadcastResult.broadcastDoneFuture;
      
      final responses = await broadcastResult.broadcastDoneFuture;
      if (responses.any((r) => r.broadcastSuccessful)) {
        if (kDebugMode) {
          print('ReactionService: Successfully published repost for event ${targetEvent.id}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('ReactionService: Failed to publish repost');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ReactionService: Error reposting: $e');
      }
      return false;
    }
  }

  /// Get reactions for a specific event
  Stream<Map<String, dynamic>> getReactionsForEvent(String eventId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      
      // Track reaction counts
      final reactionCounts = <String, int>{};
      final reactors = <String, Set<String>>{}; // reaction -> set of pubkeys
      
      // Subscribe to reactions for this event
      final subscription = ndk.requests.query(
        filters: [
          Filter(
            kinds: [7], // Reaction events
            eTags: [eventId],
          ),
        ],
      ).stream.listen((event) {
        final content = event.content;
        reactionCounts[content] = (reactionCounts[content] ?? 0) + 1;
        
        // Track who reacted
        reactors[content] ??= {};
        reactors[content]!.add(event.pubKey);
        
        // Emit updated counts
        controller.add({
          'counts': Map<String, int>.from(reactionCounts),
          'reactors': Map<String, Set<String>>.from(reactors),
          'total': reactionCounts.values.fold(0, (sum, count) => sum + count),
        });
      });
      
      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      controller.addError('Error getting reactions: $e');
    }
    
    return controller.stream;
  }

  /// Check if current user has liked a specific event
  Future<bool> hasUserLiked(String eventId) async {
    try {
      if (!_ndkService.isLoggedIn) return false;
      
      // Check cache first
      if (_userReactions.containsKey(eventId)) {
        return _userReactions[eventId] == '+';
      }
      
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return false;

      // Query for existing reaction from current user
      final reactions = await ndk.requests.query(
        filters: [
          Filter(
            authors: [currentPubkey],
            kinds: [7],
            eTags: [eventId],
            limit: 1,
          ),
        ],
      ).stream.toList();
      
      final hasLiked = reactions.any((event) => event.content == '+');
      
      // Update cache
      if (hasLiked) {
        _userReactions[eventId] = '+';
      }
      
      return hasLiked;
    } catch (e) {
      if (kDebugMode) {
        print('ReactionService: Error checking if user liked: $e');
      }
      return false;
    }
  }

  /// Get all reactions by the current user
  Future<Map<String, String>> getUserReactions() async {
    try {
      if (!_ndkService.isLoggedIn) return {};
      
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return {};

      // Query for all reactions by current user
      final reactions = await ndk.requests.query(
        filters: [
          Filter(
            authors: [currentPubkey],
            kinds: [7],
          ),
        ],
      ).stream.toList();
      
      // Update cache
      _userReactions.clear();
      for (final event in reactions) {
        // Get the event ID from e tag
        final eTags = event.tags.where((tag) => tag[0] == 'e').toList();
        if (eTags.isNotEmpty) {
          _userReactions[eTags.first[1]] = event.content;
        }
      }
      
      return Map.from(_userReactions);
    } catch (e) {
      if (kDebugMode) {
        print('ReactionService: Error getting user reactions: $e');
      }
      return {};
    }
  }

  /// Subscribe to reaction updates for a specific event
  Stream<ReactionUpdate> subscribeToReactions(String eventId) {
    final controller = StreamController<ReactionUpdate>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      
      // Subscribe to new reactions
      final subscription = ndk.requests.query(
        filters: [
          Filter(
            kinds: [7], // Reactions
            eTags: [eventId],
          ),
        ],
      ).stream.listen((event) {
        controller.add(ReactionUpdate(
          eventId: eventId,
          reaction: event.content,
          pubkey: event.pubKey,
          timestamp: event.createdAt,
        ));
      });
      
      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      controller.addError('Error subscribing to reactions: $e');
    }
    
    return controller.stream;
  }

  /// Clear cached reactions (e.g., on logout)
  void clearCache() {
    _userReactions.clear();
  }
}

/// Represents a reaction update
class ReactionUpdate {
  final String eventId;
  final String reaction;
  final String pubkey;
  final int timestamp;

  ReactionUpdate({
    required this.eventId,
    required this.reaction,
    required this.pubkey,
    required this.timestamp,
  });
}