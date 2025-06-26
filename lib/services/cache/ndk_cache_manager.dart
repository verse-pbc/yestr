import 'package:ndk/ndk.dart';
import '../database/isar_database_service.dart';
import '../../models/nostr_profile.dart';
import '../../models/database/cached_message.dart';
import 'package:logger/logger.dart';

/// Custom cache manager for NDK that uses Isar database
class NdkCacheManager implements CacheManager {
  final IsarDatabaseService _database;
  final Logger _logger = Logger();
  
  NdkCacheManager(this._database);
  
  @override
  Future<void> saveEvent(Nip01Event event) async {
    try {
      // Handle different event kinds
      switch (event.kind) {
        case Metadata.KIND: // Kind 0 - Profile metadata
          await _saveProfileFromEvent(event);
          break;
        case 4: // Kind 4 - Encrypted DM
          await _saveMessageFromEvent(event);
          break;
        default:
          // For now, we only cache profiles and messages
          break;
      }
    } catch (e) {
      _logger.e('Error saving event to cache', error: e);
    }
  }
  
  @override
  Future<Nip01Event?> loadEvent(String id) async {
    // For now, return null as we don't store raw events
    // In the future, we could store raw events if needed
    return null;
  }
  
  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    String? search,
    int? since,
    int? until,
    int? limit,
  }) async {
    // For now, return empty list
    // In the future, we could implement event querying from cache
    return [];
  }
  
  @override
  Future<void> removeEvent(String id) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllEvents() async {
    await _database.clearAllCache();
  }
  
  // Helper methods
  
  Future<void> _saveProfileFromEvent(Nip01Event event) async {
    try {
      final metadata = Metadata.fromEvent(event);
      if (metadata == null) return;
      
      final profile = NostrProfile(
        pubkey: event.pubkey,
        name: metadata.name,
        displayName: metadata.displayName,
        picture: metadata.picture,
        banner: metadata.banner,
        about: metadata.about,
        nip05: metadata.nip05,
        lud16: metadata.lud16,
        website: metadata.website,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
      
      await _database.cacheProfile(profile);
    } catch (e) {
      _logger.e('Error saving profile from event', error: e);
    }
  }
  
  Future<void> _saveMessageFromEvent(Nip01Event event) async {
    try {
      // Extract receiver from tags
      final pTags = event.tags.where((tag) => tag[0] == 'p').toList();
      if (pTags.isEmpty) return;
      
      final receiverPubkey = pTags.first[1];
      
      await _database.cacheMessage(
        eventId: event.id,
        senderPubkey: event.pubkey,
        receiverPubkey: receiverPubkey,
        encryptedContent: event.content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
    } catch (e) {
      _logger.e('Error saving message from event', error: e);
    }
  }
}