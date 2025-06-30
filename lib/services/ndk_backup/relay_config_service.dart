import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart';
import 'ndk_service.dart';

/// Service to manage relay configuration for NDK
class RelayConfigService {
  final NdkService _ndkService;
  
  // Default relay URLs for the app
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://relay.snort.social',
    'wss://nos.lol',
    'wss://relay.nostr.bg',
    'wss://relay.primal.net',
    'wss://relay.nostr.wirednet.jp',
    'wss://nostr-pub.wellorder.net',
    'wss://relay.current.fyi',
    'wss://relay.nostrplebs.com',
  ];
  
  // Specialized relays for different purposes
  static const Map<String, List<String>> specializedRelays = {
    'profiles': [
      'wss://purplepag.es',
      'wss://relay.nostr.band',
      'wss://relay.damus.io',
    ],
    'messages': [
      'wss://relay.snort.social',
      'wss://nos.lol',
      'wss://relay.damus.io',
    ],
    'discovery': [
      'wss://relay.nostr.band',
      'wss://relay.primal.net',
      'wss://relay.current.fyi',
    ],
  };
  
  RelayConfigService(this._ndkService);
  
  /// Get connected relays
  List<RelayConnectivity> getConnectedRelays() {
    try {
      final ndk = _ndkService.ndk;
      return ndk.relays.connectedRelays;
    } catch (e) {
      print('Error getting connected relays: $e');
      return [];
    }
  }
  
  /// Add a relay to the pool
  Future<bool> addRelay(String url) async {
    try {
      final ndk = _ndkService.ndk;
      await ndk.relays.connectRelay(
        dirtyUrl: url,
        connectionSource: ConnectionSource.explicit,
      );
      return true;
    } catch (e) {
      print('Error adding relay: $e');
      return false;
    }
  }
  
  /// Remove a relay from the pool
  Future<bool> removeRelay(String url) async {
    try {
      final ndk = _ndkService.ndk;
      await ndk.relays.disconnectRelay(url);
      return true;
    } catch (e) {
      print('Error removing relay: $e');
      return false;
    }
  }
  
  /// Get relay information (NIP-11)
  Future<Map<String, dynamic>?> getRelayInfo(String url) async {
    try {
      final ndk = _ndkService.ndk;
      final relayConnectivity = ndk.relays.connectedRelays
          .firstWhere((r) => r.url == url, orElse: () => throw Exception('Relay not found'));
      
      return await relayConnectivity.relay.getRelayInformation();
    } catch (e) {
      print('Error getting relay info: $e');
      return null;
    }
  }
  
  /// Create a relay set for specific use case
  RelaySet createRelaySet(String purpose, String ownerPubKey) {
    final relayUrls = specializedRelays[purpose] ?? defaultRelays;
    
    // Create relay mappings
    final relayMap = <String, List<PubkeyMapping>>{};
    for (final url in relayUrls) {
      relayMap[url] = [
        PubkeyMapping(
          pubKey: ownerPubKey,
          rwMarker: ReadWriteMarker.readWrite,
        ),
      ];
    }
    
    return RelaySet(
      name: purpose,
      pubKey: ownerPubKey,
      relayMinCountPerPubkey: 2,
      direction: RelayDirection.outbox,
      relaysMap: relayMap,
    );
  }
  
  /// Get relay statistics
  Map<String, Map<String, dynamic>> getRelayStats() {
    try {
      final ndk = _ndkService.ndk;
      final stats = <String, Map<String, dynamic>>{};
      
      for (final relay in ndk.relays.connectedRelays) {
        stats[relay.url] = {
          'connected': relay.relayTransport?.isOpen() ?? false,
          'url': relay.url,
          'connectionSource': relay.relay.connectionSource.toString(),
        };
      }
      
      return stats;
    } catch (e) {
      print('Error getting relay stats: $e');
      return {};
    }
  }
  
  /// Connect to all default relays
  Future<void> connectToDefaultRelays() async {
    for (final url in defaultRelays) {
      await addRelay(url);
    }
  }
  
  /// Optimize relay connections based on usage
  Future<void> optimizeRelays() async {
    try {
      final ndk = _ndkService.ndk;
      
      // Let NDK's JIT engine handle optimization
      // This will disconnect unused relays and connect to better ones
      await ndk.relays.reconnectRelays(ndk.relays.connectedRelays.map((r) => r.url));
    } catch (e) {
      print('Error optimizing relays: $e');
    }
  }
  
  /// Get user's relay list (NIP-65)
  Future<UserRelayList?> getUserRelayList(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      // Load from cache first
      // For now return null - would need to implement proper cache access
      return null;
    } catch (e) {
      print('Error getting user relay list: $e');
      return null;
    }
  }
  
  /// Update user's relay list
  Future<bool> updateUserRelayList({
    required List<String> readRelays,
    required List<String> writeRelays,
  }) async {
    try {
      final ndk = _ndkService.ndk;
      
      // Create relay map
      final relayMap = <String, ReadWriteMarker>{};
      
      // Add read relays
      for (final url in readRelays) {
        relayMap[url] = ReadWriteMarker.readOnly;
      }
      
      // Add write relays
      for (final url in writeRelays) {
        // If relay is both read and write, use readWrite marker
        if (relayMap.containsKey(url)) {
          relayMap[url] = ReadWriteMarker.readWrite;
        } else {
          relayMap[url] = ReadWriteMarker.writeOnly;
        }
      }
      
      // Create and broadcast the relay list
      final userRelayList = UserRelayList(
        relays: relayMap,
        pubKey: ndk.accounts.getPublicKey()!,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        refreshedTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      await ndk.userRelayLists.setInitialUserRelayList(userRelayList);
      
      return true;
    } catch (e) {
      print('Error updating user relay list: $e');
      return false;
    }
  }
  
  /// Monitor relay connectivity
  Stream<Map<String, RelayConnectivity>> monitorConnectivity() {
    try {
      final ndk = _ndkService.ndk;
      return ndk.relays.relayConnectivityChanges;
    } catch (e) {
      print('Error monitoring connectivity: $e');
      return const Stream.empty();
    }
  }
}