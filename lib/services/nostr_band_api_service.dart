import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nostr_profile.dart';
// Only import platform-specific code conditionally
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

class NostrBandApiService {
  static final NostrBandApiService _instance = NostrBandApiService._internal();
  factory NostrBandApiService() => _instance;
  NostrBandApiService._internal();

  final String _baseUrl = 'https://api.nostr.band/v0';
  final _profilesController = StreamController<List<NostrProfile>>.broadcast();
  List<NostrProfile> _cachedProfiles = [];
  bool _isLoading = false;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 15); // Cache for 15 minutes

  Stream<List<NostrProfile>> get profilesStream => _profilesController.stream;
  List<NostrProfile> get cachedProfiles => List.unmodifiable(_cachedProfiles);
  bool get isLoading => _isLoading;

  Future<List<NostrProfile>> fetchTrendingProfiles() async {
    // Check if we have valid cached data
    if (_cachedProfiles.isNotEmpty && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
      print('NostrBandApiService: Returning cached profiles');
      return _cachedProfiles;
    }

    if (_isLoading) {
      print('NostrBandApiService: Already loading profiles, returning cached');
      return _cachedProfiles;
    }

    _isLoading = true;
    try {
      final apiUrl = '$_baseUrl/trending/profiles';
      
      // Use a self-hosted CORS proxy or consider these alternatives:
      // 1. Deploy a simple Cloudflare Worker as a CORS proxy
      // 2. Use Vercel/Netlify functions
      // 3. Set up a simple Express server with cors middleware
      
      // For immediate testing, try thingproxy
      final proxyUrl = 'https://thingproxy.freeboard.io/fetch/$apiUrl';
      
      print('NostrBandApiService: Fetching trending profiles from: $apiUrl');
      print('NostrBandApiService: Using proxy: $proxyUrl');
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('NostrBandApiService: Response status: ${response.statusCode}');
      print('NostrBandApiService: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('NostrBandApiService: Received response with data type: ${data.runtimeType}');
        
        // Debug: Print first few items of response to see structure
        if (data is List && data.isNotEmpty) {
          print('NostrBandApiService: First item structure:');
          print(jsonEncode(data.first));
        } else if (data is Map) {
          print('NostrBandApiService: Response is a Map with keys: ${data.keys.toList()}');
          if (data.containsKey('profiles') && data['profiles'] is List) {
            final profilesList = data['profiles'] as List;
            if (profilesList.isNotEmpty) {
              print('NostrBandApiService: First profile item:');
              print(jsonEncode(profilesList.first));
            }
          }
        }
        
        final profiles = <NostrProfile>[];
        
        // The API returns an object with 'profiles' key when no parameters are provided
        if (data is Map && data.containsKey('profiles')) {
          final profilesList = data['profiles'] as List;
          print('NostrBandApiService: Found ${profilesList.length} trending profiles');
          
          for (final item in profilesList) {
            try {
              final profile = _parseProfile(item);
              if (profile != null) {
                profiles.add(profile);
                print('PROFILE DOWNLOADED: ${profile.pubkey} - ${profile.displayNameOrName}');
              }
            } catch (e) {
              print('NostrBandApiService: Error parsing profile: $e');
            }
          }
        } else if (data is List) {
          // Handle the case where API returns array directly (with date parameter)
          print('NostrBandApiService: Found ${data.length} trending profiles in array format');
          
          for (final item in data) {
            try {
              final profile = _parseProfile(item);
              if (profile != null) {
                profiles.add(profile);
                print('PROFILE DOWNLOADED: ${profile.pubkey} - ${profile.displayNameOrName}');
              }
            } catch (e) {
              print('NostrBandApiService: Error parsing profile: $e');
            }
          }
        }

        print('\n=== NOSTR.BAND API PROFILES SUMMARY ===');
        print('Total profiles downloaded: ${profiles.length}');
        print('Expected trending profiles:');
        print('1. e0f6050d930a61323bac4a5b47d58e961da2919834f3f58f3b312c2918852b55 - Flame_of_Man⚡️');
        print('2. 9349c924270bf5b2390f6d780dde344e965512470321b1603cef68522f9c01cc - Tsuki');
        print('3. 5be6189315d16136de600c1491b1dea44c79605b79bb2cda3452841a646b0e69 - Product Hunt');
        print('\nActual profiles received:');
        for (int i = 0; i < profiles.length && i < 10; i++) {
          print('${i + 1}. ${profiles[i].pubkey} - ${profiles[i].displayNameOrName}');
        }
        print('=====================================\n');
        _cachedProfiles = profiles;
        _lastFetchTime = DateTime.now();
        _profilesController.add(profiles);
        return profiles;
      } else {
        throw Exception('Failed to fetch trending profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('NostrBandApiService: Error fetching profiles: $e');
      // Return cached profiles if available
      if (_cachedProfiles.isNotEmpty) {
        return _cachedProfiles;
      }
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  NostrProfile? _parseProfile(dynamic data) {
    if (data == null) return null;

    try {
      String? pubkey;
      Map<String, dynamic>? profileData;

      if (data is Map) {
        // Get pubkey
        pubkey = data['pubkey'] as String?;
        
        // Check if there's a profile field with kind-0 event details
        if (data.containsKey('profile') && data['profile'] != null) {
          final profileEvent = data['profile'];
          
          // Parse the content field if it's a string (JSON)
          if (profileEvent is Map && profileEvent.containsKey('content')) {
            final contentStr = profileEvent['content'] as String?;
            if (contentStr != null) {
              try {
                profileData = jsonDecode(contentStr) as Map<String, dynamic>;
              } catch (e) {
                print('NostrBandApiService: Failed to parse profile content JSON: $e');
                profileData = {};
              }
            }
          }
        }
      }

      if (pubkey == null) return null;

      // Create profile with available data
      return NostrProfile(
        pubkey: pubkey,
        name: profileData?['name'] as String?,
        displayName: profileData?['display_name'] as String?,
        about: profileData?['about'] as String?,
        picture: profileData?['picture'] as String?,
        banner: profileData?['banner'] as String?,
        nip05: profileData?['nip05'] as String?,
        lud16: profileData?['lud16'] as String?,
        website: profileData?['website'] as String?,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('NostrBandApiService: Error creating profile: $e');
      return null;
    }
  }

  // Prefetch profiles in the background
  void prefetchProfiles() {
    print('NostrBandApiService: Starting background prefetch of trending profiles');
    fetchTrendingProfiles().then((profiles) {
      print('NostrBandApiService: Background prefetch completed with ${profiles.length} profiles');
    }).catchError((error) {
      print('NostrBandApiService: Background prefetch error: $error');
    });
  }

  // Clear the cache and force a fresh fetch
  void clearCache() {
    print('NostrBandApiService: Clearing cache');
    _cachedProfiles = [];
    _lastFetchTime = null;
  }

  // Force refresh profiles (clear cache and fetch new ones)
  Future<List<NostrProfile>> forceRefreshProfiles() async {
    clearCache();
    return fetchTrendingProfiles();
  }

  void dispose() {
    _profilesController.close();
  }
}