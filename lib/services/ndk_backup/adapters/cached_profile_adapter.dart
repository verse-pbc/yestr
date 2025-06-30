import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:logger/logger.dart' as logger;
import 'package:isar/isar.dart';
import '../../../models/nostr_profile.dart';
import '../../../models/database/cached_profile.dart';
import '../ndk_service.dart';
import '../../database/isar_database_service.dart';
import 'profile_adapter.dart';

/// Profile adapter with integrated caching for better performance
class CachedProfileAdapter extends ProfileAdapter {
  final IsarDatabaseService _database;
  final logger.Logger _logger = logger.Logger();
  
  CachedProfileAdapter(NdkService ndkService, this._database) : super(ndkService);
  
  /// Fetch profile with cache-first approach
  @override
  Future<NostrProfile?> fetchProfile(String pubkey) async {
    try {
      // Check cache first
      final cached = await _database.getCachedProfile(pubkey);
      
      // Return cached if fresh
      if (cached != null) {
        final cachedData = await _database.isar.cachedProfiles
            .where()
            .pubkeyEqualTo(pubkey)
            .findFirst();
        
        if (cachedData != null && !cachedData.isStale) {
          _logger.d('Returning cached profile for $pubkey');
          return cached;
        }
      }
      
      // Fetch from network
      _logger.d('Fetching fresh profile for $pubkey');
      final profile = await super.fetchProfile(pubkey);
      
      // Cache the result
      if (profile != null) {
        await _database.cacheProfile(profile);
      }
      
      return profile;
    } catch (e) {
      _logger.e('Error fetching profile with cache', error: e);
      
      // On error, return cached version if available
      return await _database.getCachedProfile(pubkey);
    }
  }
  
  /// Fetch multiple profiles with cache optimization
  @override
  Future<List<NostrProfile>> fetchProfiles(List<String> pubkeys) async {
    try {
      // Get all cached profiles
      final cachedProfiles = await _database.getCachedProfiles(pubkeys);
      final cachedMap = {for (var p in cachedProfiles) p.pubkey: p};
      
      // Identify which profiles need fresh data
      final needsFetch = <String>[];
      final results = <NostrProfile>[];
      
      for (final pubkey in pubkeys) {
        final cached = cachedMap[pubkey];
        if (cached != null) {
          final cachedData = await _database.isar.cachedProfiles
              .where()
              .pubkeyEqualTo(pubkey)
              .findFirst();
          
          if (cachedData != null && !cachedData.isStale) {
            results.add(cached);
          } else {
            needsFetch.add(pubkey);
          }
        } else {
          needsFetch.add(pubkey);
        }
      }
      
      // Fetch missing/stale profiles
      if (needsFetch.isNotEmpty) {
        _logger.d('Fetching ${needsFetch.length} profiles from network');
        final freshProfiles = await super.fetchProfiles(needsFetch);
        
        // Cache fresh profiles
        if (freshProfiles.isNotEmpty) {
          await _database.cacheProfiles(freshProfiles);
        }
        
        results.addAll(freshProfiles);
      }
      
      return results;
    } catch (e) {
      _logger.e('Error fetching profiles with cache', error: e);
      
      // On error, return all cached versions
      return await _database.getCachedProfiles(pubkeys);
    }
  }
  
  /// Prefetch and cache profiles for better performance
  Future<void> prefetchProfiles(List<String> pubkeys) async {
    try {
      // Check which profiles are not cached or stale
      final needsFetch = <String>[];
      
      for (final pubkey in pubkeys) {
        final cachedData = await _database.isar.cachedProfiles
            .where()
            .pubkeyEqualTo(pubkey)
            .findFirst();
        
        if (cachedData == null || cachedData.isStale) {
          needsFetch.add(pubkey);
        }
      }
      
      if (needsFetch.isEmpty) return;
      
      // Batch fetch in chunks to avoid overwhelming relays
      const chunkSize = 50;
      for (var i = 0; i < needsFetch.length; i += chunkSize) {
        final chunk = needsFetch.skip(i).take(chunkSize).toList();
        final profiles = await super.fetchProfiles(chunk);
        
        if (profiles.isNotEmpty) {
          await _database.cacheProfiles(profiles);
        }
        
        // Small delay between chunks
        if (i + chunkSize < needsFetch.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      _logger.i('Prefetched ${needsFetch.length} profiles');
    } catch (e) {
      _logger.e('Error prefetching profiles', error: e);
    }
  }
  
  /// Handle failed profile images
  Future<void> markImageAsFailed(String pubkey, String imageUrl) async {
    await _database.markImageAsFailed(pubkey, imageUrl);
  }
  
  /// Check if image has failed before
  Future<bool> hasImageFailed(String pubkey, String imageUrl) async {
    return await _database.hasImageFailed(pubkey, imageUrl);
  }
}