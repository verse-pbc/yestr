import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ndk_backup/ndk_service.dart';
import 'ndk_backup/adapters/follow_adapter.dart';
import 'key_management_service.dart';

/// NDK-based FollowService that maintains compatibility with the existing interface
/// while using NDK's robust contact list management
class FollowServiceNdk {
  static const String _followedProfilesKey = 'followed_profiles';
  
  final NdkService _ndkService = NdkService.instance;
  late final FollowAdapter _followAdapter;
  final KeyManagementService _keyService = KeyManagementService();
  
  // Cache followed profiles locally for offline access
  final Set<String> _followedProfiles = {};
  
  // Stream controller for follow updates
  final _followUpdatesController = StreamController<Set<String>>.broadcast();
  StreamSubscription? _contactListSubscription;
  
  // Singleton pattern
  static final FollowServiceNdk _instance = FollowServiceNdk._internal();
  factory FollowServiceNdk() => _instance;
  
  FollowServiceNdk._internal() {
    _followAdapter = FollowAdapter(_ndkService);
    _initialize();
  }

  /// Initialize the service
  Future<void> _initialize() async {
    await _loadFollowedProfiles();
    
    // Initialize NDK if not already done
    if (!_ndkService.isInitialized) {
      await _ndkService.initialize();
    }
    
    // Load contact list from relays if logged in
    if (_ndkService.isLoggedIn) {
      await loadContactListFromRelays();
    }
    
    // Subscribe to contact list updates
    _subscribeToContactListUpdates();
  }

  /// Get the set of followed profiles
  Set<String> get followedProfiles => Set.from(_followedProfiles);
  
  /// Stream of follow updates
  Stream<Set<String>> get followUpdates => _followUpdatesController.stream;

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
      _followUpdatesController.add(followedProfiles);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving followed profiles: $e');
      }
    }
  }

  /// Subscribe to contact list updates from NDK
  void _subscribeToContactListUpdates() {
    _contactListSubscription?.cancel();
    
    if (!_ndkService.isLoggedIn) return;
    
    _contactListSubscription = _followAdapter
        .subscribeToContactListUpdates()
        .listen((contactList) {
      // Update local cache
      _followedProfiles.clear();
      _followedProfiles.addAll(contactList.contacts);
      _saveFollowedProfiles();
      
      if (kDebugMode) {
        print('Contact list updated: ${_followedProfiles.length} contacts');
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('Error in contact list subscription: $error');
      }
    });
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

  /// Follow a profile using NDK (non-blocking version)
  /// Returns immediately with optimistic update, processes in background
  Future<bool> followProfileNonBlocking(String pubkey) async {
    try {
      // Quick login check
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('Cannot follow: User not logged in to NDK');
        }
        return false;
      }
      
      // Optimistically update local cache immediately
      _followedProfiles.add(pubkey);
      await _saveFollowedProfiles();
      
      // Process the actual follow in the background without awaiting
      _processFollowInBackground(pubkey);
      
      // Return success immediately for optimistic UI update
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in followProfileNonBlocking: $e');
      }
      return false;
    }
  }
  
  /// Process follow action in background
  Future<void> _processFollowInBackground(String pubkey) async {
    try {
      print('🔄 Processing follow in background for $pubkey');
      
      // Use NDK to follow the user (this might take time)
      final success = await _followAdapter.followUser(pubkey);
      
      if (!success) {
        // Revert on failure
        print('❌ Background follow failed, reverting for $pubkey');
        _followedProfiles.remove(pubkey);
        await _saveFollowedProfiles();
        
        // Notify UI about the failure if needed
        // You could emit an event here to show an error snackbar
      } else {
        print('✅ Background follow succeeded for $pubkey');
      }
    } catch (e) {
      print('❌ Error in background follow: $e');
      // Revert on error
      _followedProfiles.remove(pubkey);
      await _saveFollowedProfiles();
    }
  }

  /// Follow a profile using NDK (blocking version - kept for compatibility)
  Future<bool> followProfile(String pubkey) async {
    final startTime = DateTime.now();
    print('⏱️ [${startTime.toIso8601String()}] FollowServiceNdk.followProfile started for $pubkey');
    
    try {
      // Check if user is logged in
      final loginCheckTime = DateTime.now();
      print('⏱️ [${loginCheckTime.toIso8601String()}] Checking login status...');
      print('  NDK initialized: ${_ndkService.isInitialized}');
      print('  NDK logged in: ${_ndkService.isLoggedIn}');
      print('  NDK current pubkey: ${_ndkService.currentUserPubkey}');
      
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('⏱️ [${DateTime.now().toIso8601String()}] Cannot follow: User not logged in to NDK');
        }
        return false;
      }
      
      print('⏱️ [${DateTime.now().toIso8601String()}] User is logged in');

      // Optimistically update local cache
      final optimisticUpdateTime = DateTime.now();
      print('⏱️ [${optimisticUpdateTime.toIso8601String()}] Optimistically updating local cache...');
      _followedProfiles.add(pubkey);
      await _saveFollowedProfiles();
      print('⏱️ [${DateTime.now().toIso8601String()}] Local cache updated (took ${DateTime.now().difference(optimisticUpdateTime).inMilliseconds}ms)');

      // Use NDK to follow the user
      final ndkCallTime = DateTime.now();
      print('⏱️ [${ndkCallTime.toIso8601String()}] Calling NDK followUser adapter...');
      final success = await _followAdapter.followUser(pubkey);
      final ndkCallDuration = DateTime.now().difference(ndkCallTime);
      print('⏱️ [${DateTime.now().toIso8601String()}] NDK followUser completed: $success (took ${ndkCallDuration.inMilliseconds}ms)');
      
      if (!success) {
        // Revert on failure
        final revertTime = DateTime.now();
        print('⏱️ [${revertTime.toIso8601String()}] Reverting optimistic update...');
        _followedProfiles.remove(pubkey);
        await _saveFollowedProfiles();
        print('⏱️ [${DateTime.now().toIso8601String()}] Reverted (took ${DateTime.now().difference(revertTime).inMilliseconds}ms)');
      }
      
      final totalDuration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        print(success 
          ? '⏱️ [${DateTime.now().toIso8601String()}] ✅ Successfully followed: $pubkey (total: ${totalDuration.inMilliseconds}ms)' 
          : '⏱️ [${DateTime.now().toIso8601String()}] ❌ Failed to follow: $pubkey (total: ${totalDuration.inMilliseconds}ms)');
      }
      
      return success;
    } catch (e) {
      // Revert on error
      final errorTime = DateTime.now();
      print('⏱️ [${errorTime.toIso8601String()}] Error occurred, reverting...');
      _followedProfiles.remove(pubkey);
      await _saveFollowedProfiles();
      
      final totalDuration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        print('⏱️ [${DateTime.now().toIso8601String()}] ❌ Error following profile: $e (total: ${totalDuration.inMilliseconds}ms)');
      }
      return false;
    }
  }

  /// Unfollow a profile using NDK
  Future<bool> unfollowProfile(String pubkey) async {
    try {
      // Check if user is logged in
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('Cannot unfollow: User not logged in');
        }
        return false;
      }

      // Optimistically update local cache
      _followedProfiles.remove(pubkey);
      await _saveFollowedProfiles();

      // Use NDK to unfollow the user
      final success = await _followAdapter.unfollowUser(pubkey);
      
      if (!success) {
        // Revert on failure
        _followedProfiles.add(pubkey);
        await _saveFollowedProfiles();
      }
      
      if (kDebugMode) {
        print(success 
          ? 'Successfully unfollowed: $pubkey' 
          : 'Failed to unfollow: $pubkey');
      }
      
      return success;
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

  /// Load contact list from relays for the current user
  Future<void> loadContactListFromRelays() async {
    try {
      if (!_ndkService.isLoggedIn) {
        if (kDebugMode) {
          print('Cannot load contact list: User not logged in');
        }
        return;
      }

      // Use NDK to get following list
      final following = await _followAdapter.getFollowing();
      
      // Update local cache
      _followedProfiles.clear();
      _followedProfiles.addAll(following);
      await _saveFollowedProfiles();
      
      if (kDebugMode) {
        print('Loaded ${_followedProfiles.length} followed profiles from relays');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading contact list from relays: $e');
      }
    }
  }

  /// Get followers of a specific user
  Future<Set<String>> getFollowers(String pubkey) async {
    try {
      return await _followAdapter.getFollowers(pubkey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting followers: $e');
      }
      return {};
    }
  }

  /// Get mutual follows (users who follow each other)
  Future<Set<String>> getMutualFollows() async {
    try {
      return await _followAdapter.getMutualFollows();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mutual follows: $e');
      }
      return {};
    }
  }

  /// Clear all followed profiles (e.g., on logout)
  Future<void> clearFollowedProfiles() async {
    _followedProfiles.clear();
    await _saveFollowedProfiles();
    _contactListSubscription?.cancel();
  }

  /// Dispose resources
  void dispose() {
    _contactListSubscription?.cancel();
    _followUpdatesController.close();
  }
}