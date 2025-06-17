import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';

class NostrService {
  static const String relayUrl = 'wss://relay.yestr.social';
  WebSocketChannel? _channel;
  final _profilesController = StreamController<NostrProfile>.broadcast();
  final List<NostrProfile> _profiles = [];
  String? _subscriptionId;

  Stream<NostrProfile> get profilesStream => _profilesController.stream;
  List<NostrProfile> get profiles => List.unmodifiable(_profiles);

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

  Future<List<NostrEvent>> getUserNotes(String pubkey, {int limit = 10}) async {
    final completer = Completer<List<NostrEvent>>();
    final notes = <NostrEvent>[];
    final subscriptionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create a new WebSocket connection for this request
    final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
    
    StreamSubscription? subscription;
    Timer? timeout;
    
    void cleanup() {
      subscription?.cancel();
      timeout?.cancel();
      final closeRequest = ["CLOSE", subscriptionId];
      channel.sink.add(jsonEncode(closeRequest));
      channel.sink.close();
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
                  final event = NostrEvent.fromJson(eventData);
                  notes.add(event);
                }
              }
              break;
            case 'EOSE':
              if (data[1] == subscriptionId) {
                cleanup();
                notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                completer.complete(notes.take(limit).toList());
              }
              break;
          }
        } catch (e) {
          print('Error handling user notes message: $e');
        }
      },
      onError: (error) {
        cleanup();
        completer.completeError(error);
      },
    );
    
    // Set timeout
    timeout = Timer(const Duration(seconds: 5), () {
      cleanup();
      if (!completer.isCompleted) {
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        completer.complete(notes.take(limit).toList());
      }
    });
    
    // Request notes from the user
    final request = [
      "REQ",
      subscriptionId,
      {
        "kinds": [1],
        "authors": [pubkey],
        "limit": limit * 2, // Request more to ensure we get enough
      }
    ];
    
    channel.sink.add(jsonEncode(request));
    
    return completer.future;
  }
}