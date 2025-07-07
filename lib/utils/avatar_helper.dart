import '../config/app_config.dart';

/// Helper class for generating avatar proxy URLs
class AvatarHelper {
  /// Get proxy URL for a profile picture
  static String getProxyUrl(String? originalUrl, String pubkey, {int size = 400}) {
    // Always use proxy for consistent CORS handling
    return '${AppConfig.avatarProxyUrl}/avatar/$pubkey?size=$size';
  }
  
  /// Get thumbnail size avatar (200px)
  static String getThumbnail(String pubkey) {
    return getProxyUrl(null, pubkey, size: AppConfig.thumbnailSize);
  }
  
  /// Get medium size avatar (400px)
  static String getMedium(String pubkey) {
    return getProxyUrl(null, pubkey, size: AppConfig.mediumSize);
  }
  
  /// Get large size avatar (800px)
  static String getLarge(String pubkey) {
    return getProxyUrl(null, pubkey, size: AppConfig.largeSize);
  }
  
  /// Check if we should use the proxy
  static bool shouldUseProxy() {
    return AppConfig.useAvatarProxy;
  }
  
  /// Get the appropriate image URL (proxy or original)
  static String getImageUrl(String? originalUrl, String pubkey, {int size = 400}) {
    if (shouldUseProxy()) {
      return getProxyUrl(originalUrl, pubkey, size: size);
    }
    return originalUrl ?? '';
  }
}