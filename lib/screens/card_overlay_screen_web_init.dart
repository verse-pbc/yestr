import 'package:flutter/foundation.dart';
import '../services/service_migration_helper_web.dart';
import '../services/key_management_service.dart';

/// Helper mixin to initialize web-compatible NDK after login
mixin WebNdkInitializer {
  /// Try to initialize web-compatible NDK with gift wrap support
  Future<bool> initializeWebNdk() async {
    if (!kIsWeb) return false;
    
    try {
      final keyService = KeyManagementService.instance;
      final privateKey = await keyService.getPrivateKey();
      final publicKey = await keyService.getPublicKey();
      
      if (privateKey == null && publicKey == null) {
        print('[WebNDK] No keys available, skipping NDK initialization');
        return false;
      }
      
      print('[WebNDK] Initializing web-compatible NDK with gift wrap support...');
      
      await ServiceMigrationHelperWeb.initialize(
        isNdkMode: true,
        privateKey: privateKey,
        publicKey: publicKey,
      );
      
      if (ServiceMigrationHelperWeb.isUsingNdk) {
        print('[WebNDK] ✅ Web NDK initialized successfully - Gift wrap enabled!');
        return true;
      } else {
        print('[WebNDK] ❌ Failed to initialize web NDK');
        return false;
      }
    } catch (e) {
      print('[WebNDK] Error initializing web NDK: $e');
      return false;
    }
  }
}