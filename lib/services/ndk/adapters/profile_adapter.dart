import 'dart:async';
import 'package:ndk/ndk.dart';
import '../../../models/nostr_profile.dart';
import '../ndk_service.dart';

/// Adapter to convert between NDK metadata and our NostrProfile model
class ProfileAdapter {
  final NdkService _ndkService;
  
  ProfileAdapter(this._ndkService);
  
  /// Convert NDK Metadata to NostrProfile
  NostrProfile metadataToProfile(Metadata metadata, {required String pubkey}) {
    return NostrProfile(
      id: pubkey,
      name: metadata.name ?? '',
      displayName: metadata.displayName,
      picture: metadata.picture,
      banner: metadata.banner,
      about: metadata.about,
      nip05: metadata.nip05,
      lud16: metadata.lud16,
      website: metadata.website,
      // Extract custom fields if any
      bio: metadata.about,
      location: _extractCustomField(metadata, 'location'),
      age: _extractCustomField(metadata, 'age'),
      occupation: _extractCustomField(metadata, 'occupation'),
      interests: _extractInterests(metadata),
      pronouns: _extractCustomField(metadata, 'pronouns'),
      relationshipStatus: _extractCustomField(metadata, 'relationship_status'),
      height: _extractCustomField(metadata, 'height'),
      education: _extractCustomField(metadata, 'education'),
      instagram: _extractCustomField(metadata, 'instagram'),
      twitter: _extractCustomField(metadata, 'twitter'),
      createdAt: DateTime.now(), // Will be updated when we fetch the actual event
    );
  }
  
  /// Convert NostrProfile to NDK Metadata
  Metadata profileToMetadata(NostrProfile profile) {
    final customFields = <String, dynamic>{};
    
    // Add custom fields if present
    if (profile.location != null) customFields['location'] = profile.location;
    if (profile.age != null) customFields['age'] = profile.age;
    if (profile.occupation != null) customFields['occupation'] = profile.occupation;
    if (profile.interests.isNotEmpty) customFields['interests'] = profile.interests.join(',');
    if (profile.pronouns != null) customFields['pronouns'] = profile.pronouns;
    if (profile.relationshipStatus != null) customFields['relationship_status'] = profile.relationshipStatus;
    if (profile.height != null) customFields['height'] = profile.height;
    if (profile.education != null) customFields['education'] = profile.education;
    if (profile.instagram != null) customFields['instagram'] = profile.instagram;
    if (profile.twitter != null) customFields['twitter'] = profile.twitter;
    
    return Metadata(
      name: profile.name,
      displayName: profile.displayName,
      picture: profile.picture,
      banner: profile.banner,
      about: profile.about ?? profile.bio,
      nip05: profile.nip05,
      lud16: profile.lud16,
      website: profile.website,
      customFields: customFields.isNotEmpty ? customFields : null,
    );
  }
  
  /// Fetch profile by public key
  Future<NostrProfile?> fetchProfile(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      final metadata = await ndk.metadatas.loadMetadata(pubkey);
      
      if (metadata == null) return null;
      
      final profile = metadataToProfile(metadata, pubkey: pubkey);
      
      // Get the actual metadata event to extract createdAt
      final events = await ndk.requests.query(
        filters: [
          Filter(
            authors: [pubkey],
            kinds: [Metadata.KIND],
            limit: 1,
          ),
        ],
      ).stream.toList();
      
      if (events.isNotEmpty) {
        final event = events.first;
        return profile.copyWith(
          createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        );
      }
      
      return profile;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
  
  /// Fetch multiple profiles
  Future<List<NostrProfile>> fetchProfiles(List<String> pubkeys) async {
    try {
      final ndk = _ndkService.ndk;
      final profiles = <NostrProfile>[];
      
      // Use NDK's batch metadata loading
      final metadataMap = await ndk.metadatas.loadMetadatas(pubkeys);
      
      for (final entry in metadataMap.entries) {
        final metadata = entry.value;
        if (metadata != null) {
          profiles.add(metadataToProfile(metadata, pubkey: entry.key));
        }
      }
      
      return profiles;
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }
  
  /// Update user's own profile
  Future<bool> updateProfile(NostrProfile profile) async {
    try {
      final ndk = _ndkService.ndk;
      final metadata = profileToMetadata(profile);
      
      await ndk.metadatas.broadcastMetadata(metadata);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  // Helper methods
  String? _extractCustomField(Metadata metadata, String field) {
    if (metadata.customFields == null) return null;
    final value = metadata.customFields![field];
    return value?.toString();
  }
  
  List<String> _extractInterests(Metadata metadata) {
    if (metadata.customFields == null) return [];
    final interests = metadata.customFields!['interests'];
    if (interests == null) return [];
    if (interests is String) {
      return interests.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (interests is List) {
      return interests.map((e) => e.toString()).toList();
    }
    return [];
  }
}