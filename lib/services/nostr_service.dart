import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dart_nostr/dart_nostr.dart' as nostr;
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart' as local;

class NostrService {
  static const String relayUrl = 'wss://relay.yestr.social';
  WebSocketChannel? _channel;
  final _profilesController = StreamController<NostrProfile>.broadcast();
  final List<NostrProfile> _profiles = [];
  String? _subscriptionId;

  Stream<NostrProfile> get profilesStream => _profilesController.stream;
  List<NostrProfile> get profiles => List.unmodifiable(_profiles);
  bool get isConnected => _channel != null;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      print('Connected to relay: $relayUrl');
      
      // Listen to messages from relay
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );

      // Request profiles
      await _requestProfiles();
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }

  Future<void> _requestProfiles() async {
    _subscriptionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create a REQ message for kind 0 (profile) events
    final request = [
      "REQ",
      _subscriptionId,
      {
        "kinds": [0],
        "limit": 100,
      }
    ];

    final requestJson = jsonEncode(request);
    _channel?.sink.add(requestJson);
    print('Sent profile request: $requestJson');
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as List<dynamic>;
      
      if (data.length < 2) return;

      final type = data[0] as String;
      
      switch (type) {
        case 'EVENT':
          if (data.length >= 3) {
            final eventData = data[2] as Map<String, dynamic>;
            _handleEvent(eventData);
          }
          break;
        case 'EOSE':
          print('End of stored events for subscription: ${data[1]}');
          break;
        case 'NOTICE':
          print('Relay notice: ${data[1]}');
          break;
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _handleEvent(Map<String, dynamic> eventData) {
    try {
      if (eventData['kind'] == 0) {
        final profile = NostrProfile.fromNostrEvent(eventData);
        
        // Only add profiles with at least a name and picture
        if (profile.picture != null && 
            (profile.name != null || profile.displayName != null)) {
          _profiles.add(profile);
          _profilesController.add(profile);
          print('Added profile: ${profile.displayNameOrName}');
          
          // Stop after getting 10 good profiles
          if (_profiles.length >= 10) {
            closeSubscription();
          }
        }
      }
    } catch (e) {
      print('Error handling event: $e');
    }
  }

  void closeSubscription() {
    if (_subscriptionId != null) {
      final closeRequest = ["CLOSE", _subscriptionId];
      _channel?.sink.add(jsonEncode(closeRequest));
      print('Closed subscription: $_subscriptionId');
    }
  }

  void disconnect() {
    closeSubscription();
    _channel?.sink.close();
    _profilesController.close();
    _profiles.clear();
  }

  /// Publish an event to the connected relay
  void publishEvent(Map<String, dynamic> eventData) {
    if (_channel == null) {
      throw Exception('Not connected to relay');
    }

    try {
      // Create EVENT message
      final message = [
        "EVENT",
        eventData,
      ];

      final messageJson = jsonEncode(message);
      _channel!.sink.add(messageJson);
      
      print('Published event: ${eventData['id']}');
      print('Event kind: ${eventData['kind']}');
    } catch (e) {
      print('Error publishing event: $e');
      throw e;
    }
  }

  /// Subscribe to events matching a filter - simplified version
  Stream<Map<String, dynamic>> subscribeToSimpleFilter(Map<String, dynamic> filter) {
    if (_channel == null) {
      throw Exception('Not connected to relay');
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final subscriptionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Listen for events
    StreamSubscription? subscription;
    subscription = _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message as String) as List<dynamic>;
          
          if (data.length < 2) return;
          
          final type = data[0] as String;
          
          if (type == 'EVENT' && data[1] == subscriptionId && data.length >= 3) {
            final eventData = data[2] as Map<String, dynamic>;
            controller.add(eventData);
          } else if (type == 'EOSE' && data[1] == subscriptionId) {
            // End of stored events
            controller.close();
            subscription?.cancel();
          }
        } catch (e) {
          print('Error in subscription: $e');
        }
      },
      onError: (error) {
        controller.addError(error);
        controller.close();
      },
      onDone: () {
        controller.close();
      },
    );

    // Send subscription request
    final request = [
      "REQ",
      subscriptionId,
      filter,
    ];
    
    _channel!.sink.add(jsonEncode(request));
    
    // Cleanup on stream cancellation
    controller.onCancel = () {
      final closeRequest = ["CLOSE", subscriptionId];
      _channel?.sink.add(jsonEncode(closeRequest));
      subscription?.cancel();
    };

    return controller.stream;
  }

  Future<List<local.NostrEvent>> getUserNotes(String pubkey, {int limit = 10}) async {
    print('getUserNotes called for pubkey: $pubkey, limit: $limit');
    
    // Use multiple popular relays to ensure we get notes
    final relays = [
      'wss://relay.damus.io',
      'wss://relay.primal.net',
      'wss://nos.lol',
      'wss://relay.nostr.band',
      relayUrl, // Also include yestr relay
    ];
    
    final allNotes = <String, local.NostrEvent>{};
    final futures = <Future<void>>[];
    
    for (final relay in relays) {
      futures.add(_fetchNotesFromRelay(relay, pubkey, limit * 2, allNotes));
    }
    
    // Wait for all relays to respond or timeout
    await Future.wait(futures, eagerError: false);
    
    // Sort notes by creation time (newest first)
    final sortedNotes = allNotes.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    print('Total unique notes found: ${sortedNotes.length}');
    
    // Return requested limit
    return sortedNotes.take(limit).toList();
  }
  
  Future<void> _fetchNotesFromRelay(
    String relayUrl,
    String pubkey,
    int limit,
    Map<String, local.NostrEvent> allNotes,
  ) async {
    try {
      print('Fetching notes from relay: $relayUrl');
      
      final completer = Completer<void>();
      final subscriptionId = '${DateTime.now().millisecondsSinceEpoch}_${relayUrl.hashCode}';
      
      // Create a new WebSocket connection for this relay
      final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      
      StreamSubscription? subscription;
      Timer? timeout;
      int notesFromThisRelay = 0;
      
      void cleanup() {
        subscription?.cancel();
        timeout?.cancel();
        try {
          final closeRequest = ["CLOSE", subscriptionId];
          channel.sink.add(jsonEncode(closeRequest));
          channel.sink.close();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      
      subscription = channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as List<dynamic>;
            
            if (data.length < 2) return;
            
            final type = data[0] as String;
            
            switch (type) {
              case 'EVENT':
                if (data.length >= 3) {
                  final eventData = data[2] as Map<String, dynamic>;
                  if (eventData['kind'] == 1) {
                    final event = local.NostrEvent.fromJson(eventData);
                    allNotes[event.id] = event;
                    notesFromThisRelay++;
                  }
                }
                break;
              case 'EOSE':
                if (data[1] == subscriptionId) {
                  print('Relay $relayUrl: Got $notesFromThisRelay notes');
                  cleanup();
                  if (!completer.isCompleted) {
                    completer.complete();
                  }
                }
                break;
              case 'NOTICE':
                print('Relay $relayUrl notice: ${data[1]}');
                break;
            }
          } catch (e) {
            print('Error handling message from $relayUrl: $e');
          }
        },
        onError: (error) {
          print('WebSocket error from $relayUrl: $error');
          cleanup();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () {
          cleanup();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      
      // Set timeout for this relay
      timeout = Timer(const Duration(seconds: 3), () {
        print('Timeout for relay: $relayUrl');
        cleanup();
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      // Request notes from the user
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [1],
          "authors": [pubkey],
          "limit": limit,
        }
      ];
      
      final requestJson = jsonEncode(request);
      channel.sink.add(requestJson);
      print('Sent request to $relayUrl: $requestJson');
      
      await completer.future;
    } catch (e) {
      print('Error connecting to relay $relayUrl: $e');
    }
  }
}