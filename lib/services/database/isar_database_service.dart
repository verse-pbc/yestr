import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../models/database/cached_profile.dart';
import '../../models/database/cached_message.dart';
import '../../models/database/cached_relay.dart';
import '../../models/nostr_profile.dart';

/// Service for managing Isar database operations
class IsarDatabaseService {
  static IsarDatabaseService? _instance;
  static Isar? _isar;
  final Logger _logger = Logger();
  
  // Singleton pattern
  static IsarDatabaseService get instance {
    _instance ??= IsarDatabaseService._internal();
    return _instance!;
  }
  
  IsarDatabaseService._internal();
  
  /// Initialize Isar database
  Future<void> initialize() async {
    if (_isar != null) return;
    
    try {
      String? dirPath;
      
      // Handle web platform where path_provider might not be available
      if (!kIsWeb) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          dirPath = dir.path;
        } catch (e) {
          _logger.w('Could not get app documents directory, using default: $e');
        }
      }
      
      _isar = await Isar.open(
        [
          CachedProfileSchema,
          CachedMessageSchema,
          CachedRelaySchema,
        ],
        directory: dirPath ?? (kIsWeb ? '' : '.'),
        name: 'yestr_cache',
        inspector: kDebugMode,
      );
      
      _logger.i('Isar database initialized successfully');
      
      // Start background cleanup task
      _startPeriodicCleanup();
    } catch (e) {
      _logger.e('Error initializing Isar database', error: e);
      rethrow;
    }
  }
  
  /// Get Isar instance
  Isar get isar {
    if (_isar == null) {
      throw StateError('Isar not initialized. Call initialize() first.');
    }
    return _isar!;
  }
  
  // Profile Operations
  
  /// Cache a profile
  Future<void> cacheProfile(NostrProfile profile) async {
    await isar.writeTxn(() async {
      final cached = CachedProfile()
        ..pubkey = profile.pubkey
        ..name = profile.name
        ..displayName = profile.displayName
        ..picture = profile.picture
        ..banner = profile.banner
        ..about = profile.about
        ..nip05 = profile.nip05
        ..lud16 = profile.lud16
        ..website = profile.website
        ..createdAt = profile.createdAt ?? DateTime.now()
        ..lastUpdated = DateTime.now();
      
      await isar.cachedProfiles.put(cached);
    });
  }
  
  /// Cache multiple profiles
  Future<void> cacheProfiles(List<NostrProfile> profiles) async {
    await isar.writeTxn(() async {
      final cached = profiles.map((profile) => CachedProfile()
        ..pubkey = profile.pubkey
        ..name = profile.name
        ..displayName = profile.displayName
        ..picture = profile.picture
        ..banner = profile.banner
        ..about = profile.about
        ..nip05 = profile.nip05
        ..lud16 = profile.lud16
        ..website = profile.website
        ..createdAt = profile.createdAt ?? DateTime.now()
        ..lastUpdated = DateTime.now()
      ).toList();
      
      await isar.cachedProfiles.putAll(cached);
    });
  }
  
  /// Get cached profile
  Future<NostrProfile?> getCachedProfile(String pubkey) async {
    final cached = await isar.cachedProfiles
        .where()
        .pubkeyEqualTo(pubkey)
        .findFirst();
    
    if (cached == null) return null;
    
    return NostrProfile(
      pubkey: cached.pubkey,
      name: cached.name,
      displayName: cached.displayName,
      picture: cached.picture,
      banner: cached.banner,
      about: cached.about,
      nip05: cached.nip05,
      lud16: cached.lud16,
      website: cached.website,
      createdAt: cached.createdAt,
    );
  }
  
  /// Get multiple cached profiles
  Future<List<NostrProfile>> getCachedProfiles(List<String> pubkeys) async {
    final cached = await isar.cachedProfiles
        .where()
        .anyOf(pubkeys, (q, pubkey) => q.pubkeyEqualTo(pubkey))
        .findAll();
    
    return cached.map((c) => NostrProfile(
      pubkey: c.pubkey,
      name: c.name,
      displayName: c.displayName,
      picture: c.picture,
      banner: c.banner,
      about: c.about,
      nip05: c.nip05,
      lud16: c.lud16,
      website: c.website,
      createdAt: c.createdAt,
    )).toList();
  }
  
  /// Mark image URL as failed
  Future<void> markImageAsFailed(String pubkey, String imageUrl) async {
    await isar.writeTxn(() async {
      final profile = await isar.cachedProfiles
          .where()
          .pubkeyEqualTo(pubkey)
          .findFirst();
      
      if (profile != null && !profile.failedImageUrls.contains(imageUrl)) {
        profile.failedImageUrls.add(imageUrl);
        await isar.cachedProfiles.put(profile);
      }
    });
  }
  
  /// Check if image URL has failed
  Future<bool> hasImageFailed(String pubkey, String imageUrl) async {
    final profile = await isar.cachedProfiles
        .where()
        .pubkeyEqualTo(pubkey)
        .findFirst();
    
    return profile?.hasFailedImageUrl(imageUrl) ?? false;
  }
  
  // Message Operations
  
  /// Cache a message
  Future<void> cacheMessage({
    required String eventId,
    required String senderPubkey,
    required String receiverPubkey,
    required String encryptedContent,
    String? decryptedContent,
    required DateTime createdAt,
    bool isRead = false,
    bool isPending = false,
    String? localId,
  }) async {
    await isar.writeTxn(() async {
      final message = CachedMessage()
        ..eventId = eventId
        ..senderPubkey = senderPubkey
        ..receiverPubkey = receiverPubkey
        ..encryptedContent = encryptedContent
        ..decryptedContent = decryptedContent
        ..createdAt = createdAt
        ..receivedAt = DateTime.now()
        ..conversationKey = CachedMessage.generateConversationKey(
          senderPubkey, 
          receiverPubkey
        )
        ..isRead = isRead
        ..isPending = isPending
        ..localId = localId;
      
      await isar.cachedMessages.put(message);
    });
  }
  
  /// Get conversation messages
  Future<List<CachedMessage>> getConversationMessages(
    String pubkey1, 
    String pubkey2,
    {int limit = 50, int offset = 0}
  ) async {
    final conversationKey = CachedMessage.generateConversationKey(pubkey1, pubkey2);
    
    return await isar.cachedMessages
        .filter()
        .conversationKeyEqualTo(conversationKey)
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }
  
  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderPubkey, String receiverPubkey) async {
    await isar.writeTxn(() async {
      final messages = await isar.cachedMessages
          .filter()
          .senderPubkeyEqualTo(senderPubkey)
          .and()
          .receiverPubkeyEqualTo(receiverPubkey)
          .and()
          .isReadEqualTo(false)
          .findAll();
      
      for (final message in messages) {
        message.isRead = true;
      }
      
      await isar.cachedMessages.putAll(messages);
    });
  }
  
  /// Get unread message count
  Future<int> getUnreadMessageCount(String userPubkey) async {
    return await isar.cachedMessages
        .where()
        .receiverPubkeyEqualTo(userPubkey)
        .filter()
        .isReadEqualTo(false)
        .count();
  }
  
  // Relay Operations
  
  /// Cache relay information
  Future<void> cacheRelay({
    required String url,
    String? name,
    String? description,
    RelayStatus status = RelayStatus.unknown,
  }) async {
    await isar.writeTxn(() async {
      final existing = await isar.cachedRelays
          .where()
          .urlEqualTo(url)
          .findFirst();
      
      final relay = existing ?? CachedRelay()
        ..url = url
        ..firstSeen = DateTime.now();
      
      relay
        ..name = name ?? relay.name
        ..description = description ?? relay.description
        ..status = status
        ..lastConnected = DateTime.now();
      
      await isar.cachedRelays.put(relay);
    });
  }
  
  /// Update relay metrics
  Future<void> updateRelayMetrics({
    required String url,
    required bool success,
    double? responseTime,
  }) async {
    await isar.writeTxn(() async {
      final relay = await isar.cachedRelays
          .where()
          .urlEqualTo(url)
          .findFirst();
      
      if (relay != null) {
        if (success) {
          relay.successfulConnections++;
          relay.status = RelayStatus.connected;
        } else {
          relay.failedConnections++;
          relay.status = RelayStatus.error;
        }
        
        if (responseTime != null) {
          // Update average response time
          final total = relay.successfulConnections + relay.failedConnections;
          relay.averageResponseTime = 
            ((relay.averageResponseTime * (total - 1)) + responseTime) / total;
        }
        
        await isar.cachedRelays.put(relay);
      }
    });
  }
  
  /// Get healthy relays sorted by reliability
  Future<List<CachedRelay>> getHealthyRelays({int limit = 10}) async {
    final relays = await isar.cachedRelays
        .filter()
        .statusEqualTo(RelayStatus.connected)
        .findAll();
    
    // Sort by reliability score
    relays.sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));
    
    return relays.take(limit).toList();
  }
  
  // Cleanup Operations
  
  /// Start periodic cleanup of old data
  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 6), (_) async {
      await cleanupOldData();
    });
  }
  
  /// Cleanup old cached data
  Future<void> cleanupOldData() async {
    try {
      await isar.writeTxn(() async {
        // Delete messages older than 30 days
        final oldMessageDate = DateTime.now().subtract(const Duration(days: 30));
        await isar.cachedMessages
            .where()
            .createdAtLessThan(oldMessageDate)
            .deleteAll();
        
        // Delete stale profiles (not updated in 7 days)
        final staleProfileDate = DateTime.now().subtract(const Duration(days: 7));
        await isar.cachedProfiles
            .where()
            .lastUpdatedLessThan(staleProfileDate)
            .deleteAll();
        
        _logger.i('Cleanup completed successfully');
      });
    } catch (e) {
      _logger.e('Error during cleanup', error: e);
    }
  }
  
  /// Clear all cached data
  Future<void> clearAllCache() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
  
  /// Close database
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
    _instance = null;
  }
}