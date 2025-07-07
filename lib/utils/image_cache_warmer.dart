import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

/// Warms up the image cache by establishing connections to the Yestr Face proxy
class ImageCacheWarmer {
  static bool _hasWarmedUp = false;
  
  /// Warm up the cache by establishing connections to the proxy server
  /// This should be called early in the app lifecycle
  static Future<void> warmUp(BuildContext context) async {
    if (_hasWarmedUp) return;
    _hasWarmedUp = true;
    
    try {
      // Warm up connection to Yestr Face by loading a small test image
      // This establishes SSL handshake and DNS resolution early
      const testPubkey = '0000000000000000000000000000000000000000000000000000000000000000';
      final warmupUrl = '${AppConfig.avatarProxyUrl}/avatar/$testPubkey?size=1';
      
      await precacheImage(
        CachedNetworkImageProvider(warmupUrl),
        context,
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // Ignore timeout - this is just a warmup
        },
      );
      
      print('Image cache warmed up - connection to Yestr Face established');
    } catch (e) {
      print('Cache warmup failed (non-critical): $e');
    }
  }
  
  /// Clear the image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache(
      '${AppConfig.avatarProxyUrl}/avatar/',
    );
  }
}