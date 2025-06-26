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
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) return {};
      
      final contactList = await ndk.follows.getContactList(currentPubkey);
      
      if (contactList == null) return {};
      
      return contactList.contacts.map((contact) => contact.pubkey).toSet();
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
            kinds: [ContactList.KIND],
            pTags: [pubkey],
          ),
        ],
      ).stream.toList();
      
      return events.map((event) => event.pubkey).toSet();
    } catch (e) {
      print('Error getting followers: $e');
      return {};
    }
  }
  
  /// Follow a user
  Future<bool> followUser(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) return false;
      
      // Get current contact list
      final currentContacts = await ndk.follows.getContactList(currentPubkey);
      
      // Create new contact to add
      final newContact = Contact(
        pubkey: pubkey,
        relay: null, // Let NDK figure out the best relay
        petname: null,
      );
      
      // Add to contacts
      final updatedContacts = currentContacts?.contacts.toList() ?? [];
      
      // Check if already following
      if (updatedContacts.any((c) => c.pubkey == pubkey)) {
        return true; // Already following
      }
      
      updatedContacts.add(newContact);
      
      // Broadcast updated contact list
      await ndk.follows.broadcastContactList(
        ContactList(
          contacts: updatedContacts,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
      
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
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) return false;
      
      // Get current contact list
      final currentContacts = await ndk.follows.getContactList(currentPubkey);
      
      if (currentContacts == null) return false;
      
      // Remove from contacts
      final updatedContacts = currentContacts.contacts
          .where((contact) => contact.pubkey != pubkey)
          .toList();
      
      // Broadcast updated contact list
      await ndk.follows.broadcastContactList(
        ContactList(
          contacts: updatedContacts,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
      
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
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
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
      final currentPubkey = ndk.accounts.currentAccount?.pubkey;
      
      if (currentPubkey == null) {
        controller.addError('No logged in user');
        return controller.stream;
      }
      
      // Subscribe to contact list updates
      final subscription = ndk.requests.query(
        filters: [
          Filter(
            authors: [currentPubkey],
            kinds: [ContactList.KIND],
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