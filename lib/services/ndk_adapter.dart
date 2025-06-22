import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as ndk_entities;
import 'dart:convert';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart' as local;

/// Adapter class to bridge NDK functionality with existing service contracts
class NDKAdapter {
  static NDKAdapter? _instance;
  Ndk? _ndk;
  
  // Singleton pattern
  factory NDKAdapter() {
    _instance ??= NDKAdapter._internal();
    return _instance!;
  }
  
  NDKAdapter._internal();
  
  Ndk get ndk {
    if (_ndk == null) {
      throw Exception('NDK not initialized. Call initialize() first.');
    }
    return _ndk!;
  }
  
  /// Initialize NDK with default relays
  Future<void> initialize() async {
    if (_ndk != null) {
      print('NDK already initialized');
      return;
    }
    
    try {
      _ndk = Ndk(
        NdkConfig(
          cache: MemCacheManager(),
          eventVerifier: Bip340EventVerifier(),
          bootstrapRelays: [
            'wss://relay.yestr.social',
            'wss://relay.damus.io',
            'wss://relay.primal.net',
            'wss://nos.lol',
            'wss://relay.nostr.band',
            'wss://relay.snort.social',
            'wss://nostr.wine',
          ],
        ),
      );
      
      print('NDK initialized with ${_ndk!.config.bootstrapRelays.length} bootstrap relays');
    } catch (e) {
      print('Error initializing NDK: $e');
      rethrow;
    }
  }
  
  /// Convert NDK event to local NostrEvent model
  local.NostrEvent ndkEventToLocal(ndk_entities.Nip01Event ndkEvent) {
    return local.NostrEvent(
      id: ndkEvent.id,
      pubkey: ndkEvent.pubKey,
      createdAt: ndkEvent.createdAt,
      kind: ndkEvent.kind,
      tags: ndkEvent.tags,
      content: ndkEvent.content,
      sig: ndkEvent.sig,
    );
  }
  
  /// Convert NDK event to NostrProfile
  NostrProfile? ndkEventToProfile(ndk_entities.Nip01Event ndkEvent) {
    if (ndkEvent.kind != 0) return null;
    
    try {
      print('NDKAdapter: Converting event from ${ndkEvent.pubKey}');
      print('NDKAdapter: Event content: ${ndkEvent.content}');
      
      final metadata = jsonDecode(ndkEvent.content) as Map<String, dynamic>;
      final profile = NostrProfile.fromNostrEvent({
        'id': ndkEvent.id,
        'pubkey': ndkEvent.pubKey,
        'created_at': ndkEvent.createdAt,
        'kind': ndkEvent.kind,
        'tags': ndkEvent.tags,
        'content': ndkEvent.content,
        'sig': ndkEvent.sig,
      });
      
      print('NDKAdapter: Created profile: ${profile.displayNameOrName}');
      return profile;
    } catch (e) {
      print('Error converting NDK event to profile: $e');
      print('Event data: id=${ndkEvent.id}, pubKey=${ndkEvent.pubKey}, content=${ndkEvent.content}');
      return null;
    }
  }
  
  /// Clean up resources
  void dispose() {
    _ndk?.destroy();
    _ndk = null;
    _instance = null;
  }
}