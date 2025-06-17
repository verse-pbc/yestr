import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';

class FollowService {
  static const String _followedProfilesKey = 'followed_profiles';
  
  final KeyManagementService _keyService = KeyManagementService();
  final NostrService _nostrService = NostrService();
  
  // Store followed profiles locally
  final Set<String> _followedProfiles = {};
  
  // Singleton pattern
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal() {
    _loadFollowedProfiles();
  }

  /// Get the set of followed profiles
  Set<String> get followedProfiles => Set.from(_followedProfiles);

  /// Load followed profiles from local storage
  Future<void> _loadFollowedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_followedProfilesKey);
      if (stored != null) {
        _followedProfiles.addAll(stored);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading followed profiles: $e');
      }
    }
  }

  /// Save followed profiles to local storage
  Future<void> _saveFollowedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_followedProfilesKey, _followedProfiles.toList());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving followed profiles: $e');
      }
    }
  }

  /// Check if a profile is followed
  bool isFollowing(String pubkey) {
    return _followedProfiles.contains(pubkey);
  }

  /// Toggle follow status for a profile
  Future<bool> toggleFollow(String pubkey) async {
    if (isFollowing(pubkey)) {
      return await unfollowProfile(pubkey);
    } else {
      return await followProfile(pubkey);
    }
  }

  /// Follow a profile
  Future<bool> followProfile(String pubkey) async {
    try {
      // Check if user is logged in
      final hasKey = await _keyService.hasPrivateKey();
      if (!hasKey) {
        if (kDebugMode) {
          print('Cannot follow: User not logged in');
        }
        return false;
      }

      // Add to local set
      _followedProfiles.add(pubkey);
      await _saveFollowedProfiles();

      // Publish follow event
      await _publishContactList();
      
      if (kDebugMode) {
        print('Successfully followed: $pubkey');
      }
      return true;
    } catch (e) {
      // Revert on error
      _followedProfiles.remove(pubkey);
      await _saveFollowedProfiles();
      
      if (kDebugMode) {
        print('Error following profile: $e');
      }
      return false;
    }
  }

  /// Unfollow a profile
  Future<bool> unfollowProfile(String pubkey) async {
    try {
      // Check if user is logged in
      final hasKey = await _keyService.hasPrivateKey();
      if (!hasKey) {
        if (kDebugMode) {
          print('Cannot unfollow: User not logged in');
        }
        return false;
      }

      // Remove from local set
      _followedProfiles.remove(pubkey);
      await _saveFollowedProfiles();

      // Publish updated contact list
      await _publishContactList();
      
      if (kDebugMode) {
        print('Successfully unfollowed: $pubkey');
      }
      return true;
    } catch (e) {
      // Revert on error
      _followedProfiles.add(pubkey);
      await _saveFollowedProfiles();
      
      if (kDebugMode) {
        print('Error unfollowing profile: $e');
      }
      return false;
    }
  }

  /// Publish contact list event (kind 3) to relays
  Future<void> _publishContactList() async {
    try {
      // Get keys for signing
      final keys = await _keyService.getKeys();
      if (keys == null) {
        throw Exception('No keys available');
      }

      // For now, just log the action
      // In a real implementation, you would:
      // 1. Create the event with proper signing
      // 2. Send it to relays
      
      if (kDebugMode) {
        print('Would publish contact list with ${_followedProfiles.length} contacts');
        print('User pubkey: ${keys['public']}');
      }
      
      // Note: dart_nostr v4.0.0 has limitations for creating events from existing keys
      // This is a simplified implementation for demonstration
      
    } catch (e) {
      if (kDebugMode) {
        print('Error publishing contact list: $e');
      }
      throw e;
    }
  }

  /// Load contact list from relays for the current user
  Future<void> loadContactListFromRelays() async {
    try {
      final currentUserPubkey = await _keyService.getPublicKey();
      if (currentUserPubkey == null) {
        if (kDebugMode) {
          print('Cannot load contact list: User not logged in');
        }
        return;
      }

      // Ensure NostrService is connected
      if (!_nostrService.isConnected) {
        await _nostrService.connect();
      }

      // Request contact list from relay
      final filter = {
        'kinds': [3], // Contact list
        'authors': [currentUserPubkey],
        'limit': 1,
      };

      // Subscribe to contact list events
      final subscription = _nostrService.subscribeToSimpleFilter(filter);
      
      // Listen for contact list
      await for (final eventData in subscription) {
        if (eventData['kind'] == 3 && eventData['pubkey'] == currentUserPubkey) {
          // Clear existing followed profiles
          _followedProfiles.clear();
          
          // Extract pubkeys from 'p' tags
          final tags = eventData['tags'] as List<dynamic>;
          for (final tag in tags) {
            if (tag is List && tag.isNotEmpty && tag[0] == 'p' && tag.length >= 2) {
              _followedProfiles.add(tag[1] as String);
            }
          }
          
          // Save to local storage
          await _saveFollowedProfiles();
          
          if (kDebugMode) {
            print('Loaded ${_followedProfiles.length} followed profiles from relays');
          }
          
          // Only process the latest contact list
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading contact list from relays: $e');
      }
    }
  }

  /// Clear all followed profiles (e.g., on logout)
  Future<void> clearFollowedProfiles() async {
    _followedProfiles.clear();
    await _saveFollowedProfiles();
  }
}