import 'package:isar/isar.dart';

part 'cached_profile.g.dart';

/// Cached profile data stored in Isar database for offline access and performance
@Collection(accessor: 'cachedProfiles')
class CachedProfile {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String pubkey;
  
  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? about;
  String? nip05;
  String? lud16;
  String? website;
  
  @Index()
  late DateTime lastUpdated;
  
  late DateTime createdAt;
  
  // Track failed image URLs to avoid re-loading
  List<String> failedImageUrls = [];
  
  // Cache validation - profiles older than 24 hours should be refreshed
  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours > 24;
  }
  
  // Helper to check if a specific image URL has failed
  bool hasFailedImageUrl(String? url) {
    if (url == null) return false;
    return failedImageUrls.contains(url);
  }
}