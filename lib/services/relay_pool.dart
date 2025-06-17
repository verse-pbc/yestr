import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages connections to multiple Nostr relays
class RelayPool {
  // Popular Nostr relays
  static const List<String> defaultRelays = [
    'wss://relay.yestr.social',
    'wss://relay.damus.io',
    'wss://relay.primal.net',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://relay.snort.social',
    'wss://nostr.wine',
  ];
  
  final Map<String, RelayConnection> _connections = {};
  final _eventController = StreamController<RelayEvent>.broadcast();
  
  Stream<RelayEvent> get eventStream => _eventController.stream;
  
  /// Connect to all default relays
  Future<void> connectToDefaultRelays() async {
    await connectToRelays(defaultRelays);
  }
  
  /// Connect to specific relays
  Future<void> connectToRelays(List<String> relayUrls) async {
    final futures = <Future<void>>[];
    
    for (final url in relayUrls) {
      futures.add(_connectToRelay(url));
    }
    
    await Future.wait(futures, eagerError: false);
  }
  
  /// Connect to a single relay
  Future<void> _connectToRelay(String relayUrl) async {
    try {
      // Skip if already connected
      if (_connections.containsKey(relayUrl)) {
        return;
      }
      
      final connection = RelayConnection(
        url: relayUrl,
        onEvent: (event) => _eventController.add(event),
      );
      
      await connection.connect();
      _connections[relayUrl] = connection;
      
      if (kDebugMode) {
        print('Connected to relay: $relayUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect to relay $relayUrl: $e');
      }
    }
  }
  
  /// Publish an event to all connected relays
  Future<Map<String, bool>> publishEvent(Map<String, dynamic> event) async {
    final results = <String, bool>{};
    
    for (final entry in _connections.entries) {
      try {
        await entry.value.publishEvent(event);
        results[entry.key] = true;
      } catch (e) {
        results[entry.key] = false;
        if (kDebugMode) {
          print('Failed to publish to ${entry.key}: $e');
        }
      }
    }
    
    return results;
  }
  
  /// Subscribe to events with a filter on all relays
  String subscribeToFilter(Map<String, dynamic> filter) {
    final subscriptionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    for (final connection in _connections.values) {
      connection.subscribe(subscriptionId, filter);
    }
    
    return subscriptionId;
  }
  
  /// Unsubscribe from a subscription
  void unsubscribe(String subscriptionId) {
    for (final connection in _connections.values) {
      connection.unsubscribe(subscriptionId);
    }
  }
  
  /// Disconnect from all relays
  void disconnectAll() {
    for (final connection in _connections.values) {
      connection.disconnect();
    }
    _connections.clear();
    _eventController.close();
  }
  
  /// Get connected relay URLs
  List<String> get connectedRelays => _connections.keys.toList();
  
  /// Check if connected to any relay
  bool get isConnected => _connections.isNotEmpty;
}

/// Represents a single relay connection
class RelayConnection {
  final String url;
  final Function(RelayEvent) onEvent;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  RelayConnection({
    required this.url,
    required this.onEvent,
  });
  
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: (error) {
        if (kDebugMode) {
          print('WebSocket error on $url: $error');
        }
      },
      onDone: () {
        if (kDebugMode) {
          print('WebSocket closed on $url');
        }
      },
    );
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as List<dynamic>;
      
      if (data.length < 2) return;
      
      final type = data[0] as String;
      
      switch (type) {
        case 'EVENT':
          if (data.length >= 3) {
            onEvent(RelayEvent(
              relayUrl: url,
              subscriptionId: data[1] as String,
              event: data[2] as Map<String, dynamic>,
            ));
          }
          break;
        case 'EOSE':
          onEvent(RelayEvent(
            relayUrl: url,
            subscriptionId: data[1] as String,
            event: null,
            isEndOfStream: true,
          ));
          break;
        case 'OK':
          if (data.length >= 3) {
            final eventId = data[1] as String;
            final success = data[2] as bool;
            final message = data.length > 3 ? data[3] as String? : null;
            if (kDebugMode) {
              print('Relay $url: Event $eventId ${success ? "accepted" : "rejected"} - $message');
            }
          }
          break;
        case 'NOTICE':
          if (kDebugMode) {
            print('Relay $url notice: ${data[1]}');
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message from $url: $e');
      }
    }
  }
  
  Future<void> publishEvent(Map<String, dynamic> event) async {
    if (_channel == null) {
      throw Exception('Not connected to relay $url');
    }
    
    final message = ['EVENT', event];
    _channel!.sink.add(jsonEncode(message));
  }
  
  void subscribe(String subscriptionId, Map<String, dynamic> filter) {
    if (_channel == null) {
      throw Exception('Not connected to relay $url');
    }
    
    final message = ['REQ', subscriptionId, filter];
    _channel!.sink.add(jsonEncode(message));
  }
  
  void unsubscribe(String subscriptionId) {
    if (_channel == null) return;
    
    final message = ['CLOSE', subscriptionId];
    _channel!.sink.add(jsonEncode(message));
  }
  
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
  }
}

/// Event received from a relay
class RelayEvent {
  final String relayUrl;
  final String subscriptionId;
  final Map<String, dynamic>? event;
  final bool isEndOfStream;
  
  RelayEvent({
    required this.relayUrl,
    required this.subscriptionId,
    this.event,
    this.isEndOfStream = false,
  });
}