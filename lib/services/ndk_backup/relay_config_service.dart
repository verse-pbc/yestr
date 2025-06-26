import 'package:ndk/ndk.dart';
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
  List<Relay> getConnectedRelays() {
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
      await ndk.relays.addRelay(url);
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
      await ndk.relays.removeRelay(url);
      return true;
    } catch (e) {
      print('Error removing relay: $e');
      return false;
    }
  }
  
  /// Get relay information (NIP-11)
  Future<RelayInfo?> getRelayInfo(String url) async {
    try {
      final ndk = _ndkService.ndk;
      final relay = ndk.relays.getRelay(url);
      if (relay == null) return null;
      
      return await relay.getRelayInformation();
    } catch (e) {
      print('Error getting relay info: $e');
      return null;
    }
  }
  
  /// Create a relay set for specific use case
  RelaySet createRelaySet(String purpose) {
    final relayUrls = specializedRelays[purpose] ?? defaultRelays;
    return RelaySet.fromRelayUrls(relayUrls);
  }
  
  /// Get relay statistics
  Map<String, RelayStats> getRelayStats() {
    try {
      final ndk = _ndkService.ndk;
      final stats = <String, RelayStats>{};
      
      for (final relay in ndk.relays.relays) {
        if (relay.stats != null) {
          stats[relay.url] = relay.stats!;
        }
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
      await ndk.relays.reconnectRelays();
    } catch (e) {
      print('Error optimizing relays: $e');
    }
  }
  
  /// Get user's relay list (NIP-65)
  Future<UserRelayList?> getUserRelayList(String pubkey) async {
    try {
      final ndk = _ndkService.ndk;
      return await ndk.userRelayLists.getCached(pubkey);
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
      
      // Create relay list items
      final items = <RelayListItem>[];
      
      // Add read relays
      for (final url in readRelays) {
        items.add(RelayListItem(
          url: url,
          marker: ReadWriteMarker.read,
        ));
      }
      
      // Add write relays
      for (final url in writeRelays) {
        items.add(RelayListItem(
          url: url,
          marker: ReadWriteMarker.write,
        ));
      }
      
      // Broadcast the relay list
      await ndk.userRelayLists.broadcastUserRelayList(
        UserRelayList(
          relays: items,
          pubkey: ndk.accounts.currentAccount!.pubkey,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
      
      return true;
    } catch (e) {
      print('Error updating user relay list: $e');
      return false;
    }
  }
  
  /// Monitor relay connectivity
  Stream<RelayConnectivity> monitorConnectivity() {
    try {
      final ndk = _ndkService.ndk;
      return ndk.relays.connectivityStream;
    } catch (e) {
      print('Error monitoring connectivity: $e');
      return const Stream.empty();
    }
  }
}