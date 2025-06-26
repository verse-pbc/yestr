import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:flutter/foundation.dart';
import '../key_management_service.dart';

/// Core service for managing NDK (Nostr Development Kit) integration
/// This service initializes and configures NDK with JIT engine for efficient relay management
class NdkService {
  static NdkService? _instance;
  Ndk? _ndk;
  final KeyManagementService _keyManagementService;
  
  // Singleton pattern
  static NdkService get instance {
    _instance ??= NdkService._internal(KeyManagementService.instance);
    return _instance!;
  }
  
  NdkService._internal(this._keyManagementService);
  
  // For testing purposes
  @visibleForTesting
  NdkService.forTesting(this._keyManagementService);
  
  /// Initialize NDK with proper configuration
  Future<void> initialize() async {
    if (_ndk != null) return;
    
    try {
      // Create NDK configuration with JIT engine and Rust verifier for performance
      final config = NdkConfig(
        // Use JIT engine for optimal relay management (outbox model)
        engine: Engine.JIT,
        // Use Rust verifier for better performance on signature verification
        eventVerifier: RustEventVerifier(),
        // Use memory cache for now, can be replaced with persistent cache later
        cache: MemCacheManager(),
        // Bootstrap relays for initial connection
        bootstrapRelays: [
          'wss://relay.damus.io',
          'wss://relay.nostr.band',
          'wss://relay.snort.social',
          'wss://nos.lol',
          'wss://relay.nostr.bg',
          'wss://relay.primal.net',
        ],
        // Configure logging
        logLevel: kDebugMode ? LogLevel.trace : LogLevel.warning,
      );
      
      // Initialize NDK
      _ndk = Ndk(config);
      
      // Load account if available
      await _loadAccount();
      
      debugPrint('NDK initialized successfully with JIT engine');
    } catch (e) {
      debugPrint('Error initializing NDK: $e');
      rethrow;
    }
  }
  
  /// Load user account from key management service
  Future<void> _loadAccount() async {
    final privateKey = await _keyManagementService.getPrivateKey();
    if (privateKey != null && privateKey.isNotEmpty) {
      try {
        // Create account from private key
        final keyPair = KeyPair.fromPrivateKey(privateKey);
        _ndk!.accounts.login(keyPair);
        debugPrint('Account loaded successfully');
      } catch (e) {
        debugPrint('Error loading account: $e');
      }
    }
  }
  
  /// Login with private key
  Future<void> login(String privateKey) async {
    if (_ndk == null) {
      await initialize();
    }
    
    try {
      final keyPair = KeyPair.fromPrivateKey(privateKey);
      _ndk!.accounts.login(keyPair);
      
      // Save to key management service
      await _keyManagementService.savePrivateKey(privateKey);
      
      debugPrint('Login successful');
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    }
  }
  
  /// Logout current user
  Future<void> logout() async {
    if (_ndk != null) {
      _ndk!.accounts.logout();
      await _keyManagementService.clearKeys();
      debugPrint('Logout successful');
    }
  }
  
  /// Get the NDK instance
  Ndk get ndk {
    if (_ndk == null) {
      throw StateError('NDK not initialized. Call initialize() first.');
    }
    return _ndk!;
  }
  
  /// Check if NDK is initialized
  bool get isInitialized => _ndk != null;
  
  /// Check if user is logged in
  bool get isLoggedIn => _ndk?.accounts.currentAccount != null;
  
  /// Get current user's public key
  String? get currentUserPubkey => _ndk?.accounts.currentAccount?.pubkey;
  
  /// Dispose NDK service
  void dispose() {
    _ndk = null;
    _instance = null;
  }
}