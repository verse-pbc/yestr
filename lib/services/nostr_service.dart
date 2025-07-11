import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart' as dart_nostr;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'key_management_service.dart';
import 'event_signer.dart';

class NostrService {
  // Singleton instance
  static final NostrService _instance = NostrService._internal();
  factory NostrService() => _instance;
  NostrService._internal();
  
  final KeyManagementService _keyService = KeyManagementService();
  final _profilesController = StreamController<NostrProfile>.broadcast();
  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final List<NostrProfile> _profiles = [];
  StreamSubscription? _profileSubscription;
  bool _isConnected = false;
  final List<WebSocketChannel> _channels = [];
  final List<String> _relayUrls = [
    'wss://relay.damus.io',
    'wss://relay.primal.net',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://relay.yestr.social',
  ];

  Stream<NostrProfile> get profilesStream => _profilesController.stream;
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;
  List<NostrProfile> get profiles => List.unmodifiable(_profiles);
  bool get isConnected => _isConnected;
  List<WebSocketChannel> get channels => _channels;

  Future<void> connect() async {
    if (_isConnected) {
      print('NostrService: Already connected');
      return;
    }
    
    try {
      await connectToMultipleRelays();
      _isConnected = true;
      
      // Request profiles after connection
      await _requestProfiles();
    } catch (e) {
      print('NostrService: Connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }
  
  void _setupEventListeners() {
    for (final channel in _channels) {
      channel.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as List<dynamic>;
          if (data.length >= 3 && data[0] == 'EVENT') {
            final eventData = data[2] as Map<String, dynamic>;
            _handleEvent(eventData);
          } else if (data[0] == 'EOSE') {
            // End of stored events
            print('NostrService: End of stored events for subscription ${data[1]}');
          } else if (data[0] == 'NOTICE') {
            print('NostrService: Relay notice: ${data[1]}');
          }
        } catch (e) {
          print('Error processing message: $e');
          print('Raw message: $message');
        }
      });
    }
  }
  
  void _handleEvent(Map<String, dynamic> eventData) {
    final kind = eventData['kind'] as int;
    
    // Debug: log all kind 1 events
    if (kind == 1) {
      print('NostrService: Received kind 1 event from ${eventData['pubkey']?.substring(0, 8)}...');
    }
    
    if (kind == 0) {
      // Profile metadata
      final profile = NostrProfile.fromNostrEvent(eventData);
      if (!_profiles.any((p) => p.pubkey == profile.pubkey)) {
        _profiles.add(profile);
        _profilesController.add(profile);
      }
    }
    
    // Emit all events to the events stream
    _eventsController.add(eventData);
  }

  Future<void> _requestProfiles() async {
    try {
      print('NostrService: Requesting profiles...');
      
      final subscriptionId = 'profiles_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0],
          "limit": 100,
        }
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      print('NostrService: Sent profile request to ${_channels.length} relays');
    } catch (e) {
      print('NostrService: Error requesting profiles: $e');
    }
  }

  Future<void> requestProfilesWithLimit({
    int limit = 50,
    List<String>? authors,
    bool useTrendingProfiles = true,
  }) async {
    try {
      print('NostrService: Requesting profiles with limit $limit');
      
      // Clear existing profiles
      _profiles.clear();
      
      // Try to get trending profiles from nostr.band first
      if (useTrendingProfiles && authors == null) {
        try {
          final trendingProfiles = await getTrendingProfilesFromNostrBand(limit: limit);
          if (trendingProfiles.isNotEmpty) {
            for (final profile in trendingProfiles) {
              _profiles.add(profile);
              _profilesController.add(profile);
            }
            return;
          }
        } catch (e) {
          print('NostrService: Failed to get trending profiles from nostr.band, using relay fallback: $e');
        }
      }
      
      // Fallback to regular profile request
      final subscriptionId = 'profiles_limit_${DateTime.now().millisecondsSinceEpoch}';
      final filter = {
        "kinds": [0],
        "limit": limit,
      };
      
      if (authors != null && authors.isNotEmpty) {
        filter["authors"] = authors;
      }
      
      final request = [
        "REQ",
        subscriptionId,
        filter,
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      print('NostrService: Sent limited profile request to ${_channels.length} relays');
    } catch (e) {
      print('NostrService: Error requesting profiles: $e');
    }
  }

  Future<NostrProfile?> getProfile(String pubkey) async {
    try {
      // First check cache
      final cached = _profiles.firstWhere(
        (p) => p.pubkey == pubkey,
        orElse: () => NostrProfile(
          pubkey: pubkey,
          name: null,
          displayName: null,
          about: null,
          picture: null,
          banner: null,
          nip05: null,
          lud16: null,
          website: null,
        ),
      );
      
      // Return cached if valid
      if (cached.name != null || cached.displayName != null) {
        return cached;
      }
      
      // Query for latest profile
      final subscriptionId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0],
          "authors": [pubkey],
          "limit": 1,
        }
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      // Wait a bit for response
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if profile was received
      final updated = _profiles.firstWhere(
        (p) => p.pubkey == pubkey,
        orElse: () => cached,
      );
      
      return updated.name != null ? updated : null;
    } catch (e) {
      print('NostrService: Error getting profile: $e');
      return null;
    }
  }

  Future<List<NostrEvent>> getUserNotes(String pubkey, {int limit = 20}) async {
    try {
      print('NostrService: Getting notes for user $pubkey');
      final subscriptionId = 'notes_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [1], // Text notes
          "authors": [pubkey],
          "limit": limit,
        }
      ];
      
      final notes = <NostrEvent>[];
      final completer = Completer<List<NostrEvent>>();
      
      // Set up temporary listener for notes BEFORE sending request
      StreamSubscription? subscription;
      subscription = _eventsController.stream.listen((eventData) {
        if (eventData['kind'] == 1 && eventData['pubkey'] == pubkey) {
          try {
            final event = NostrEvent.fromJson(eventData);
            notes.add(event);
            print('NostrService: Received note ${notes.length}/${limit} from ${pubkey.substring(0, 8)}...');
          } catch (e) {
            print('NostrService: Error parsing note event: $e');
          }
        }
      });
      
      // Small delay to ensure listener is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      print('NostrService: Sent notes request to ${_channels.length} relays');
      
      // Wait for responses with timeout
      Timer(const Duration(seconds: 3), () {
        subscription?.cancel();
        
        // Send CLOSE to all channels
        final closeRequest = ["CLOSE", subscriptionId];
        for (final channel in _channels) {
          channel.sink.add(jsonEncode(closeRequest));
        }
        
        if (!completer.isCompleted) {
          // Sort by created_at descending (newest first)
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('NostrService: Returning ${notes.length} notes for $pubkey');
          completer.complete(notes);
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('NostrService: Error getting user notes: $e');
      return [];
    }
  }

  Future<bool> publishEvent(Map<String, dynamic> eventData) async {
    try {
      // Get keys for signing
      final keys = await _keyService.getKeys();
      if (keys == null) {
        throw Exception('No keys available for signing');
      }
      
      // Create signed event using EventSigner static method
      final signedEvent = EventSigner.createSignedEvent(
        privateKeyHex: keys['private']!,
        publicKeyHex: keys['public']!,
        kind: eventData['kind'] ?? 1,
        content: eventData['content'] ?? '',
        tags: List<List<String>>.from(eventData['tags'] ?? []),
      );
      
      final message = [
        "EVENT",
        signedEvent,
      ];
      
      // Send to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(message));
      }
      
      print('NostrService: Published event with id: ${signedEvent['id']}');
      return true;
    } catch (e) {
      print('NostrService: Error publishing event: $e');
      return false;
    }
  }

  Future<void> connectToMultipleRelays() async {
    for (final url in _relayUrls) {
      try {
        final channel = WebSocketChannel.connect(Uri.parse(url));
        _channels.add(channel);
        // Connected to $url
      } catch (e) {
        print('NostrService: Failed to connect to $url: $e');
      }
    }
    
    if (_channels.isNotEmpty) {
      _setupEventListeners();
    }
  }

  Stream<Map<String, dynamic>> subscribeToSimpleFilter(Map<String, dynamic> filter) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    
    // Subscribe to events matching the filter
    final request = [
      "REQ",
      subscriptionId,
      filter,
    ];
    
    // Send request to all channels
    for (final channel in _channels) {
      channel.sink.add(jsonEncode(request));
    }
    
    // Listen for matching events
    final subscription = _eventsController.stream.listen((eventData) {
      // Check if event matches filter criteria
      bool matches = true;
      
      if (filter['kinds'] != null && filter['kinds'] is List) {
        matches = matches && (filter['kinds'] as List).contains(eventData['kind']);
      }
      
      if (filter['authors'] != null && filter['authors'] is List) {
        matches = matches && (filter['authors'] as List).contains(eventData['pubkey']);
      }
      
      if (matches) {
        controller.add(eventData);
      }
    });
    
    // Clean up subscription when done
    controller.onCancel = () {
      subscription.cancel();
      // Send CLOSE to all channels
      final closeRequest = ["CLOSE", subscriptionId];
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(closeRequest));
      }
    };
    
    return controller.stream;
  }

  Future<Map<String, int>> getFollowerFollowingCounts(String pubkey) async {
    try {
      // First try to get counts from nostr.band API
      final nostrBandCounts = await getFollowerFollowingCountsFromNostrBand(pubkey);
      if (nostrBandCounts['followers']! > 0 || nostrBandCounts['following']! > 0) {
        return nostrBandCounts;
      }
      
      // Fallback to relay-based counting
      print('NostrService: Getting follower/following counts from relays for $pubkey');
      
      int followerCount = 0;
      int followingCount = 0;
      
      // First, get the user's contact list to count following
      final followingSubscriptionId = 'following_${DateTime.now().millisecondsSinceEpoch}';
      final followingRequest = [
        "REQ",
        followingSubscriptionId,
        {
          "kinds": [3], // Contact list
          "authors": [pubkey],
          "limit": 1,
        }
      ];
      
      // Send request to get user's contact list
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(followingRequest));
      }
      
      // Set up temporary listener for the user's contact list
      final followingCompleter = Completer<void>();
      StreamSubscription? followingSubscription;
      
      followingSubscription = _eventsController.stream.listen((eventData) {
        if (eventData['kind'] == 3 && eventData['pubkey'] == pubkey) {
          final tags = eventData['tags'] as List<dynamic>;
          followingCount = tags.where((tag) => 
            tag is List && tag.isNotEmpty && tag[0] == 'p'
          ).length;
          if (!followingCompleter.isCompleted) {
            followingCompleter.complete();
          }
        }
      });
      
      // Set timeout for following count
      Timer(const Duration(seconds: 2), () {
        if (!followingCompleter.isCompleted) {
          followingCompleter.complete();
        }
      });
      
      await followingCompleter.future;
      followingSubscription.cancel();
      
      // Close the following subscription
      final closeFollowingRequest = ["CLOSE", followingSubscriptionId];
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(closeFollowingRequest));
      }
      
      // Now get followers (contact lists that include this pubkey)
      final followerSubscriptionId = 'followers_${DateTime.now().millisecondsSinceEpoch}';
      final followerRequest = [
        "REQ",
        followerSubscriptionId,
        {
          "kinds": [3], // Contact list
          "#p": [pubkey], // Contact lists that include this pubkey
          "limit": 500, // Reasonable limit to prevent too much data
        }
      ];
      
      // Send request to get followers
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(followerRequest));
      }
      
      // Count unique followers
      final uniqueFollowers = <String>{};
      
      // Listen for follower events with timeout
      final followerCompleter = Completer<void>();
      Timer(const Duration(seconds: 2), () {
        if (!followerCompleter.isCompleted) {
          followerCompleter.complete();
        }
      });
      
      final followerSubscription = _eventsController.stream.listen((eventData) {
        if (eventData['kind'] == 3) {
          final tags = eventData['tags'] as List<dynamic>;
          // Check if this contact list includes our pubkey
          for (final tag in tags) {
            if (tag is List && tag.length >= 2 && tag[0] == 'p' && tag[1] == pubkey) {
              uniqueFollowers.add(eventData['pubkey'] as String);
              break;
            }
          }
        }
      });
      
      await followerCompleter.future;
      followerSubscription.cancel();
      
      // Close the follower subscription
      final closeFollowerRequest = ["CLOSE", followerSubscriptionId];
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(closeFollowerRequest));
      }
      
      followerCount = uniqueFollowers.length;
      
      print('NostrService: Profile $pubkey has $followerCount followers and $followingCount following');
      
      return {
        'followers': followerCount,
        'following': followingCount,
      };
    } catch (e) {
      print('NostrService: Error getting follower/following counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  Future<Map<String, int>> getFollowerFollowingCountsFromNostrBand(String pubkey) async {
    try {
      print('NostrService: Getting follower/following counts from nostr.band for $pubkey');
      
      // Query nostr.band API for user stats
      final url = Uri.parse('https://api.nostr.band/v0/stats/profile/$pubkey');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // The API returns stats nested under 'stats' -> pubkey
        final stats = data['stats'] as Map<String, dynamic>?;
        if (stats != null && stats.containsKey(pubkey)) {
          final userStats = stats[pubkey] as Map<String, dynamic>;
          
          final followerCount = userStats['followers_pubkey_count'] as int? ?? 0;
          final followingCount = userStats['pub_following_pubkey_count'] as int? ?? 0;
          
          print('NostrService: nostr.band stats - followers: $followerCount, following: $followingCount');
          
          return {
            'followers': followerCount,
            'following': followingCount,
          };
        }
      } else {
        print('NostrService: nostr.band API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('NostrService: Error getting stats from nostr.band: $e');
    }
    
    // Return zeros if API call fails
    return {'followers': 0, 'following': 0};
  }

  Future<List<NostrProfile>> getTrendingProfilesFromNostrBand({int limit = 50}) async {
    try {
      // Getting trending profiles from today from nostr.band
      
      // Query nostr.band API for trending profiles (default is today)
      final url = Uri.parse('https://api.nostr.band/v0/trending/profiles');
      // Fetching trending profiles from today
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // The API returns an array directly when no date parameter is used
        final profiles = data as List<dynamic>? ?? [];
        
        final nostrProfiles = <NostrProfile>[];
        
        // Process up to 'limit' profiles
        for (int i = 0; i < profiles.length && i < limit; i++) {
          final profileData = profiles[i] as Map<String, dynamic>;
          
          // The structure is: { pubkey, profile: { ... event data ... } }
          final pubkey = profileData['pubkey'] as String?;
          final profileEvent = profileData['profile'] as Map<String, dynamic>?;
          
          if (pubkey != null && profileEvent != null) {
            // Extract profile metadata from the event content
            final metadata = profileEvent['content'] != null 
                ? jsonDecode(profileEvent['content'] as String) as Map<String, dynamic>
                : <String, dynamic>{};
            
            final nostrProfile = NostrProfile(
              pubkey: pubkey,
              name: metadata['name'] as String?,
              displayName: metadata['display_name'] as String?,
              about: metadata['about'] as String?,
              picture: metadata['picture'] as String?,
              banner: metadata['banner'] as String?,
              nip05: metadata['nip05'] as String?,
              lud16: metadata['lud16'] as String?,
              website: metadata['website'] as String?,
            );
            
            nostrProfiles.add(nostrProfile);
          }
        }
        
        // Retrieved ${nostrProfiles.length} trending profiles from nostr.band
        return nostrProfiles;
      }
    } catch (e) {
      print('NostrService: Error getting trending profiles from nostr.band: $e');
    }
    
    return [];
  }

  void disconnect() {
    _profileSubscription?.cancel();
    for (final channel in _channels) {
      channel.sink.close();
    }
    _channels.clear();
    _profiles.clear();
    _isConnected = false;
    print('NostrService: Disconnected');
  }

  
  void dispose() {
    _profilesController.close();
    _eventsController.close();
    disconnect();
  }
}