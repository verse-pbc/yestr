import 'package:flutter/foundation.dart';
import 'follow_service.dart';
import 'follow_service_ndk.dart';
import 'reaction_service.dart';
import 'reaction_service_ndk.dart';
import 'direct_message_service_v2.dart';
import 'ndk_backup/ndk_service.dart';
import 'ndk_backup/ndk_service_web.dart';
import 'ndk_backup/ndk_adapter_service.dart';
import 'key_management_service.dart';

/// Enhanced helper class that supports web-based NDK for gift-wrapped messages
class ServiceMigrationHelperWeb {
  static bool _useNdkServices = false;
  static bool _ndkInitialized = false;
  
  /// Initialize services with proper web support
  static Future<void> initialize({
    required bool isNdkMode,
    String? privateKey,
    String? publicKey,
  }) async {
    if (isNdkMode) {
      try {
        if (kIsWeb) {
          // Use web-compatible NDK (no Isar dependency)
          await NdkServiceWeb.instance.initialize(
            privateKey: privateKey,
            publicKey: publicKey,
          );
          _ndkInitialized = true;
          _useNdkServices = true;
          print('Web-compatible NDK services initialized successfully');
        } else {
          // Use full NDK with Isar for mobile/desktop
          await NdkService.instance.initialize();
          await NdkAdapterService.instance.initialize();
          _ndkInitialized = true;
          _useNdkServices = true;
          print('Full NDK services initialized successfully');
        }
      } catch (e) {
        print('Error initializing NDK: $e');
        print('Falling back to legacy services');
        _useNdkServices = false;
        _ndkInitialized = false;
      }
    } else {
      _useNdkServices = false;
      _ndkInitialized = false;
    }
  }
  
  /// Check if NDK services are enabled
  static bool get isUsingNdk => _useNdkServices;
  
  /// Get the appropriate DirectMessageService
  static DirectMessageService getDirectMessageService() {
    // Always return v2 which internally uses NDK with gift wrap support
    return DirectMessageService(KeyManagementService.instance);
  }
  
  /// Get the appropriate FollowService
  static dynamic getFollowService() {
    if (_useNdkServices) {
      return FollowServiceNdk();
    }
    return FollowService();
  }
  
  /// Get the appropriate ReactionService
  static dynamic getReactionService() {
    if (_useNdkServices) {
      return ReactionServiceNdk();
    }
    return ReactionService();
  }
}