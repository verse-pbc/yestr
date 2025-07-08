import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nostr_profile.dart';
import '../utils/avatar_helper.dart';

/// Service to proactively preload profile images in the background
class ProfileImagePreloadService {
  static final ProfileImagePreloadService _instance = ProfileImagePreloadService._internal();
  factory ProfileImagePreloadService() => _instance;
  ProfileImagePreloadService._internal();

  // Configuration
  static const int _batchSize = 10;
  static const int _preloadAhead = 20; // Always keep 20 images preloaded ahead
  static const int _concurrentDownloads = 5;
  
  // State
  final Map<String, bool> _preloadedImages = {};
  final Set<String> _currentlyPreloading = {};
  int _currentIndex = 0;
  List<NostrProfile> _profiles = [];
  Timer? _preloadTimer;
  bool _isPreloading = false;
  
  /// Initialize the service with a list of profiles
  void initialize(List<NostrProfile> profiles) {
    print('[ProfileImagePreloadService] Initializing with ${profiles.length} profiles');
    _profiles = profiles;
    _currentIndex = 0;
    _preloadedImages.clear();
    _currentlyPreloading.clear();
    
    // Start preloading immediately
    _startContinuousPreloading();
  }
  
  /// Update the current swipe position
  void updateCurrentIndex(int index) {
    _currentIndex = index;
    print('[ProfileImagePreloadService] Current index updated to: $index');
    
    // Trigger preloading if needed
    _checkAndPreloadMore();
  }
  
  /// Add more profiles to the list
  void addProfiles(List<NostrProfile> newProfiles) {
    print('[ProfileImagePreloadService] Adding ${newProfiles.length} new profiles');
    _profiles.addAll(newProfiles);
    
    // Continue preloading with new profiles
    _checkAndPreloadMore();
  }
  
  /// Start continuous background preloading
  void _startContinuousPreloading() {
    _preloadTimer?.cancel();
    
    // Check every 500ms if we need to preload more
    _preloadTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isPreloading) {
        _checkAndPreloadMore();
      }
    });
    
    // Initial preload
    _checkAndPreloadMore();
  }
  
  /// Check if we need to preload more images
  void _checkAndPreloadMore() {
    if (_isPreloading || _profiles.isEmpty) return;
    
    // Calculate how many images ahead we have preloaded
    int preloadedAhead = 0;
    for (int i = _currentIndex; i < _profiles.length && i < _currentIndex + _preloadAhead; i++) {
      final imageUrl = AvatarHelper.getMedium(_profiles[i].pubkey);
      if (_preloadedImages[imageUrl] == true) {
        preloadedAhead++;
      } else {
        break; // Stop counting at first non-preloaded image
      }
    }
    
    // If we have less than half of our target preloaded, load more
    if (preloadedAhead < _preloadAhead ~/ 2) {
      print('[ProfileImagePreloadService] Only $preloadedAhead images preloaded ahead, loading more...');
      _preloadNextBatch();
    }
  }
  
  /// Preload the next batch of images
  Future<void> _preloadNextBatch() async {
    if (_isPreloading) return;
    _isPreloading = true;
    
    try {
      // Find the next batch of profiles to preload
      final startIndex = _currentIndex;
      final endIndex = (_currentIndex + _preloadAhead).clamp(0, _profiles.length);
      
      if (startIndex >= endIndex) {
        print('[ProfileImagePreloadService] No more profiles to preload');
        return;
      }
      
      // Collect URLs that need preloading
      final urlsToPreload = <String>[];
      for (int i = startIndex; i < endIndex; i++) {
        final imageUrl = AvatarHelper.getMedium(_profiles[i].pubkey);
        
        // Skip if already preloaded or currently preloading
        if (_preloadedImages[imageUrl] == true || _currentlyPreloading.contains(imageUrl)) {
          continue;
        }
        
        urlsToPreload.add(imageUrl);
        
        // Limit batch size
        if (urlsToPreload.length >= _batchSize) break;
      }
      
      if (urlsToPreload.isEmpty) {
        print('[ProfileImagePreloadService] All images in range already preloaded');
        return;
      }
      
      print('[ProfileImagePreloadService] Preloading ${urlsToPreload.length} images...');
      
      // Mark as currently preloading
      _currentlyPreloading.addAll(urlsToPreload);
      
      // Preload images in parallel with concurrency limit
      final chunks = _chunkList(urlsToPreload, _concurrentDownloads);
      
      for (final chunk in chunks) {
        await Future.wait(
          chunk.map((url) => _preloadSingleImage(url)),
          eagerError: false, // Don't fail if one image fails
        );
      }
      
    } finally {
      _isPreloading = false;
    }
  }
  
  /// Preload a single image
  Future<void> _preloadSingleImage(String imageUrl) async {
    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      
      // Use precacheImage to download and cache the image
      await precacheImage(
        imageProvider,
        navigatorKey.currentContext!,
        onError: (exception, stackTrace) {
          print('[ProfileImagePreloadService] Failed to preload $imageUrl: $exception');
        },
      );
      
      _preloadedImages[imageUrl] = true;
      print('[ProfileImagePreloadService] Successfully preloaded: ${imageUrl.substring(0, 50)}...');
      
    } catch (e) {
      print('[ProfileImagePreloadService] Error preloading $imageUrl: $e');
    } finally {
      _currentlyPreloading.remove(imageUrl);
    }
  }
  
  /// Split list into chunks for parallel processing
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, list.length);
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
  
  /// Check if an image is preloaded
  bool isImagePreloaded(String pubkey) {
    final imageUrl = AvatarHelper.getMedium(pubkey);
    return _preloadedImages[imageUrl] == true;
  }
  
  /// Get preload statistics
  Map<String, dynamic> getStats() {
    return {
      'totalProfiles': _profiles.length,
      'currentIndex': _currentIndex,
      'preloadedImages': _preloadedImages.length,
      'currentlyPreloading': _currentlyPreloading.length,
      'preloadedAhead': _getPreloadedAheadCount(),
    };
  }
  
  int _getPreloadedAheadCount() {
    int count = 0;
    for (int i = _currentIndex; i < _profiles.length && i < _currentIndex + _preloadAhead; i++) {
      final imageUrl = AvatarHelper.getMedium(_profiles[i].pubkey);
      if (_preloadedImages[imageUrl] == true) {
        count++;
      }
    }
    return count;
  }
  
  /// Dispose the service
  void dispose() {
    _preloadTimer?.cancel();
    _preloadedImages.clear();
    _currentlyPreloading.clear();
    _profiles.clear();
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();