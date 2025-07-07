import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nostr_profile.dart';
import 'avatar_helper.dart';

/// Utility class for preloading profile images
class ProfileImagePreloader {
  /// Preload profile images for a list of profiles
  /// This ensures images are in cache before they're displayed
  static Future<void> preloadProfileImages(
    BuildContext context,
    List<NostrProfile> profiles, {
    bool includeThumbnails = true,
    bool includeMedium = true,
  }) async {
    if (profiles.isEmpty) return;
    
    final futures = <Future>[];
    
    // Process in smaller batches for better performance
    const batchSize = 3;
    for (var i = 0; i < profiles.length; i += batchSize) {
      final batch = profiles.skip(i).take(batchSize).toList();
      
      for (final profile in batch) {
        // Preload thumbnail size (used in lists)
        if (includeThumbnails) {
          futures.add(
            _preloadSingleImage(
              context,
              AvatarHelper.getThumbnail(profile.pubkey),
            ),
          );
        }
        
        // Preload medium size (used in cards and profile details)
        if (includeMedium) {
          futures.add(
            _preloadSingleImage(
              context,
              AvatarHelper.getMedium(profile.pubkey),
            ),
          );
        }
      }
      
      // Small delay between batches to avoid overwhelming the network
      if (i + batchSize < profiles.length) {
        futures.add(Future.delayed(const Duration(milliseconds: 50)));
      }
    }
    
    // Don't wait forever - use a reasonable timeout
    await Future.wait(futures).timeout(
      const Duration(seconds: 8),
      onTimeout: () => [],
    );
  }
  
  /// Preload a single image with error handling
  static Future<void> _preloadSingleImage(BuildContext context, String url) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
      );
    } catch (e) {
      // Silently ignore individual image load failures
      // The image will be loaded when actually displayed
    }
  }
  
  /// Preload a single profile image
  static Future<void> preloadSingleProfile(
    BuildContext context,
    NostrProfile profile, {
    bool includeThumbnail = true,
    bool includeMedium = true,
  }) async {
    await preloadProfileImages(
      context,
      [profile],
      includeThumbnails: includeThumbnail,
      includeMedium: includeMedium,
    );
  }
}