import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nostr_profile.dart';

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
      print('NostrBandApiService: Fetching trending profiles from $_baseUrl/trending/profiles');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/profiles'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('NostrBandApiService: Received response with data type: ${data.runtimeType}');
        
        final profiles = <NostrProfile>[];
        
        if (data is Map && data.containsKey('profiles')) {
          final profilesList = data['profiles'] as List;
          print('NostrBandApiService: Found ${profilesList.length} trending profiles');
          
          for (final item in profilesList) {
            try {
              final profile = _parseProfile(item);
              if (profile != null) {
                profiles.add(profile);
              }
            } catch (e) {
              print('NostrBandApiService: Error parsing profile: $e');
            }
          }
        }

        print('NostrBandApiService: Successfully parsed ${profiles.length} profiles');
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

  void dispose() {
    _profilesController.close();
  }
}