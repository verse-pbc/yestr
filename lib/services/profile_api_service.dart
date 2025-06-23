import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nostr_profile.dart';

class ProfileApiService {
  static final ProfileApiService _instance = ProfileApiService._internal();
  factory ProfileApiService() => _instance;
  ProfileApiService._internal();

  final String _baseUrl = 'https://relay.yestr.social/random';
  final _profilesController = StreamController<List<NostrProfile>>.broadcast();
  List<NostrProfile> _cachedProfiles = [];
  bool _isLoading = false;

  Stream<List<NostrProfile>> get profilesStream => _profilesController.stream;
  List<NostrProfile> get cachedProfiles => List.unmodifiable(_cachedProfiles);
  bool get isLoading => _isLoading;

  Future<List<NostrProfile>> fetchRandomProfiles({int count = 50}) async {
    if (_isLoading) {
      print('ProfileApiService: Already loading profiles, returning cached');
      return _cachedProfiles;
    }

    _isLoading = true;
    try {
      print('ProfileApiService: Fetching $count random profiles from $_baseUrl');
      
      final response = await http.get(
        Uri.parse('$_baseUrl?count=$count'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ProfileApiService: Received response with data type: ${data.runtimeType}');
        
        // Parse the profiles based on the API response structure
        final profiles = <NostrProfile>[];
        
        if (data is List) {
          for (final item in data) {
            try {
              // Each item has a 'profile' property containing the Nostr event
              if (item is Map && item.containsKey('profile')) {
                final profileEvent = item['profile'];
                final profile = _parseProfile(profileEvent);
                if (profile != null) {
                  profiles.add(profile);
                }
              }
            } catch (e) {
              print('ProfileApiService: Error parsing profile: $e');
            }
          }
        }

        print('ProfileApiService: Parsed ${profiles.length} profiles');
        _cachedProfiles = profiles;
        _profilesController.add(profiles);
        return profiles;
      } else {
        throw Exception('Failed to fetch profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('ProfileApiService: Error fetching profiles: $e');
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
      // Handle different possible data structures
      String? pubkey;
      Map<String, dynamic>? content;

      if (data is Map) {
        // Check if it's a Nostr event structure
        if (data.containsKey('pubkey') && data.containsKey('content')) {
          pubkey = data['pubkey'] as String?;
          final contentStr = data['content'] as String?;
          if (contentStr != null) {
            try {
              content = jsonDecode(contentStr) as Map<String, dynamic>;
            } catch (e) {
              print('ProfileApiService: Failed to parse content JSON: $e');
              content = {};
            }
          }
        } else {
          // Direct profile data
          pubkey = data['pubkey'] as String? ?? data['id'] as String?;
          content = data as Map<String, dynamic>;
        }
      }

      if (pubkey == null) return null;

      return NostrProfile(
        pubkey: pubkey,
        name: content?['name'] as String?,
        displayName: content?['display_name'] as String?,
        about: content?['about'] as String?,
        picture: content?['picture'] as String?,
        banner: content?['banner'] as String?,
        nip05: content?['nip05'] as String?,
        lud16: content?['lud16'] as String?,
        website: content?['website'] as String?,
        createdAt: data['created_at'] != null 
            ? DateTime.fromMillisecondsSinceEpoch((data['created_at'] as int) * 1000)
            : DateTime.now(),
      );
    } catch (e) {
      print('ProfileApiService: Error creating profile: $e');
      return null;
    }
  }

  // Prefetch profiles in the background
  void prefetchProfiles({int count = 50}) {
    print('ProfileApiService: Starting background prefetch of $count profiles');
    fetchRandomProfiles(count: count).then((profiles) {
      print('ProfileApiService: Background prefetch completed with ${profiles.length} profiles');
    }).catchError((error) {
      print('ProfileApiService: Background prefetch error: $error');
    });
  }

  void dispose() {
    _profilesController.close();
  }
}