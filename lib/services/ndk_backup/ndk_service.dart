import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
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
        // Bootstrap relays for initial connection - include common DM relays
        bootstrapRelays: [
          'wss://relay.damus.io',
          'wss://relay.nostr.band',
          'wss://relay.snort.social',
          'wss://nos.lol',
          'wss://relay.nostr.bg',
          'wss://relay.primal.net',
          'wss://nostr.wine',
          'wss://relay.nostr.wirednet.jp',
          'wss://offchain.pub',
          'wss://purplepag.es',
        ],
        // Configure logging - set to error level to hide connection status messages
        logLevel: kDebugMode ? Level.error : Level.error,
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
        // Generate pubkey from private key using Bip340
        final pubkey = Bip340.getPublicKey(privateKey);
        
        debugPrint('Loading account with pubkey: $pubkey');
        _ndk!.accounts.loginPrivateKey(pubkey: pubkey, privkey: privateKey);
        
        // Verify login
        final loggedInPubkey = _ndk!.accounts.getPublicKey();
        debugPrint('Account loaded successfully. Logged in pubkey: $loggedInPubkey');
      } catch (e) {
        debugPrint('Error loading account: $e');
      }
    } else {
      debugPrint('No private key available to load account');
    }
  }
  
  /// Login with private key
  Future<void> login(String privateKey) async {
    if (_ndk == null) {
      await initialize();
    }
    
    try {
      // Get the hex private key (handles nsec conversion in KeyManagementService)
      final hexPrivateKey = await _keyManagementService.getPrivateKey();
      if (hexPrivateKey == null || hexPrivateKey.isEmpty) {
        throw Exception('Failed to get hex private key');
      }
      
      // Extract pubkey from private key using Bip340
      final pubkey = Bip340.getPublicKey(hexPrivateKey);
      
      debugPrint('Attempting to login with pubkey: $pubkey');
      
      // Check if already logged in with this pubkey
      if (_ndk!.accounts.isLoggedIn && _ndk!.accounts.getPublicKey() == pubkey) {
        debugPrint('Already logged in with this pubkey');
        return;
      }
      
      // Logout first if logged in with different account
      if (_ndk!.accounts.isLoggedIn) {
        debugPrint('Logging out existing account: ${_ndk!.accounts.getPublicKey()}');
        _ndk!.accounts.logout();
      }
      
      debugPrint('Logging in with pubkey: $pubkey');
      _ndk!.accounts.loginPrivateKey(pubkey: pubkey, privkey: hexPrivateKey);
      
      // Verify login
      final loggedInPubkey = _ndk!.accounts.getPublicKey();
      debugPrint('Login successful. Verified pubkey: $loggedInPubkey');
      
      if (loggedInPubkey != pubkey) {
        throw Exception('NDK login verification failed: pubkey mismatch');
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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