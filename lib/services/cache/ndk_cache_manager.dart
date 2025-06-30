import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart' show UserRelayList, Nip05;
import '../database/isar_database_service.dart';
import '../../models/nostr_profile.dart';
import '../../models/database/cached_message.dart';
import 'package:logger/logger.dart' as logger;

/// Custom cache manager for NDK that uses Isar database
class NdkCacheManager implements CacheManager {
  final IsarDatabaseService _database;
  final logger.Logger _logger = logger.Logger();
  
  NdkCacheManager(this._database);
  
  @override
  Future<void> saveEvent(Nip01Event event) async {
    try {
      // Handle different event kinds
      switch (event.kind) {
        case Metadata.kKind: // Kind 0 - Profile metadata
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
    List<String> pubKeys = const [],
    List<int> kinds = const [],
    String? pTag,
    int? since,
    int? until,
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
  
  @override
  Future<void> close() async {
    // Database cleanup if needed
  }
  
  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    for (final event in events) {
      await saveEvent(event);
    }
  }
  
  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) async {
    // Implement if needed
  }
  
  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) async {
    // Implement if needed
  }
  
  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) async {
    return null;
  }
  
  @override
  Future<void> removeUserRelayList(String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllUserRelayLists() async {
    // Implement if needed
  }
  
  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) async {
    return null;
  }
  
  @override
  Future<void> saveRelaySet(RelaySet relaySet) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeRelaySet(String name, String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllRelaySets() async {
    // Implement if needed
  }
  
  @override
  Future<void> saveContactList(ContactList contactList) async {
    // Implement if needed
  }
  
  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    // Implement if needed
  }
  
  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    return null;
  }
  
  @override
  Future<void> removeContactList(String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllContactLists() async {
    // Implement if needed
  }
  
  @override
  Future<void> saveMetadata(Metadata metadata) async {
    // Convert to event and save
    final profile = NostrProfile(
      pubkey: metadata.pubKey,
      name: metadata.name,
      displayName: metadata.displayName,
      picture: metadata.picture,
      banner: metadata.banner,
      about: metadata.about,
      nip05: metadata.nip05,
      lud16: metadata.lud16,
      website: metadata.website,
      createdAt: DateTime.now(),
    );
    await _database.cacheProfile(profile);
  }
  
  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }
  }
  
  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    final profile = await _database.getCachedProfile(pubKey);
    if (profile == null) return null;
    
    return Metadata(
      pubKey: profile.pubkey,
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
  
  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    final results = <Metadata?>[];
    for (final pubKey in pubKeys) {
      results.add(await loadMetadata(pubKey));
    }
    return results;
  }
  
  @override
  Future<void> removeMetadata(String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllMetadatas() async {
    // Implement if needed
  }
  
  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) async {
    // Implement if needed
    return [];
  }
  
  @override
  Future<Iterable<Nip01Event>> searchEvents({
    List<String>? ids,
    List<String>? authors,
    List<int>? kinds,
    Map<String, List<String>>? tags,
    int? since,
    int? until,
    String? search,
    int limit = 100,
  }) async {
    // Implement if needed
    return [];
  }
  
  @override
  Future<void> saveNip05(Nip05 nip05) async {
    // Implement if needed
  }
  
  @override
  Future<void> saveNip05s(List<Nip05> nip05s) async {
    // Implement if needed
  }
  
  @override
  Future<Nip05?> loadNip05(String pubKey) async {
    return null;
  }
  
  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) async {
    return [];
  }
  
  @override
  Future<void> removeNip05(String pubKey) async {
    // Implement if needed
  }
  
  @override
  Future<void> removeAllNip05s() async {
    // Implement if needed
  }
  
  // Helper methods
  
  Future<void> _saveProfileFromEvent(Nip01Event event) async {
    try {
      final metadata = Metadata.fromEvent(event);
      if (metadata == null) return;
      
      final profile = NostrProfile(
        pubkey: event.pubKey,
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
        senderPubkey: event.pubKey,
        receiverPubkey: receiverPubkey,
        encryptedContent: event.content,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
    } catch (e) {
      _logger.e('Error saving message from event', error: e);
    }
  }
}