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
  final List<String>? relays; // General relays for content (from kind 10002)
  final List<String>? dmRelays; // DM-specific relays (from kind 10050)

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
    this.relays,
    this.dmRelays,
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
        relays: null, // Will be populated separately from relay events
        dmRelays: null, // Will be populated separately from relay events
      );
    } catch (e) {
      print('Error parsing profile: $e');
      return NostrProfile(pubkey: event['pubkey'] as String);
    }
  }

  String get displayNameOrName => displayName ?? name ?? 'Unnamed';
  
  NostrProfile copyWith({
    String? pubkey,
    String? name,
    String? displayName,
    String? picture,
    String? about,
    String? banner,
    String? website,
    String? nip05,
    String? lud16,
    DateTime? createdAt,
    List<String>? relays,
    List<String>? dmRelays,
  }) {
    return NostrProfile(
      pubkey: pubkey ?? this.pubkey,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      picture: picture ?? this.picture,
      about: about ?? this.about,
      banner: banner ?? this.banner,
      website: website ?? this.website,
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      createdAt: createdAt ?? this.createdAt,
      relays: relays ?? this.relays,
      dmRelays: dmRelays ?? this.dmRelays,
    );
  }
}