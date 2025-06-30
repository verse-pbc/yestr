import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nostr_profile.dart';

/// Service for interacting with the Yestr relay API
class YestrRelayService {
  static const String _baseUrl = 'https://relay.yestr.social';
  
  // Singleton instance
  static final YestrRelayService _instance = YestrRelayService._internal();
  factory YestrRelayService() => _instance;
  YestrRelayService._internal();
  
  /// Fetch random profiles from the Yestr relay
  Future<List<NostrProfile>> getRandomProfiles({int count = 50}) async {
    try {
      print('YestrRelayService: Fetching $count random profiles...');
      
      final url = Uri.parse('$_baseUrl/random?count=$count');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profiles = <NostrProfile>[];
        
        // The API returns an array of profile events
        if (data is List) {
          for (final item in data) {
            try {
              // The response has a nested structure: { profile: {...}, dm_relay_list: {...}, ... }
              final itemData = item as Map<String, dynamic>;
              final profileEvent = itemData['profile'] as Map<String, dynamic>?;
              
              if (profileEvent != null) {
                final content = profileEvent['content'] as String?;
                final pubkey = profileEvent['pubkey'] as String?;
                
                if (content != null && pubkey != null) {
                  final metadata = jsonDecode(content) as Map<String, dynamic>;
                  
                  // Extract relay information
                  List<String>? relays;
                  List<String>? dmRelays;
                  
                  // Get general relays from relay_list (kind 10002)
                  final relayList = itemData['relay_list'] as Map<String, dynamic>?;
                  if (relayList != null && relayList['tags'] != null) {
                    relays = [];
                    for (final tag in relayList['tags'] as List) {
                      if (tag is List && tag.length >= 2 && tag[0] == 'r') {
                        relays.add(tag[1] as String);
                      }
                    }
                  }
                  
                  // Get DM relays from dm_relay_list (kind 10050)
                  final dmRelayList = itemData['dm_relay_list'] as Map<String, dynamic>?;
                  if (dmRelayList != null && dmRelayList['tags'] != null) {
                    dmRelays = [];
                    for (final tag in dmRelayList['tags'] as List) {
                      if (tag is List && tag.length >= 2 && tag[0] == 'relay') {
                        dmRelays.add(tag[1] as String);
                      }
                    }
                  }
                  
                  final profile = NostrProfile(
                    pubkey: pubkey,
                    name: metadata['name'] as String?,
                    displayName: metadata['display_name'] as String?,
                    about: metadata['about'] as String?,
                    picture: metadata['picture'] as String?,
                    banner: metadata['banner'] as String?,
                    nip05: metadata['nip05'] as String?,
                    lud16: metadata['lud16'] as String?,
                    website: metadata['website'] as String?,
                    createdAt: profileEvent['created_at'] != null 
                      ? DateTime.fromMillisecondsSinceEpoch((profileEvent['created_at'] as int) * 1000)
                      : null,
                    relays: relays,
                    dmRelays: dmRelays,
                  );
                  
                  profiles.add(profile);
                  print('YestrRelayService: Added profile ${pubkey.substring(0, 8)}... - ${profile.displayNameOrName}');
                  if (relays != null && relays.isNotEmpty) {
                    print('  - Relays: ${relays.join(", ")}');
                  }
                  if (dmRelays != null && dmRelays.isNotEmpty) {
                    print('  - DM Relays: ${dmRelays.join(", ")}');
                  }
                }
              }
            } catch (e) {
              print('YestrRelayService: Error parsing profile: $e');
            }
          }
        }
        
        print('YestrRelayService: Successfully fetched ${profiles.length} random profiles');
        return profiles;
      } else {
        print('YestrRelayService: Failed with status ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('YestrRelayService: Error fetching random profiles: $e');
      return [];
    }
  }
  
  /// Prefetch random profiles in the background
  Future<void> prefetchRandomProfiles() async {
    try {
      await getRandomProfiles(count: 50);
    } catch (e) {
      print('YestrRelayService: Error prefetching random profiles: $e');
    }
  }
}