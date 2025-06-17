import 'dart:convert';

class NostrProfile {
  final String pubkey;
  final String? name;
  final String? displayName;
  final String? picture;
  final String? about;
  final String? banner;
  final String? website;
  final String? nip05;
  final String? lud16;
  final DateTime? createdAt;

  NostrProfile({
    required this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.about,
    this.banner,
    this.website,
    this.nip05,
    this.lud16,
    this.createdAt,
  });

  factory NostrProfile.fromNostrEvent(Map<String, dynamic> event) {
    try {
      final content = event['content'] as String;
      final profileData = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate and clean picture URL
      String? pictureUrl = profileData['picture'] as String?;
      if (pictureUrl != null && pictureUrl.isNotEmpty) {
        // Trim whitespace
        pictureUrl = pictureUrl.trim();
        // Validate URL format
        try {
          final uri = Uri.parse(pictureUrl);
          if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
            pictureUrl = null;
          }
        } catch (e) {
          print('Invalid picture URL for ${profileData['name'] ?? 'unknown'}: $pictureUrl');
          pictureUrl = null;
        }
      }
      
      // Debug logging for specific profiles
      if (profileData['name']?.toString().toLowerCase().contains('airport') == true) {
        print('Debug: Parsing AirportStatusBot profile');
        print('Raw picture URL: ${profileData['picture']}');
        print('Cleaned picture URL: $pictureUrl');
      }
      
      return NostrProfile(
        pubkey: event['pubkey'] as String,
        name: profileData['name'] as String?,
        displayName: profileData['display_name'] as String?,
        picture: pictureUrl,
        about: profileData['about'] as String?,
        banner: profileData['banner'] as String?,
        website: profileData['website'] as String?,
        nip05: profileData['nip05'] as String?,
        lud16: profileData['lud16'] as String?,
        createdAt: event['created_at'] != null 
            ? DateTime.fromMillisecondsSinceEpoch((event['created_at'] as int) * 1000)
            : null,
      );
    } catch (e) {
      print('Error parsing profile: $e');
      return NostrProfile(pubkey: event['pubkey'] as String);
    }
  }

  String get displayNameOrName => displayName ?? name ?? 'Unnamed';
}