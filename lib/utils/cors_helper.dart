import 'package:flutter/foundation.dart';

/// Helper class to handle CORS issues on web platform
class CorsHelper {
  /// List of known CORS proxy services (use with caution in production)
  static const List<String> corsProxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
  ];
  
  /// Track failed domains during runtime
  static final Set<String> _failedDomains = {};
  
  /// Check if URL needs CORS proxy (for web platform)
  static bool needsCorsProxy(String url) {
    // CORS proxy should ONLY be used on web platform
    // On mobile apps, direct requests work fine
    if (!kIsWeb) return false;
    
    // List of domains known to have CORS issues on web
    final problematicDomains = [
      'charlie.fish',
      'misskey.bubbletea.dev',
      'social.heise.de',
      'social.trom.tf',
      'poliverso.org',
      's3.solarcom.ch',
      'media.misskeyusercontent.com',
      'r2.primal.net', // Add primal.net cache
    ];
    
    try {
      final uri = Uri.parse(url);
      // Check if domain is in the known problematic list or has failed before
      return problematicDomains.any((domain) => uri.host.contains(domain)) ||
             _failedDomains.contains(uri.host);
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
    
    // Use the first available CORS proxy
    final proxy = corsProxies.first;
    
    if (kDebugMode) {
      print('[CorsHelper] Wrapping URL with CORS proxy: $url');
      print('[CorsHelper] Proxied URL: $proxy${Uri.encodeComponent(url)}');
    }
    
    return '$proxy${Uri.encodeComponent(url)}';
  }
}