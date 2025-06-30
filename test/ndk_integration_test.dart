import 'package:flutter_test/flutter_test.dart';
import 'package:yestr/services/nostr_service.dart';
import 'package:yestr/services/ndk_backup/ndk_adapter_service.dart';
import 'package:yestr/models/nostr_profile.dart';

void main() {
  group('NDK Integration Tests', () {
    late NostrService nostrService;
    
    setUp(() {
      nostrService = NostrService();
    });
    
    test('NostrService should initialize with NDK enabled', () async {
      // Connect to Nostr
      await nostrService.connect();
      
      // Verify connection
      expect(nostrService.isConnected, isTrue);
    });
    
    test('Should fetch profiles using NDK', () async {
      // Connect first
      await nostrService.connect();
      
      // Request profiles
      await nostrService.requestProfilesWithLimit(limit: 10);
      
      // Wait a bit for profiles to load
      await Future.delayed(const Duration(seconds: 3));
      
      // Check if profiles were loaded
      final profiles = nostrService.profiles;
      expect(profiles, isNotEmpty);
      print('Loaded ${profiles.length} profiles via NDK');
      
      // Verify profile data
      for (final profile in profiles) {
        expect(profile.pubkey, isNotEmpty);
        print('Profile: ${profile.displayNameOrName} (${profile.pubkey.substring(0, 8)}...)');
      }
    });
    
    test('Should fetch specific profile using NDK', () async {
      // Connect first
      await nostrService.connect();
      
      // Test with a known pubkey (jack dorsey)
      const testPubkey = '82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2';
      
      final profile = await nostrService.getProfile(testPubkey);
      
      expect(profile, isNotNull);
      expect(profile!.pubkey, equals(testPubkey));
      expect(profile.name, isNotNull);
      print('Fetched profile: ${profile.displayNameOrName}');
    });
    
    tearDown(() {
      nostrService.disconnect();
    });
  });
}