import 'package:flutter_test/flutter_test.dart';
import '../lib/services/service_migration_helper.dart';
import '../lib/services/follow_service_ndk.dart';
import '../lib/services/reaction_service_ndk.dart';
import '../lib/services/ndk_backup/ndk_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize services for testing
    try {
      await ServiceMigrationHelper.initializeNdk();
    } catch (e) {
      // Ignore errors related to Rust library in tests
      print('Error during NDK initialization (expected in test): $e');
    }
  });

  group('NDK Services Tests', () {
    test('NDK Service should initialize', () async {
      final ndkService = NdkService.instance;
      expect(ndkService.isInitialized, isTrue);
    });

    test('FollowService should be NDK-based when enabled', () async {
      await ServiceMigrationHelper.enableNdkServices();
      final followService = ServiceMigrationHelper.getFollowService();
      expect(followService, isA<FollowServiceNdk>());
    });

    test('ReactionService should be NDK-based when enabled', () async {
      await ServiceMigrationHelper.enableNdkServices();
      final reactionService = ServiceMigrationHelper.getReactionService();
      expect(reactionService, isA<ReactionServiceNdk>());
    });

    test('FollowService should handle follow operations', () async {
      await ServiceMigrationHelper.enableNdkServices();
      final followService = ServiceMigrationHelper.getFollowService() as FollowServiceNdk;
      
      // Test pubkey (random test key)
      const testPubkey = 'e77b246867ba5172e22c08b6add1c7de1049de997ad2fe6ea0a352131f9a0e9a';
      
      // Check initial state
      final isFollowing = followService.isFollowing(testPubkey);
      expect(isFollowing, isFalse);
      
      // Note: Actual follow/unfollow operations require authentication
      // This is just testing the service initialization and basic methods
    });

    test('Migration helper should track NDK state', () async {
      // Enable NDK
      await ServiceMigrationHelper.enableNdkServices();
      expect(ServiceMigrationHelper.isUsingNdk, isTrue);
      
      // Disable NDK
      ServiceMigrationHelper.disableNdkServices();
      expect(ServiceMigrationHelper.isUsingNdk, isFalse);
      
      // Re-enable for other tests
      await ServiceMigrationHelper.enableNdkServices();
    });
  });
}