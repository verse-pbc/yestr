import 'dart:async';
import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart' as dart_nostr;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'key_management_service.dart';
import 'event_signer.dart';

class NostrService {
  // Singleton instance
  static final NostrService _instance = NostrService._internal();
  factory NostrService() => _instance;
  NostrService._internal();
  
  final KeyManagementService _keyService = KeyManagementService();
  final EventSigner _eventSigner = EventSigner();
  final _profilesController = StreamController<NostrProfile>.broadcast();
  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final List<NostrProfile> _profiles = [];
  StreamSubscription? _profileSubscription;
  bool _isConnected = false;
  final List<WebSocketChannel> _channels = [];
  final List<String> _relayUrls = [
    'wss://relay.damus.io',
    'wss://relay.primal.net',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://relay.yestr.social',
  ];

  Stream<NostrProfile> get profilesStream => _profilesController.stream;
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;
  List<NostrProfile> get profiles => List.unmodifiable(_profiles);
  bool get isConnected => _isConnected;
  List<WebSocketChannel> get channels => _channels;

  Future<void> connect() async {
    if (_isConnected) {
      print('NostrService: Already connected');
      return;
    }
    
    try {
      await connectToMultipleRelays();
      _isConnected = true;
      
      // Request profiles after connection
      await _requestProfiles();
    } catch (e) {
      print('NostrService: Connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }
  
  void _setupEventListeners() {
    for (final channel in _channels) {
      channel.stream.listen((message) {
        try {
          final data = jsonDecode(message as String) as List<dynamic>;
          if (data.length >= 3 && data[0] == 'EVENT') {
            final eventData = data[2] as Map<String, dynamic>;
            _handleEvent(eventData);
          } else if (data[0] == 'EOSE') {
            // End of stored events
            print('NostrService: End of stored events for subscription ${data[1]}');
          } else if (data[0] == 'NOTICE') {
            print('NostrService: Relay notice: ${data[1]}');
          }
        } catch (e) {
          print('Error processing message: $e');
          print('Raw message: $message');
        }
      });
    }
  }
  
  void _handleEvent(Map<String, dynamic> eventData) {
    final kind = eventData['kind'] as int;
    
    // Debug: log all kind 1 events
    if (kind == 1) {
      print('NostrService: Received kind 1 event from ${eventData['pubkey']?.substring(0, 8)}...');
    }
    
    if (kind == 0) {
      // Profile metadata
      final profile = NostrProfile.fromNostrEvent(eventData);
      if (!_profiles.any((p) => p.pubkey == profile.pubkey)) {
        _profiles.add(profile);
        _profilesController.add(profile);
      }
    }
    
    // Emit all events to the events stream
    _eventsController.add(eventData);
  }

  Future<void> _requestProfiles() async {
    try {
      print('NostrService: Requesting profiles...');
      
      final subscriptionId = 'profiles_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0],
          "limit": 100,
        }
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      print('NostrService: Sent profile request to ${_channels.length} relays');
    } catch (e) {
      print('NostrService: Error requesting profiles: $e');
    }
  }

  Future<void> requestProfilesWithLimit({
    int limit = 50,
    List<String>? authors,
  }) async {
    try {
      print('NostrService: Requesting profiles with limit $limit');
      
      // Clear existing profiles
      _profiles.clear();
      
      final subscriptionId = 'profiles_limit_${DateTime.now().millisecondsSinceEpoch}';
      final filter = {
        "kinds": [0],
        "limit": limit,
      };
      
      if (authors != null && authors.isNotEmpty) {
        filter["authors"] = authors;
      }
      
      final request = [
        "REQ",
        subscriptionId,
        filter,
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      print('NostrService: Sent limited profile request to ${_channels.length} relays');
    } catch (e) {
      print('NostrService: Error requesting profiles: $e');
    }
  }

  Future<NostrProfile?> getProfile(String pubkey) async {
    try {
      // First check cache
      final cached = _profiles.firstWhere(
        (p) => p.pubkey == pubkey,
        orElse: () => NostrProfile(
          pubkey: pubkey,
          name: null,
          displayName: null,
          about: null,
          picture: null,
          banner: null,
          nip05: null,
          lud06: null,
          lud16: null,
          website: null,
        ),
      );
      
      // Return cached if valid
      if (cached.name != null || cached.displayName != null) {
        return cached;
      }
      
      // Query for latest profile
      final subscriptionId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0],
          "authors": [pubkey],
          "limit": 1,
        }
      ];
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      
      // Wait a bit for response
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if profile was received
      final updated = _profiles.firstWhere(
        (p) => p.pubkey == pubkey,
        orElse: () => cached,
      );
      
      return updated.name != null ? updated : null;
    } catch (e) {
      print('NostrService: Error getting profile: $e');
      return null;
    }
  }

  Future<List<NostrEvent>> getUserNotes(String pubkey, {int limit = 20}) async {
    try {
      print('NostrService: Getting notes for user $pubkey');
      final subscriptionId = 'notes_${DateTime.now().millisecondsSinceEpoch}';
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [1], // Text notes
          "authors": [pubkey],
          "limit": limit,
        }
      ];
      
      final notes = <NostrEvent>[];
      final completer = Completer<List<NostrEvent>>();
      
      // Set up temporary listener for notes BEFORE sending request
      StreamSubscription? subscription;
      subscription = _eventsController.stream.listen((eventData) {
        if (eventData['kind'] == 1 && eventData['pubkey'] == pubkey) {
          try {
            final event = NostrEvent.fromJson(eventData);
            notes.add(event);
            print('NostrService: Received note ${notes.length}/${limit} from ${pubkey.substring(0, 8)}...');
          } catch (e) {
            print('NostrService: Error parsing note event: $e');
          }
        }
      });
      
      // Small delay to ensure listener is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send request to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(request));
      }
      print('NostrService: Sent notes request to ${_channels.length} relays');
      
      // Wait for responses with timeout
      Timer(const Duration(seconds: 3), () {
        subscription?.cancel();
        
        // Send CLOSE to all channels
        final closeRequest = ["CLOSE", subscriptionId];
        for (final channel in _channels) {
          channel.sink.add(jsonEncode(closeRequest));
        }
        
        if (!completer.isCompleted) {
          // Sort by created_at descending (newest first)
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('NostrService: Returning ${notes.length} notes for $pubkey');
          completer.complete(notes);
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('NostrService: Error getting user notes: $e');
      return [];
    }
  }

  Future<bool> publishEvent(Map<String, dynamic> eventData) async {
    try {
      // Add created_at if not present
      if (!eventData.containsKey('created_at')) {
        eventData['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      
      // Sign the event
      final signedEvent = await _eventSigner.signEvent(eventData);
      if (signedEvent == null) {
        throw Exception('Failed to sign event');
      }
      
      final message = [
        "EVENT",
        signedEvent,
      ];
      
      // Send to all channels
      for (final channel in _channels) {
        channel.sink.add(jsonEncode(message));
      }
      
      print('NostrService: Published event with id: ${signedEvent['id']}');
      return true;
    } catch (e) {
      print('NostrService: Error publishing event: $e');
      return false;
    }
  }

  Future<void> connectToMultipleRelays() async {
    for (final url in _relayUrls) {
      try {
        final channel = WebSocketChannel.connect(Uri.parse(url));
        _channels.add(channel);
        print('NostrService: Connected to $url');
      } catch (e) {
        print('NostrService: Failed to connect to $url: $e');
      }
    }
    
    if (_channels.isNotEmpty) {
      _setupEventListeners();
    }
  }

  void disconnect() {
    _profileSubscription?.cancel();
    for (final channel in _channels) {
      channel.sink.close();
    }
    _channels.clear();
    _profiles.clear();
    _isConnected = false;
    print('NostrService: Disconnected');
  }

  
  void dispose() {
    _profilesController.close();
    _eventsController.close();
    disconnect();
  }
}