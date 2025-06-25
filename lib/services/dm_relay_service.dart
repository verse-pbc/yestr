import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Optimized relay service specifically for Direct Messages
/// Uses fewer, more reliable relays for faster DM loading
class DmRelayService {
  static const List<String> priorityRelays = [
    'wss://relay.damus.io',     // Fast and reliable
    'wss://nos.lol',            // Good for DMs
    'wss://relay.primal.net',   // Primal's relay
  ];
  
  static const List<String> fallbackRelays = [
    'wss://relay.nostr.band',
    'wss://relay.yestr.social',
  ];
  
  final List<WebSocketChannel> _channels = [];
  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;
  bool get isConnected => _channels.isNotEmpty;
  
  /// Connect to priority relays first for faster DM loading
  Future<void> connectForDMs() async {
    // First connect to priority relays
    await _connectToRelays(priorityRelays);
    
    // If we have at least 2 connections, that's enough for DMs
    if (_channels.length >= 2) {
      print('[DM Relay Service] Connected to ${_channels.length} priority relays');
      return;
    }
    
    // Otherwise, try fallback relays
    await _connectToRelays(fallbackRelays);
    print('[DM Relay Service] Total connections: ${_channels.length}');
  }
  
  Future<void> _connectToRelays(List<String> relayUrls) async {
    final futures = <Future>[];
    
    for (final url in relayUrls) {
      futures.add(_connectToRelay(url));
    }
    
    // Wait for all connections to complete or timeout
    await Future.wait(
      futures,
      eagerError: false, // Don't fail if one relay fails
    ).timeout(
      const Duration(seconds: 2), // Quick timeout for each batch
      onTimeout: () {
        print('[DM Relay Service] Connection timeout reached');
      },
    );
  }
  
  Future<void> _connectToRelay(String url) async {
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(url),
      );
      
      // Test the connection with a timeout
      await channel.ready.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      _channels.add(channel);
      print('[DM Relay Service] Connected to $url');
      
      // Set up event listener
      channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as List<dynamic>;
            if (data.length >= 3 && data[0] == 'EVENT') {
              final eventData = data[2] as Map<String, dynamic>;
              _eventsController.add(eventData);
            }
          } catch (e) {
            print('[DM Relay Service] Error processing message: $e');
          }
        },
        onError: (error) {
          print('[DM Relay Service] Stream error: $error');
        },
        onDone: () {
          _channels.remove(channel);
        },
      );
    } catch (e) {
      print('[DM Relay Service] Failed to connect to $url: $e');
    }
  }
  
  /// Subscribe to a filter on all connected relays
  String subscribeToFilter(Map<String, dynamic> filter) {
    final subscriptionId = 'dm_${DateTime.now().millisecondsSinceEpoch}';
    final request = ['REQ', subscriptionId, filter];
    final message = jsonEncode(request);
    
    for (final channel in _channels) {
      try {
        channel.sink.add(message);
      } catch (e) {
        print('[DM Relay Service] Error sending subscription: $e');
      }
    }
    
    return subscriptionId;
  }
  
  /// Close a subscription
  void closeSubscription(String subscriptionId) {
    final request = ['CLOSE', subscriptionId];
    final message = jsonEncode(request);
    
    for (final channel in _channels) {
      try {
        channel.sink.add(message);
      } catch (e) {
        print('[DM Relay Service] Error closing subscription: $e');
      }
    }
  }
  
  /// Send an event to all connected relays
  void sendEvent(Map<String, dynamic> event) {
    final request = ['EVENT', event];
    final message = jsonEncode(request);
    
    for (final channel in _channels) {
      try {
        channel.sink.add(message);
      } catch (e) {
        print('[DM Relay Service] Error sending event: $e');
      }
    }
  }
  
  void disconnect() {
    for (final channel in _channels) {
      channel.sink.close();
    }
    _channels.clear();
  }
  
  void dispose() {
    disconnect();
    _eventsController.close();
  }
}