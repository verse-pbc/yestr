import 'package:ndk/ndk.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as app_logger;
import '../key_management_service.dart';

/// Web-compatible NDK service that doesn't require Isar
/// This allows gift-wrapped messages to work on web
class NdkServiceWeb {
  static NdkServiceWeb? _instance;
  Ndk? _ndk;
  final KeyManagementService _keyManagementService;
  final app_logger.Logger _logger = app_logger.Logger();
  
  // Singleton pattern
  static NdkServiceWeb get instance {
    _instance ??= NdkServiceWeb._internal(KeyManagementService.instance);
    return _instance!;
  }
  
  NdkServiceWeb._internal(this._keyManagementService);
  
  /// Initialize NDK for web without Isar dependency
  Future<void> initialize({String? privateKey, String? publicKey}) async {
    if (_ndk != null) return;
    
    try {
      _logger.i('Initializing NDK for web...');
      
      // Initialize NDK with default config for web
      _ndk = Ndk.defaultConfig();
      
      // Login if credentials provided
      if (privateKey != null) {
        _ndk!.accounts.loginPrivateKey(
          pubkey: publicKey ?? await _generatePublicKey(privateKey),
          privkey: privateKey,
        );
        _logger.i('NDK logged in with private key');
      } else if (publicKey != null) {
        _ndk!.accounts.loginPublicKey(pubkey: publicKey);
        _logger.i('NDK logged in with public key (read-only)');
      }
      
      _logger.i('NDK for web initialized successfully');
    } catch (e) {
      _logger.e('Error initializing NDK for web', error: e);
      rethrow;
    }
  }
  
  /// Get the NDK instance
  Ndk get ndk {
    if (_ndk == null) {
      throw Exception('NDK not initialized. Call initialize() first.');
    }
    return _ndk!;
  }
  
  /// Check if NDK is initialized
  bool get isInitialized => _ndk != null;
  
  /// Clean up resources
  void dispose() {
    _ndk = null;
  }
  
  /// Generate public key from private key
  Future<String> _generatePublicKey(String privateKey) async {
    // For web, we require the public key to be provided
    // The key generation should be handled by the key management service
    final pubkey = await _keyManagementService.getPublicKey();
    if (pubkey == null) {
      throw Exception('Public key not available. Please provide both private and public keys.');
    }
    return pubkey;
  }
}