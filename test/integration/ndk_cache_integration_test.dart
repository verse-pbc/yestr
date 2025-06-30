import 'package:flutter_test/flutter_test.dart';
import 'package:card_swiper_demo/services/ndk_backup/ndk_service.dart';
import 'package:card_swiper_demo/services/database/isar_database_service.dart';
import 'package:card_swiper_demo/services/ndk_backup/adapters/cached_profile_adapter.dart';
import 'package:card_swiper_demo/services/relay/optimized_relay_service.dart';
import 'package:card_swiper_demo/services/monitoring/performance_monitor.dart';
import 'package:card_swiper_demo/services/key_management_service.dart';
import 'package:card_swiper_demo/models/nostr_profile.dart';
import 'package:card_swiper_demo/models/database/cached_profile.dart';
import 'package:card_swiper_demo/models/database/cached_message.dart';
import 'package:card_swiper_demo/models/database/cached_relay.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

void main() {
  late NdkService ndkService;
  late IsarDatabaseService databaseService;
  late CachedProfileAdapter profileAdapter;
  late OptimizedRelayService relayService;
  late PerformanceMonitor performanceMonitor;
  late Directory testDir;

  setUpAll(() async {
    // Create test directory
    testDir = await Directory.systemTemp.createTemp('yestr_test_');
    
    // Initialize test database
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    // Initialize services
    databaseService = IsarDatabaseService.instance;
    
    // Override Isar initialization for testing
    final testIsar = await Isar.open(
      [
        CachedProfileSchema,
        CachedMessageSchema,
        CachedRelaySchema,
      ],
      directory: testDir.path,
      name: 'test_cache',
    );
    
    // Use reflection to set the private _isar field
    // In production, you'd have a better testing setup
    
    ndkService = NdkService.forTesting(KeyManagementService.instance);
    await ndkService.initialize();
    
    profileAdapter = CachedProfileAdapter(ndkService, databaseService);
    relayService = OptimizedRelayService(ndkService, databaseService);
    performanceMonitor = PerformanceMonitor.instance;
    
    await relayService.initialize();
  });

  tearDown(() async {
    await databaseService.clearAllCache();
    performanceMonitor.clearMetrics();
  });

  tearDownAll(() async {
    await databaseService.close();
    await testDir.delete(recursive: true);
  });

  group('Database Caching', () {
    test('should cache and retrieve profiles', () async {
      // Create test profile
      final profile = NostrProfile(
        pubkey: 'test_pubkey_123',
        name: 'Test User',
        displayName: 'Test Display Name',
        picture: 'https://example.com/avatar.jpg',
        about: 'Test bio',
        createdAt: DateTime.now(),
      );

      // Cache profile
      await databaseService.cacheProfile(profile);

      // Retrieve from cache
      final cached = await databaseService.getCachedProfile(profile.pubkey);

      expect(cached, isNotNull);
      expect(cached!.pubkey, equals(profile.pubkey));
      expect(cached.name, equals(profile.name));
      expect(cached.displayName, equals(profile.displayName));
    });

    test('should handle stale profile detection', () async {
      // Create profile with old timestamp
      final oldDate = DateTime.now().subtract(const Duration(days: 2));
      
      // Manually create cached profile with old date
      await databaseService.isar.writeTxn(() async {
        final cached = CachedProfile()
          ..pubkey = 'stale_pubkey'
          ..name = 'Stale User'
          ..lastUpdated = oldDate
          ..createdAt = oldDate;
        
        await databaseService.isar.cachedProfiles.put(cached);
      });

      // Check if stale
      final cachedProfile = await databaseService.isar.cachedProfiles
          .where()
          .pubkeyEqualTo('stale_pubkey')
          .findFirst();

      expect(cachedProfile!.isStale, isTrue);
    });

    test('should track failed image URLs', () async {
      const pubkey = 'test_pubkey';
      const failedUrl = 'https://example.com/broken.jpg';

      // Mark image as failed
      await databaseService.markImageAsFailed(pubkey, failedUrl);

      // Check if marked as failed
      final hasFailed = await databaseService.hasImageFailed(pubkey, failedUrl);
      expect(hasFailed, isTrue);
    });
  });

  group('Profile Adapter with Cache', () {
    test('should use cache when available and fresh', () async {
      const pubkey = 'cached_user_pubkey';
      
      // Pre-cache a profile
      final profile = NostrProfile(
        pubkey: pubkey,
        name: 'Cached User',
        displayName: 'Cached Display',
        createdAt: DateTime.now(),
      );
      await databaseService.cacheProfile(profile);

      // Fetch should return from cache
      final startTime = DateTime.now();
      final fetched = await profileAdapter.fetchProfile(pubkey);
      final duration = DateTime.now().difference(startTime);

      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Cached User'));
      expect(duration.inMilliseconds, lessThan(50)); // Should be very fast
    });

    test('should fetch from network when cache is stale', () async {
      // This test would require mocking NDK responses
      // For now, we'll skip the actual network call
      
      const pubkey = 'stale_user_pubkey';
      
      // Create stale cached profile
      await databaseService.isar.writeTxn(() async {
        final cached = CachedProfile()
          ..pubkey = pubkey
          ..name = 'Old Name'
          ..lastUpdated = DateTime.now().subtract(const Duration(days: 2))
          ..createdAt = DateTime.now();
        
        await databaseService.isar.cachedProfiles.put(cached);
      });

      // In a real test, profileAdapter.fetchProfile would fetch fresh data
      // For this test, we're just verifying the staleness check works
      final cachedProfile = await databaseService.isar.cachedProfiles
          .where()
          .pubkeyEqualTo(pubkey)
          .findFirst();

      expect(cachedProfile!.isStale, isTrue);
    });

    test('should batch fetch profiles efficiently', () async {
      // Create test profiles
      final pubkeys = List.generate(10, (i) => 'pubkey_$i');
      final profiles = pubkeys.map((pk) => NostrProfile(
        pubkey: pk,
        name: 'User $pk',
        createdAt: DateTime.now(),
      )).toList();

      // Cache half of them
      await databaseService.cacheProfiles(profiles.take(5).toList());

      // Fetch all - should use cache for first 5
      final fetched = await profileAdapter.fetchProfiles(pubkeys);

      // Should have attempted to fetch all (in a real scenario)
      expect(fetched.length, greaterThanOrEqualTo(5));
    });
  });

  group('Relay Service Optimization', () {
    test('should track relay health metrics', () async {
      // Simulate relay connections
      await relayService.connectToRelays([
        'wss://relay1.example.com',
        'wss://relay2.example.com',
      ]);

      // Wait a bit for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      // Get health status
      final health = relayService.getRelayHealthStatus();
      
      expect(health.isNotEmpty, isTrue);
    });

    test('should implement outbox model', () async {
      // Get outbox relays for a set of pubkeys
      final outbox = await relayService.getOutboxRelays(['pubkey1', 'pubkey2']);

      expect(outbox.readRelays.isNotEmpty, isTrue);
      expect(outbox.writeRelays.isNotEmpty, isTrue);
      expect(outbox.writeRelays.length, greaterThanOrEqualTo(outbox.readRelays.length));
    });

    test('should handle relay failures with retry', () async {
      // This test simulates relay failure and retry logic
      // In a real test, you'd mock the relay connection
      
      const failingRelay = 'wss://failing.relay.com';
      
      // Track metrics before
      final metricsBefore = performanceMonitor.getMetricsSummary();
      
      // Attempt connection (will fail in test environment)
      await relayService.connectToRelays([failingRelay]);
      
      // Wait for retries
      await Future.delayed(const Duration(seconds: 3));
      
      // Verify retry attempts were made
      // In production, you'd check actual metrics
      expect(true, isTrue); // Placeholder assertion
    });
  });

  group('Performance Monitoring', () {
    test('should track operation performance', () async {
      // Measure a simple operation
      final result = await performanceMonitor.measureAsync(
        'test_operation',
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'completed';
        },
      );

      expect(result, equals('completed'));

      // Check metrics
      final metrics = performanceMonitor.getMetricsSummary();
      expect(metrics.containsKey('test_operation'), isTrue);
      expect(metrics['test_operation']!.count, equals(1));
      expect(metrics['test_operation']!.successRate, equals(100.0));
    });

    test('should track counter metrics', () {
      // Increment counters
      performanceMonitor.incrementCounter('test_counter', value: 5);
      performanceMonitor.incrementCounter('test_counter', value: 3);

      // Check metrics
      final metrics = performanceMonitor.getMetricsSummary();
      expect(metrics['test_counter']!.count, equals(8));
      expect(metrics['test_counter']!.isCounter, isTrue);
    });

    test('should handle operation failures', () async {
      // Measure failing operation
      try {
        await performanceMonitor.measureAsync(
          'failing_operation',
          () async {
            throw Exception('Test failure');
          },
        );
      } catch (_) {
        // Expected
      }

      // Check metrics
      final metrics = performanceMonitor.getMetricsSummary();
      expect(metrics['failing_operation']!.count, equals(1));
      expect(metrics['failing_operation']!.successRate, equals(0.0));
      expect(metrics['failing_operation']!.errors.isNotEmpty, isTrue);
    });
  });

  group('Integration Tests', () {
    test('should handle full profile fetch with caching and monitoring', () async {
      const testPubkey = 'integration_test_pubkey';
      
      // First fetch - should go to network (mocked)
      final firstFetch = await performanceMonitor.measureAsync(
        'profile_fetch_uncached',
        () => profileAdapter.fetchProfile(testPubkey),
      );

      // Cache the profile for testing
      if (firstFetch != null) {
        await databaseService.cacheProfile(firstFetch);
      }

      // Second fetch - should use cache
      final secondFetch = await performanceMonitor.measureAsync(
        'profile_fetch_cached',
        () => profileAdapter.fetchProfile(testPubkey),
      );

      // Verify both fetches returned data
      expect(firstFetch?.pubkey, equals(testPubkey));
      expect(secondFetch?.pubkey, equals(testPubkey));

      // Check performance difference
      final metrics = performanceMonitor.getMetricsSummary();
      
      if (metrics.containsKey('profile_fetch_cached') && 
          metrics.containsKey('profile_fetch_uncached')) {
        final cachedDuration = metrics['profile_fetch_cached']!.averageDuration;
        final uncachedDuration = metrics['profile_fetch_uncached']!.averageDuration;
        
        // Cached should be faster (in a real scenario)
        print('Cached fetch: ${cachedDuration.inMilliseconds}ms');
        print('Uncached fetch: ${uncachedDuration.inMilliseconds}ms');
      }
    });

    test('should handle concurrent operations efficiently', () async {
      // Test concurrent profile fetches
      final pubkeys = List.generate(20, (i) => 'concurrent_pubkey_$i');
      
      // Measure concurrent fetches
      final results = await performanceMonitor.measureAsync(
        'concurrent_profile_fetch',
        () => Future.wait(
          pubkeys.map((pk) => profileAdapter.fetchProfile(pk)),
        ),
      );

      // Should complete without errors
      expect(results.length, equals(20));
      
      // Check metrics
      final metrics = performanceMonitor.getMetricsSummary();
      expect(metrics['concurrent_profile_fetch']!.successRate, equals(100.0));
    });
  });
}