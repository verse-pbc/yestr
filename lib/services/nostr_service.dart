import 'dart:async';
import 'dart:convert';
import 'package:ndk/ndk.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as ndk_entities;
import 'package:ndk/domain_layer/entities/filter.dart' as ndk_filter;
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart' as local;
import 'ndk_adapter.dart';
import 'key_management_service.dart';

class NostrService {
  // Singleton instance
  static final NostrService _instance = NostrService._internal();
  factory NostrService() => _instance;
  NostrService._internal();
  
  final NDKAdapter _ndkAdapter = NDKAdapter();
  final KeyManagementService _keyService = KeyManagementService();
  final _profilesController = StreamController<NostrProfile>.broadcast();
  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();
  final List<NostrProfile> _profiles = [];
  StreamSubscription? _profileSubscription;
  bool _isConnected = false;

  Stream<NostrProfile> get profilesStream => _profilesController.stream;
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;
  List<NostrProfile> get profiles => List.unmodifiable(_profiles);
  bool get isConnected => _isConnected;
  
  /// Get NDK instance
  Ndk get ndk => _ndkAdapter.ndk;
  
  /// Compatibility getter for channels (returns empty list as NDK manages connections internally)
  List<dynamic> get channels => [];

  Future<void> connect() async {
    // Skip if already connected
    if (_isConnected) {
      print('NostrService: Already connected');
      return;
    }
    
    try {
      // Initialize NDK
      await _ndkAdapter.initialize();
      _isConnected = true;
      
      // Set up event listeners
      _setupEventListeners();
      
      // Test query to see if NDK is working
      print('NostrService: Testing NDK connection with a simple query...');
      _testNdkConnection();
      
      // Request profiles after a delay to ensure relays are connected
      print('NostrService: Scheduling profile request...');
      Timer(const Duration(seconds: 3), () {
        _requestProfiles();
      });
    } catch (e) {
      print('NostrService: Connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }
  
  void _setupEventListeners() {
    // NDK doesn't have a global stream - events come through queries
    // We'll handle events when they come from specific queries
  }

  Future<void> _requestProfiles() async {
    try {
      print('NostrService: Requesting profiles...');
      
      // Add small delay to let relays connect
      await Future.delayed(const Duration(seconds: 1));
      
      // Check relay status
      print('NostrService: Checking relay manager status...');
      print('NostrService: Connected relays: ${ndk.relays.connectedRelays.length}');
      
      // Create filter for profile metadata
      final filter = ndk_filter.Filter(
        kinds: [0],
        limit: 100,
      );
      
      // Query for profiles
      final response = ndk.requests.query(
        filters: [filter],
      );
      
      // Use the future property with timeout
      final events = await response.future
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('NostrService: Query timed out after 10 seconds');
            return [];
          });
      
      print('NostrService: Received ${events.length} profile events');
      
      // Process profile events
      for (final event in events) {
        final profile = _ndkAdapter.ndkEventToProfile(event);
        if (profile != null && !_profiles.any((p) => p.pubkey == profile.pubkey)) {
          _profiles.add(profile);
          _profilesController.add(profile);
        }
      }
      
      print('NostrService: Loaded ${_profiles.length} profiles');
    } catch (e) {
      print('NostrService: Error requesting profiles: $e');
      print('Stack trace: ${StackTrace.current}');
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
      
      // Create filter
      final filter = ndk_filter.Filter(
        kinds: [0],
        limit: limit,
        authors: authors,
      );
      
      // Query for profiles
      final response = ndk.requests.query(
        filters: [filter],
      );
      
      final events = <ndk_entities.Nip01Event>[];
      final completer = Completer<void>();
      
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      // Use the future property with timeout
      final events = await response.future
          .timeout(const Duration(seconds: 10), onTimeout: () {
            print('NostrService: Query timed out');
            return [];
          });
      
      // Process profile events
      for (final event in events) {
        final profile = _ndkAdapter.ndkEventToProfile(event);
        if (profile != null && !_profiles.any((p) => p.pubkey == profile.pubkey)) {
          _profiles.add(profile);
          _profilesController.add(profile);
        }
      }
      
      print('NostrService: Loaded ${_profiles.length} profiles');
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
      
      // Query for latest profile
      final filter = ndk_filter.Filter(
        kinds: [0],
        authors: [pubkey],
        limit: 1,
      );
      
      final response = ndk.requests.query(
        filters: [filter],
      );
      
      final events = <ndk_entities.Nip01Event>[];
      final completer = Completer<void>();
      Timer(const Duration(seconds: 3), () => completer.complete());
      
      response.stream.listen((event) {
        events.add(event);
      }, onDone: () => completer.complete());
      
      await completer.future;
      
      if (events.isNotEmpty) {
        final profile = _ndkAdapter.ndkEventToProfile(events.first);
        if (profile != null) {
          // Update cache
          _profiles.removeWhere((p) => p.pubkey == pubkey);
          _profiles.add(profile);
          return profile;
        }
      }
      
      return cached.name != null ? cached : null;
    } catch (e) {
      print('NostrService: Error getting profile: $e');
      return null;
    }
  }

  Future<List<local.NostrEvent>> getUserNotes(String pubkey, {int limit = 20}) async {
    try {
      final filter = ndk_filter.Filter(
        kinds: [1], // Text notes
        authors: [pubkey],
        limit: limit,
      );
      
      final response = ndk.requests.query(
        filters: [filter],
      );
      
      final events = <ndk_entities.Nip01Event>[];
      await for (final event in response.stream) {
        events.add(event);
      }
      await Future.delayed(const Duration(seconds: 5)); // Timeout simulation
      
      return events.map((e) => _ndkAdapter.ndkEventToLocal(e)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('NostrService: Error getting user notes: $e');
      return [];
    }
  }

  Future<bool> publishEvent(Map<String, dynamic> eventData) async {
    try {
      // Get private key
      final privateKey = await _keyService.getPrivateKey();
      final publicKey = await _keyService.getPublicKey();
      if (privateKey == null || publicKey == null) {
        throw Exception('No keys available');
      }
      
      // Login to NDK with private key
      ndk.accounts.loginPrivateKey(
        pubkey: publicKey,
        privkey: privateKey,
      );
      
      // Create NDK event
      final event = ndk_entities.Nip01Event(
        pubKey: eventData['pubkey'],
        createdAt: eventData['created_at'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        kind: eventData['kind'],
        tags: List<List<String>>.from(eventData['tags'] ?? []),
        content: eventData['content'],
      );
      
      // Sign and publish through broadcast usecase
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
      );
      
      // Wait for broadcast to complete
      await response.broadcastDoneFuture;
      
      print('NostrService: Published event with id: ${event.id}');
      return true;
    } catch (e) {
      print('NostrService: Error publishing event: $e');
      return false;
    }
  }

  /// Compatibility method - NDK handles multiple relays automatically
  Future<void> connectToMultipleRelays() async {
    // NDK already connects to multiple relays configured in NDKAdapter
    print('NostrService: NDK manages multiple relay connections automatically');
  }

  void disconnect() {
    _profileSubscription?.cancel();
    _ndkAdapter.dispose();
    _profiles.clear();
    _isConnected = false;
    print('NostrService: Disconnected');
  }

  Future<void> _testNdkConnection() async {
    try {
      print('NostrService: Running test query...');
      // Query for any profile event
      final filter = ndk_filter.Filter(
        kinds: [0],
        limit: 1,
      );
      
      final response = ndk.requests.query(
        filters: [filter],
      );
      
      print('NostrService: Waiting for test query response...');
      
      // Use the future property with timeout
      final events = await response.future
          .timeout(const Duration(seconds: 5), onTimeout: () {
            print('NostrService: Test query timed out');
            return [];
          });
      
      if (events.isNotEmpty) {
        print('NostrService: ✓ NDK connection is working! Received ${events.length} test event(s)');
        print('NostrService: First event: ${events.first.id} from ${events.first.pubKey}');
      } else {
        print('NostrService: ✗ NDK connection test failed - no events received');
      }
    } catch (e) {
      print('NostrService: Test query error: $e');
    }
  }
  
  void dispose() {
    _profilesController.close();
    _eventsController.close();
    disconnect();
  }
}