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
      pubkey: pubkey,
      name: metadata.name,
      displayName: metadata.displayName,
      picture: metadata.picture,
      banner: metadata.banner,
      about: metadata.about,
      nip05: metadata.nip05,
      lud16: metadata.lud16,
      website: metadata.website,
      createdAt: DateTime.now(), // Will be updated when we fetch the actual event
    );
  }
  
  /// Convert NostrProfile to NDK Metadata
  Metadata profileToMetadata(NostrProfile profile) {
    return Metadata(
      name: profile.name,
      displayName: profile.displayName,
      picture: profile.picture,
      banner: profile.banner,
      about: profile.about,
      nip05: profile.nip05,
      lud16: profile.lud16,
      website: profile.website,
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
        // Create new profile with updated createdAt
        return NostrProfile(
          pubkey: profile.pubkey,
          name: profile.name,
          displayName: profile.displayName,
          picture: profile.picture,
          banner: profile.banner,
          about: profile.about,
          nip05: profile.nip05,
          lud16: profile.lud16,
          website: profile.website,
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
  
}