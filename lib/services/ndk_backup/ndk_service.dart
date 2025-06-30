import 'package:ndk/ndk.dart';
import 'package:ndk_rust_verifier/ndk_rust_verifier.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../key_management_service.dart';
import '../database/isar_database_service.dart';
import '../cache/ndk_cache_manager.dart';

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
      // Initialize Isar database first (skip on web)
      IsarDatabaseService? database;
      if (!kIsWeb) {
        database = IsarDatabaseService.instance;
        await database.initialize();
      }
      
      // Create NDK configuration with JIT engine and Rust verifier for performance
      final config = NdkConfig(
        // Use JIT engine for optimal relay management (outbox model)
        engine: NdkEngine.JIT,
        // Use Rust verifier for better performance on signature verification
        eventVerifier: RustEventVerifier(),
        // Use Isar cache on native, memory cache on web
        cache: kIsWeb || database == null 
            ? MemCacheManager() 
            : NdkCacheManager(database),
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
        logLevel: kDebugMode ? Level.trace : Level.warning,
      );
      
      debugPrint('🚀 NDK Configuration:');
      debugPrint('  Engine: JIT (Outbox Model Enabled)');
      debugPrint('  Event Verifier: Rust');
      debugPrint('  Cache: ${kIsWeb ? "Memory" : "Isar"}');
      debugPrint('  Bootstrap Relays: ${config.bootstrapRelays.length}');
      
      // Initialize NDK
      _ndk = Ndk(config);
      
      // Load account if available
      await _loadAccount();
      
      debugPrint('NDK initialized successfully with JIT engine and Isar cache');
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
        // Login with private key
        final pubkey = await _keyManagementService.getPublicKey();
        if (pubkey != null) {
          _ndk!.accounts.loginPrivateKey(pubkey: pubkey, privkey: privateKey);
        }
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
      // Extract pubkey from private key using Bip340EventSigner
      final signer = Bip340EventSigner(privateKey: privateKey, publicKey: '');
      final pubkey = signer.getPublicKey();
      _ndk!.accounts.loginPrivateKey(pubkey: pubkey, privkey: privateKey);
      
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
  bool get isLoggedIn => _ndk?.accounts.isLoggedIn ?? false;
  
  /// Get current user's public key
  String? get currentUserPubkey => _ndk?.accounts.getPublicKey();
  
  /// Dispose NDK service
  void dispose() {
    _ndk = null;
    _instance = null;
  }
}