import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../key_management_service.dart';
import 'ndk_adapter_service.dart';

/// Helper class to migrate from old services to NDK
class NdkMigrationHelper {
  static const String _migrationKey = 'ndk_migration_completed';
  static const String _savedProfilesKey = 'saved_profiles';
  
  /// Check if migration has been completed
  static Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }
  
  /// Perform migration from old services to NDK
  static Future<bool> performMigration() async {
    try {
      print('Starting NDK migration...');
      
      // Initialize NDK
      final ndkAdapter = NdkAdapterService.instance;
      await ndkAdapter.initialize();
      
      // Migrate user account
      await _migrateUserAccount(ndkAdapter);
      
      // Migrate saved profiles
      await _migrateSavedProfiles();
      
      // Mark migration as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationKey, true);
      
      print('NDK migration completed successfully');
      return true;
    } catch (e) {
      print('Error during NDK migration: $e');
      return false;
    }
  }
  
  /// Migrate user account from old key management to NDK
  static Future<void> _migrateUserAccount(NdkAdapterService ndkAdapter) async {
    try {
      final keyService = KeyManagementService.instance;
      final privateKey = await keyService.getPrivateKey();
      
      if (privateKey != null && privateKey.isNotEmpty) {
        await ndkAdapter.login(privateKey);
        print('User account migrated successfully');
      }
    } catch (e) {
      print('Error migrating user account: $e');
    }
  }
  
  /// Migrate saved profiles from SharedPreferences
  static Future<void> _migrateSavedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProfilesJson = prefs.getString(_savedProfilesKey);
      
      if (savedProfilesJson != null) {
        final savedProfiles = json.decode(savedProfilesJson) as List;
        print('Found ${savedProfiles.length} saved profiles to migrate');
        
        // Note: The actual migration of saved profiles would be handled
        // by the SavedProfilesService when it's updated to use NDK
      }
    } catch (e) {
      print('Error migrating saved profiles: $e');
    }
  }
  
  /// Reset migration (for testing purposes)
  static Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_migrationKey);
    print('Migration reset completed');
  }
  
  /// Get migration status details
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keyService = KeyManagementService.instance;
    
    return {
      'migrationCompleted': prefs.getBool(_migrationKey) ?? false,
      'hasPrivateKey': await keyService.getPrivateKey() != null,
      'hasSavedProfiles': prefs.getString(_savedProfilesKey) != null,
      'ndkInitialized': NdkAdapterService.instance.isInitialized,
      'userLoggedIn': NdkAdapterService.instance.isLoggedIn,
    };
  }
}