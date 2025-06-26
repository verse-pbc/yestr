/// Example usage of NDK Adapter Service
/// This file demonstrates how to use the NDK adapters in the app

import 'package:ndk/ndk.dart';
import 'ndk_adapter_service.dart';

class NdkUsageExample {
  final ndkAdapter = NdkAdapterService.instance;
  
  /// Example: Login with private key
  Future<void> loginExample() async {
    try {
      await ndkAdapter.login('your-private-key-hex');
      print('Logged in as: ${ndkAdapter.currentUserPubkey}');
    } catch (e) {
      print('Login failed: $e');
    }
  }
  
  /// Example: Fetch user profile
  Future<void> fetchProfileExample() async {
    final profile = await ndkAdapter.profiles.fetchProfile('pubkey-hex');
    if (profile != null) {
      print('Profile name: ${profile.name}');
      print('Profile picture: ${profile.picture}');
    }
  }
  
  /// Example: Send direct message
  Future<void> sendMessageExample() async {
    final message = await ndkAdapter.directMessages.sendMessage(
      recipientPubkey: 'recipient-pubkey-hex',
      content: 'Hello from NDK!',
    );
    
    if (message != null) {
      print('Message sent: ${message.id}');
    }
  }
  
  /// Example: Subscribe to incoming messages
  void subscribeToMessagesExample() {
    final stream = ndkAdapter.directMessages.subscribeToMessages();
    
    stream.listen((message) {
      print('New message from ${message.pubkey}: ${message.content}');
    });
  }
  
  /// Example: Follow a user
  Future<void> followUserExample() async {
    final success = await ndkAdapter.follows.followUser('pubkey-to-follow');
    if (success) {
      print('Successfully followed user');
    }
  }
  
  /// Example: Query text notes
  void queryTextNotesExample() {
    final stream = ndkAdapter.events.queryEvents(
      filters: [
        Filter(
          kinds: [1], // Text notes
          authors: ['author-pubkey'],
          limit: 20,
        ),
      ],
    );
    
    stream.listen((event) {
      print('Note: ${event.content}');
    });
  }
  
  /// Example: Subscribe to real-time updates
  void subscribeToRealtimeExample() {
    final stream = ndkAdapter.events.subscribeToEvents(
      filters: [
        Filter(
          kinds: [1], // Text notes
          since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ],
    );
    
    stream.listen((event) {
      print('New note from ${event.pubkey}: ${event.content}');
    });
  }
  
  /// Example: Publish a text note
  Future<void> publishNoteExample() async {
    final event = await ndkAdapter.events.publishTextNote(
      'Hello Nostr from NDK!',
      tags: [
        ['t', 'nostr'],
        ['t', 'ndk'],
      ],
    );
    
    if (event != null) {
      print('Note published: ${event.id}');
    }
  }
  
  /// Example: React to an event
  Future<void> reactToEventExample() async {
    final success = await ndkAdapter.events.reactToEvent(
      eventId: 'event-id-to-react-to',
      eventPubkey: 'event-author-pubkey',
      reaction: '❤️',
    );
    
    if (success) {
      print('Reaction sent');
    }
  }
  
  /// Example: Get mutual follows
  Future<void> getMutualFollowsExample() async {
    final mutuals = await ndkAdapter.follows.getMutualFollows();
    print('Mutual follows: ${mutuals.length}');
    
    for (final pubkey in mutuals) {
      final profile = await ndkAdapter.profiles.fetchProfile(pubkey);
      if (profile != null) {
        print('- ${profile.name}');
      }
    }
  }
  
  /// Example: Update user profile
  Future<void> updateProfileExample() async {
    final currentPubkey = ndkAdapter.currentUserPubkey;
    if (currentPubkey == null) return;
    
    // Fetch current profile
    final profile = await ndkAdapter.profiles.fetchProfile(currentPubkey);
    if (profile == null) return;
    
    // Update profile
    final updatedProfile = profile.copyWith(
      about: 'Updated bio using NDK!',
      website: 'https://example.com',
    );
    
    final success = await ndkAdapter.profiles.updateProfile(updatedProfile);
    if (success) {
      print('Profile updated successfully');
    }
  }
}