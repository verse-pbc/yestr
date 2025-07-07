import 'dart:async';
import 'package:flutter/material.dart';
import '../models/nostr_profile.dart';
import '../utils/profile_image_preloader.dart';
import '../utils/image_cache_warmer.dart';
import 'yestr_relay_service.dart';
import 'nostr_band_api_service.dart';
import 'nostr_service.dart';

/// Service to handle app initialization and preloading
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();
  
  final YestrRelayService _yestrRelayService = YestrRelayService();
  final NostrBandApiService _nostrBandApiService = NostrBandApiService();
  final NostrService _nostrService = NostrService();
  
  List<NostrProfile> _preloadedProfiles = [];
  bool _isInitialized = false;
  bool _isInitializing = false;
  final _initializationCompleter = Completer<void>();
  
  /// Get preloaded profiles
  List<NostrProfile> get preloadedProfiles => List.from(_preloadedProfiles);
  
  /// Check if initialization is complete
  bool get isInitialized => _isInitialized;
  
  /// Wait for initialization to complete
  Future<void> get initializationComplete => _initializationCompleter.future;
  
  /// Initialize app data on launch
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    
    try {
      print('🚀 AppInitializationService: Starting app initialization...');
      
      // Warm up image cache connection first
      final cacheWarmupFuture = ImageCacheWarmer.warmUp(context);
      
      // Connect to Nostr service
      final nostrConnectFuture = _nostrService.connect();
      
      // Fetch profiles from Yestr relay
      final profilesFuture = _fetchInitialProfiles();
      
      // Wait for critical tasks
      await Future.wait([
        cacheWarmupFuture,
        nostrConnectFuture,
        profilesFuture,
      ]);
      
      // If we have profiles, start preloading their images
      if (_preloadedProfiles.isNotEmpty && context.mounted) {
        // Preload images for first 10 profiles
        await ProfileImagePreloader.preloadProfileImages(
          context,
          _preloadedProfiles.take(10).toList(),
          includeThumbnails: false,
          includeMedium: true,
        );
        
        print('✅ AppInitializationService: Preloaded images for ${_preloadedProfiles.take(10).length} profiles');
      }
      
      _isInitialized = true;
      _initializationCompleter.complete();
      
      print('✅ AppInitializationService: Initialization complete with ${_preloadedProfiles.length} profiles');
    } catch (e) {
      print('❌ AppInitializationService: Error during initialization: $e');
      _isInitialized = true; // Mark as initialized even on error
      _initializationCompleter.complete();
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Fetch initial profiles from available sources
  Future<void> _fetchInitialProfiles() async {
    try {
      // Try Yestr relay first (fastest)
      print('AppInitializationService: Fetching profiles from Yestr relay...');
      final yestrProfiles = await _yestrRelayService.getRandomProfiles(count: 50);
      
      if (yestrProfiles.isNotEmpty) {
        _preloadedProfiles = yestrProfiles;
        print('AppInitializationService: Got ${yestrProfiles.length} profiles from Yestr relay');
        return;
      }
      
      // Fallback to Nostr Band API
      print('AppInitializationService: Falling back to Nostr Band API...');
      final trendingProfiles = await _nostrBandApiService.fetchTrendingProfiles();
      
      if (trendingProfiles.isNotEmpty) {
        _preloadedProfiles = trendingProfiles;
        print('AppInitializationService: Got ${trendingProfiles.length} profiles from Nostr Band');
        return;
      }
      
      print('AppInitializationService: No profiles fetched during initialization');
    } catch (e) {
      print('AppInitializationService: Error fetching initial profiles: $e');
    }
  }
  
  /// Clear preloaded data (useful for testing or logout)
  void clearPreloadedData() {
    _preloadedProfiles.clear();
    _isInitialized = false;
  }
}