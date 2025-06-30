import 'dart:async';
import 'package:ndk/ndk.dart';
import '../ndk_service.dart';

/// Adapter to handle follow/unfollow operations using NDK
class FollowAdapter {
  final NdkService _ndkService;
  
  FollowAdapter(this._ndkService);
  
  /// Get the list of pubkeys that the current user follows
  Future<Set<String>> getFollowing() async {
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return {};
      
      final contactList = await ndk.follows.getContactList(currentPubkey);
      
      if (contactList == null) return {};
      
      return contactList.contacts.toSet();
    } catch (e) {
      print('Error getting following list: $e');
      return {};
    }
  }
  
  /// Get the list of pubkeys that follow a specific user
  Future<Set<String>> getFollowers(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      
      // Query for all contact lists that include this pubkey
      final events = await ndk.requests.query(
        filters: [
          Filter(
            kinds: [ContactList.kKind],
            pTags: [pubkey],
          ),
        ],
      ).stream.toList();
      
      return events.map((event) => event.pubKey).toSet();
    } catch (e) {
      print('Error getting followers: $e');
      return {};
    }
  }
  
  /// Follow a user
  Future<bool> followUser(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      
      print('📤 Following user with outbox model:');
      print('  Target: $pubkey');
      print('  Using NDK JIT engine to broadcast to user\'s write relays');
      
      // Use NDK's built-in method to add a contact
      // This will automatically use the outbox model to publish to the user's write relays
      await ndk.follows.broadcastAddContact(pubkey);
      
      print('✅ Follow event broadcast using outbox model');
      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }
  
  /// Unfollow a user
  Future<bool> unfollowUser(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      
      // Use NDK's built-in method to remove a contact
      await ndk.follows.broadcastRemoveContact(pubkey);
      
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }
  
  /// Check if current user follows a specific pubkey
  Future<bool> isFollowing(String pubkey) async {
    try {
      final following = await getFollowing();
      return following.contains(pubkey);
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }
  
  /// Get mutual follows (users who follow each other)
  Future<Set<String>> getMutualFollows() async {
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) return {};
      
      // Get who we follow
      final following = await getFollowing();
      
      // Get who follows us
      final followers = await getFollowers(currentPubkey);
      
      // Find intersection
      return following.intersection(followers);
    } catch (e) {
      print('Error getting mutual follows: $e');
      return {};
    }
  }
  
  /// Subscribe to contact list updates
  Stream<ContactList> subscribeToContactListUpdates() {
    final controller = StreamController<ContactList>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.getPublicKey();
      
      if (currentPubkey == null) {
        controller.addError('No logged in user');
        return controller.stream;
      }
      
      // Subscribe to contact list updates
      final subscription = ndk.requests.query(
        filters: [
          Filter(
            authors: [currentPubkey],
            kinds: [ContactList.kKind],
          ),
        ],
      ).stream.listen((event) {
        try {
          final contactList = ContactList.fromEvent(event);
          controller.add(contactList);
        } catch (e) {
          print('Error parsing contact list event: $e');
        }
      });
      
      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      controller.addError('Error subscribing to contact list: $e');
    }
    
    return controller.stream;
  }
}