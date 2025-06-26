import 'follow_service.dart';
import 'follow_service_ndk.dart';
import 'reaction_service.dart';
import 'reaction_service_ndk.dart';
import 'ndk_backup/ndk_service.dart';

/// Helper class to manage the migration from old services to NDK-based services
class ServiceMigrationHelper {
  static bool _useNdkServices = false;
  static bool _ndkInitialized = false;
  
  /// Initialize NDK services
  static Future<void> initializeNdk() async {
    if (!_ndkInitialized) {
      await NdkService.instance.initialize();
      _ndkInitialized = true;
    }
  }
  
  /// Enable NDK services
  static Future<void> enableNdkServices() async {
    await initializeNdk();
    _useNdkServices = true;
  }
  
  /// Disable NDK services (fallback to old implementation)
  static void disableNdkServices() {
    _useNdkServices = false;
  }
  
  /// Check if NDK services are enabled
  static bool get isUsingNdk => _useNdkServices;
  
  /// Get the appropriate FollowService based on configuration
  static dynamic getFollowService() {
    if (_useNdkServices) {
      return FollowServiceNdk();
    }
    return FollowService();
  }
  
  /// Get the appropriate ReactionService based on configuration
  static dynamic getReactionService() {
    if (_useNdkServices) {
      return ReactionServiceNdk();
    }
    return ReactionService();
  }
  
  /// Migrate follow data from old service to NDK
  static Future<void> migrateFollowData() async {
    if (!_useNdkServices) {
      await enableNdkServices();
    }
    
    // Get followed profiles from old service
    final oldService = FollowService();
    final followedProfiles = oldService.followedProfiles;
    
    // Load them into NDK service (it will sync with relays)
    final ndkService = FollowServiceNdk();
    await ndkService.loadContactListFromRelays();
    
    print('Migrated ${followedProfiles.length} followed profiles to NDK');
  }
}