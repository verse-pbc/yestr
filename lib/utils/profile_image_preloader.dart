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
    
    for (final profile in profiles) {
      // Preload thumbnail size (used in lists)
      if (includeThumbnails) {
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(
              AvatarHelper.getThumbnail(profile.pubkey),
            ),
            context,
          ).catchError((_) {
            // Ignore errors for individual images
            return null;
          }),
        );
      }
      
      // Preload medium size (used in cards and profile details)
      if (includeMedium) {
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(
              AvatarHelper.getMedium(profile.pubkey),
            ),
            context,
          ).catchError((_) {
            // Ignore errors for individual images
            return null;
          }),
        );
      }
    }
    
    // Wait for all images to load (with a timeout to prevent hanging)
    await Future.wait(futures).timeout(
      const Duration(seconds: 10),
      onTimeout: () => [],
    );
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