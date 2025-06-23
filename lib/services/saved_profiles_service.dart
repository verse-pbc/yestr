import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'nostr_service.dart';
import 'event_signer.dart';
import 'key_management_service.dart';

/// Service for managing saved profiles using NIP-51 lists
class SavedProfilesService {
  static const int _bookmarkListKind = 10003; // NIP-51 bookmark list
  static const String _savedProfilesTag = 'saved-profiles';
  
  // Singleton instance
  static SavedProfilesService? _instance;
  factory SavedProfilesService(NostrService nostrService) {
    _instance ??= SavedProfilesService._internal(nostrService);
    return _instance!;
  }
  
  final NostrService _nostrService;
  final KeyManagementService _keyService = KeyManagementService();
  
  final _savedProfilesController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get savedProfilesStream => _savedProfilesController.stream;
  
  List<String> _savedProfilePubkeys = [];
  List<String> get savedProfilePubkeys => List.unmodifiable(_savedProfilePubkeys);
  bool _hasLoadedInitial = false;
  
  SavedProfilesService._internal(this._nostrService) {
    // Listen for bookmark events
    _nostrService.eventsStream.listen((eventData) {
      processEvent(eventData);
    });
  }
  
  /// Load saved profiles from relays
  Future<void> loadSavedProfiles() async {
    // Skip if already loaded
    if (_hasLoadedInitial) {
      print('SavedProfilesService: Already loaded initial profiles');
      return;
    }
    
    try {
      final pubkey = await _keyService.getPublicKey();
      if (pubkey == null) {
        print('SavedProfilesService: No public key available');
        return;
      }
      
      _hasLoadedInitial = true;
      
      // Request bookmark list events for the current user
      final subscriptionId = 'saved_profiles_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [_bookmarkListKind],
          "authors": [pubkey],
          "limit": 1,
        }
      ];
      
      // Send request to all connected relays
      int relayCount = 0;
      for (final channel in _nostrService.channels) {
        if (channel.closeCode == null) {
          channel.sink.add(jsonEncode(request));
          relayCount++;
        }
      }
      
      print('SavedProfilesService: Requested saved profiles from $relayCount relays');
      print('SavedProfilesService: Request: ${jsonEncode(request)}');
      
      // Listen for responses
      Timer(const Duration(seconds: 3), () {
        // Close subscription after timeout
        final closeRequest = ["CLOSE", subscriptionId];
        for (final channel in _nostrService.channels) {
          if (channel.closeCode == null) {
            channel.sink.add(jsonEncode(closeRequest));
          }
        }
      });
    } catch (e) {
      print('SavedProfilesService: Error loading saved profiles: $e');
    }
  }
  
  /// Process incoming events that might be bookmark lists
  void processEvent(Map<String, dynamic> eventData) {
    try {
      if (eventData['kind'] != _bookmarkListKind) {
        return;
      }
      
      print('SavedProfilesService: Processing bookmark event from ${eventData['pubkey']}');
      
      // Only process our own bookmark events
      _keyService.getPublicKey().then((userPubkey) {
        if (userPubkey == null || eventData['pubkey'] != userPubkey) {
          print('SavedProfilesService: Ignoring bookmark event from other user');
          return;
        }
        
        final event = NostrEvent.fromJson(eventData);
        final savedPubkeys = <String>[];
        
        // Check for our specific saved profiles tag
        bool isOurSavedProfiles = false;
        for (final tag in event.tags) {
          if (tag.length >= 2 && tag[0] == 'd' && tag[1] == _savedProfilesTag) {
            isOurSavedProfiles = true;
            break;
          }
        }
        
        if (!isOurSavedProfiles) {
          print('SavedProfilesService: Bookmark event is not for saved profiles');
          return;
        }
        
        // Extract saved profile pubkeys from tags
        for (final tag in event.tags) {
          if (tag.length >= 2 && tag[0] == 'p') {
            savedPubkeys.add(tag[1]);
            print('SavedProfilesService: Found saved profile: ${tag[1]}');
          }
        }
        
        _savedProfilePubkeys = savedPubkeys;
        _savedProfilesController.add(savedPubkeys);
        
        print('SavedProfilesService: Loaded ${savedPubkeys.length} saved profiles total');
      });
    } catch (e) {
      print('SavedProfilesService: Error processing event: $e');
    }
  }
  
  /// Save a profile to the bookmark list
  Future<bool> saveProfile(String pubkey) async {
    try {
      final userPubkey = await _keyService.getPublicKey();
      if (userPubkey == null) {
        print('SavedProfilesService: No public key available');
        return false;
      }
      
      // Add to local list if not already saved
      if (!_savedProfilePubkeys.contains(pubkey)) {
        _savedProfilePubkeys.add(pubkey);
        
        // Create updated bookmark list event
        final tags = <List<String>>[];
        
        // Add all saved profiles as p tags
        for (final savedPubkey in _savedProfilePubkeys) {
          tags.add(['p', savedPubkey]);
        }
        
        // Add identifier tag for this list type
        tags.add(['d', _savedProfilesTag]);
        
        // Create the event
        final eventData = {
          'pubkey': userPubkey,
          'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'kind': _bookmarkListKind,
          'tags': tags,
          'content': '', // Public bookmarks, no encrypted content
        };
        
        // Get keys for signing
        final keys = await _keyService.getKeys();
        if (keys == null) {
          print('SavedProfilesService: No keys available for signing');
          return false;
        }
        
        // Sign the event using EventSigner static method
        final signedEvent = EventSigner.createSignedEvent(
          privateKeyHex: keys['private']!,
          publicKeyHex: keys['public']!,
          kind: _bookmarkListKind,
          content: '',
          tags: tags,
        );
        
        // Send to relays
        final eventMessage = ["EVENT", signedEvent];
        int sentCount = 0;
        for (final channel in _nostrService.channels) {
          if (channel.closeCode == null) {
            channel.sink.add(jsonEncode(eventMessage));
            sentCount++;
          }
        }
        
        print('SavedProfilesService: Sent bookmark event to $sentCount relays');
        print('SavedProfilesService: Event: ${jsonEncode(signedEvent)}');
        
        // Update local state
        _savedProfilesController.add(_savedProfilePubkeys);
        
        print('SavedProfilesService: Saved profile $pubkey (total: ${_savedProfilePubkeys.length})');
        return true;
      }
      
      return true; // Already saved
    } catch (e) {
      print('SavedProfilesService: Error saving profile: $e');
      return false;
    }
  }
  
  /// Remove a profile from the bookmark list
  Future<bool> removeProfile(String pubkey) async {
    try {
      final userPubkey = await _keyService.getPublicKey();
      if (userPubkey == null) {
        print('SavedProfilesService: No public key available');
        return false;
      }
      
      // Remove from local list
      if (_savedProfilePubkeys.contains(pubkey)) {
        _savedProfilePubkeys.remove(pubkey);
        
        // Create updated bookmark list event
        final tags = <List<String>>[];
        
        // Add remaining saved profiles as p tags
        for (final savedPubkey in _savedProfilePubkeys) {
          tags.add(['p', savedPubkey]);
        }
        
        // Add identifier tag for this list type
        tags.add(['d', _savedProfilesTag]);
        
        // Create the event
        final eventData = {
          'pubkey': userPubkey,
          'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'kind': _bookmarkListKind,
          'tags': tags,
          'content': '', // Public bookmarks, no encrypted content
        };
        
        // Get keys for signing
        final keys = await _keyService.getKeys();
        if (keys == null) {
          print('SavedProfilesService: No keys available for signing');
          return false;
        }
        
        // Sign the event using EventSigner static method
        final signedEvent = EventSigner.createSignedEvent(
          privateKeyHex: keys['private']!,
          publicKeyHex: keys['public']!,
          kind: _bookmarkListKind,
          content: '',
          tags: tags,
        );
        
        // Send to relays
        final eventMessage = ["EVENT", signedEvent];
        for (final channel in _nostrService.channels) {
          if (channel.closeCode == null) {
            channel.sink.add(jsonEncode(eventMessage));
          }
        }
        
        // Update local state
        _savedProfilesController.add(_savedProfilePubkeys);
        
        print('SavedProfilesService: Removed profile $pubkey');
        return true;
      }
      
      return true; // Already removed
    } catch (e) {
      print('SavedProfilesService: Error removing profile: $e');
      return false;
    }
  }
  
  /// Check if a profile is saved
  bool isProfileSaved(String pubkey) {
    return _savedProfilePubkeys.contains(pubkey);
  }
  
  /// Get saved profiles as NostrProfile objects
  Future<List<NostrProfile>> getSavedProfiles() async {
    final profiles = <NostrProfile>[];
    
    if (_savedProfilePubkeys.isEmpty) {
      return profiles;
    }
    
    try {
      // Request profile metadata for all saved pubkeys
      final subscriptionId = 'saved_profiles_metadata_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0], // Profile metadata
          "authors": _savedProfilePubkeys,
        }
      ];
      
      // Collect profiles as they come in
      final completer = Completer<List<NostrProfile>>();
      final receivedProfiles = <String, NostrProfile>{};
      
      // Set up a timer to complete after receiving profiles
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(receivedProfiles.values.toList());
        }
      });
      
      // Listen for profile events
      StreamSubscription? subscription;
      subscription = _nostrService.eventsStream.listen((eventData) {
        if (eventData['kind'] == 0 && _savedProfilePubkeys.contains(eventData['pubkey'])) {
          try {
            final profile = NostrProfile.fromNostrEvent(eventData);
            receivedProfiles[profile.pubkey] = profile;
            
            // If we've received all profiles, complete early
            if (receivedProfiles.length == _savedProfilePubkeys.length && !completer.isCompleted) {
              completer.complete(receivedProfiles.values.toList());
              subscription?.cancel();
            }
          } catch (e) {
            print('SavedProfilesService: Error parsing profile: $e');
          }
        }
      });
      
      // Send request to all connected relays
      for (final channel in _nostrService.channels) {
        if (channel.closeCode == null) {
          channel.sink.add(jsonEncode(request));
        }
      }
      
      // Wait for profiles
      profiles.addAll(await completer.future);
      
      // Close subscription
      final closeRequest = ["CLOSE", subscriptionId];
      for (final channel in _nostrService.channels) {
        if (channel.closeCode == null) {
          channel.sink.add(jsonEncode(closeRequest));
        }
      }
      
      subscription.cancel();
    } catch (e) {
      print('SavedProfilesService: Error getting saved profiles: $e');
    }
    
    return profiles;
  }
  
  void dispose() {
    _savedProfilesController.close();
  }
}