import 'package:flutter/foundation.dart';

/// Helper class to handle CORS issues on web platform
class CorsHelper {
  /// List of known CORS proxy services (use with caution in production)
  static const List<String> corsProxies = [
    'https://thingproxy.freeboard.io/fetch/',
  ];
  
  /// Track failed domains during runtime
  static final Set<String> _failedDomains = {};
  
  /// Check if URL needs CORS proxy (for web platform)
  static bool needsCorsProxy(String url) {
    // CORS proxy should ONLY be used on web platform
    // On mobile apps, direct requests work fine
    if (!kIsWeb) return false;
    
    // Enable CORS proxy for all non-localhost URLs on web
    try {
      final uri = Uri.parse(url);
      // Don't proxy localhost or data URLs
      if (uri.host.contains('localhost') || 
          uri.host.contains('127.0.0.1') || 
          url.startsWith('data:')) {
        return false;
      }
      // Proxy all external images on web
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Mark a domain as needing CORS proxy
  static void markDomainAsFailed(String url) {
    if (!kIsWeb) return;
    
    try {
      final uri = Uri.parse(url);
      _failedDomains.add(uri.host);
      if (kDebugMode) {
        print('[CorsHelper] Marked ${uri.host} as needing CORS proxy');
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }
  
  /// Wrap URL with CORS proxy if needed
  static String wrapWithCorsProxy(String url) {
    if (!needsCorsProxy(url)) return url;
    
    // If no working proxies available, return original URL
    if (corsProxies.isEmpty) {
      if (kDebugMode) {
        print('[CorsHelper] No CORS proxies available, returning original URL: $url');
      }
      return url;
    }
    
    // Use the first available CORS proxy
    final proxy = corsProxies.first;
    
    // For thingproxy, we don't need to encode the URL
    final proxiedUrl = '$proxy$url';
    
    if (kDebugMode) {
      print('[CorsHelper] Wrapping URL with CORS proxy: $url');
      print('[CorsHelper] Proxied URL: $proxiedUrl');
    }
    
    return proxiedUrl;
  }
}