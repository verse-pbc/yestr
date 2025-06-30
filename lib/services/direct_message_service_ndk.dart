import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:ndk/ndk.dart';
import 'package:ndk/ndk.dart' as ndk;
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart' as app_models;
import '../models/direct_message.dart';
import '../models/conversation.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'dm_relay_service.dart';
import 'message_cache_service.dart';
import 'ndk_backup/ndk_service.dart';

/// Direct Message Service using NDK with NIP-59 Gift Wrap support
/// Maintains backward compatibility with NIP-04 messages
class DirectMessageServiceNdk {
  // Singleton instance
  static DirectMessageServiceNdk? _instance;
  
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();
  final DmRelayService _dmRelayService = DmRelayService();
  final MessageCacheService _cacheService = MessageCacheService();
  final NdkService _ndkService = NdkService.instance;
  
  // Message and conversation management
  final Map<String, List<DirectMessage>> _messagesByPubkey = {};
  final Map<String, Conversation> _conversations = {};
  final _messagesController = StreamController<DirectMessage>.broadcast();
  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  String? _currentUserPubkey;
  
  // Pagination
  static const int _conversationsPerPage = 10;
  int _currentPage = 0;
  bool _hasMoreConversations = true;
  
  // Message cache
  final Map<String, String> _decryptedMessageCache = {};
  static const int _maxCacheSize = 1000;
  
  // Stream subscriptions
  StreamSubscription? _eventsSubscription;
  final Map<String, StreamSubscription> _ndkSubscriptions = {};

  DirectMessageServiceNdk._internal(this._keyManagementService);
  
  // Factory constructor for singleton
  factory DirectMessageServiceNdk(KeyManagementService keyManagementService) {
    if (_instance == null) {
      print('[DM Service NDK] Creating new DirectMessageServiceNdk instance');
      _instance = DirectMessageServiceNdk._internal(keyManagementService);
    } else {
      print('[DM Service NDK] Returning existing DirectMessageServiceNdk instance');
    }
    return _instance!;
  }

  // Getters for streams and data
  Stream<DirectMessage> get messagesStream => _messagesController.stream;
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  List<Conversation> get conversations {
    final convList = _conversations.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    print('[DM Service NDK] Getting conversations - count: ${convList.length}');
    return convList;
  }

  /// Initialize NDK if not already initialized
  Future<void> _ensureNdkInitialized() async {
    if (!_ndkService.isInitialized) {
      print('[DM Service NDK] Initializing NDK...');
      await _ndkService.initialize();
    }
    
    // Ensure user is logged in to NDK
    if (!_ndkService.isLoggedIn) {
      final privateKey = await _keyManagementService.getPrivateKey();
      if (privateKey != null) {
        await _ndkService.login(privateKey);
      }
    }
  }

  /// Send a direct message to a recipient using NIP-59 Gift Wrap
  Future<bool> sendDirectMessage(String recipientPubkey, String content) async {
    // Create a minimal profile for backward compatibility
    final recipient = NostrProfile(
      pubkey: recipientPubkey,
      name: null,
      displayName: null,
      about: null,
      picture: null,
      banner: null,
      nip05: null,
      lud16: null,
      website: null,
      createdAt: DateTime.now(),
    );
    return _sendDirectMessage(content, recipient);
  }

  /// Send a direct message using NIP-59 Gift Wrap
  Future<bool> _sendDirectMessage(String content, NostrProfile recipient) async {
    print('[DM Service NDK] Starting sendDirectMessage with gift wrap...');
    print('[DM Service NDK] Content: "$content"');
    print('[DM Service NDK] Recipient: ${recipient.displayNameOrName} (${recipient.pubkey})');
    
    try {
      // Ensure NDK is initialized
      await _ensureNdkInitialized();
      
      // Check if user is logged in
      print('[DM Service NDK] Checking login status...');
      final hasPrivateKey = await _keyManagementService.hasPrivateKey();
      print('[DM Service NDK] Has private key: $hasPrivateKey');
      if (!hasPrivateKey) {
        throw Exception('You must be logged in to send messages');
      }

      // Get sender's keys
      print('[DM Service NDK] Getting sender keys...');
      final publicKey = await _keyManagementService.getPublicKey();
      print('[DM Service NDK] Public key: ${publicKey != null ? publicKey : 'NULL'}');
      if (publicKey == null) {
        throw Exception('Unable to get sender keys');
      }

      // For now, use legacy NIP-04 encryption since gift wrap API differs
      // TODO: Update when gift wrap API is stable
      print('[DM Service NDK] Using NIP-04 encryption...');
      return await _sendLegacyDirectMessage(content, recipient);
    } catch (e) {
      print('[DM Service NDK] ERROR in sendDirectMessage: $e');
      print('[DM Service NDK] Stack trace: ${StackTrace.current}');
      
      // Fallback to NIP-04 if gift wrap fails
      print('[DM Service NDK] Falling back to NIP-04 encryption...');
      return await _sendLegacyDirectMessage(content, recipient);
    }
  }

  /// Send a direct message using legacy NIP-04 encryption (fallback)
  Future<bool> _sendLegacyDirectMessage(String content, NostrProfile recipient) async {
    try {
      final privateKey = await _keyManagementService.getPrivateKey();
      final publicKey = await _keyManagementService.getPublicKey();
      
      if (privateKey == null || publicKey == null) {
        throw Exception('Unable to get sender keys');
      }

      // Encrypt the message content using NIP-04
      final encryptedContent = await _encryptMessage(content, privateKey, recipient.pubkey);

      // Create event using NDK
      final tags = [['p', recipient.pubkey]];
      final event = Nip01Event(
        pubKey: publicKey,
        kind: 4, // NIP-04 encrypted DM
        tags: tags,
        content: encryptedContent,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      // Sign the event
      final signer = Bip340EventSigner(privateKey: privateKey, publicKey: publicKey);
      await signer.sign(event);

      // Publish using NDK
      final response = _ndkService.ndk.broadcast.broadcast(
        nostrEvent: event,
      );
      
      // Wait for broadcast to complete
      final results = await response.broadcastDoneFuture;
      bool success = results.any((r) => r.broadcastSuccessful);
      
      print('[DM Service NDK] ✓ Successfully published NIP-04 DM');
      
      // Create local message for immediate UI update
      final message = DirectMessage(
        id: event.id,
        content: content,
        senderPubkey: publicKey,
        recipientPubkey: recipient.pubkey,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        isFromMe: true,
        isRead: true,
      );
      
      // Update local state
      if (!_messagesByPubkey.containsKey(recipient.pubkey)) {
        _messagesByPubkey[recipient.pubkey] = [];
      }
      _messagesByPubkey[recipient.pubkey]!.add(message);
      _messagesController.add(message);
      await _updateConversation(recipient.pubkey, message);
      await _saveMessagesToCache(recipient.pubkey);
      
      return success;
    } catch (e) {
      print('[DM Service NDK] ERROR in sendLegacyDirectMessage: $e');
      return false;
    }
  }

  /// Load conversations from Nostr relays with pagination
  Future<void> loadConversations({bool loadMore = false}) async {
    try {
      print('[DM Service NDK] loadConversations called with loadMore=$loadMore');
      await _ensureNdkInitialized();
      
      _currentUserPubkey = await _keyManagementService.getPublicKey();
      print('[DM Service NDK] Current user pubkey: $_currentUserPubkey');
      if (_currentUserPubkey == null) {
        print('[DM Service NDK] No user public key available - user not logged in?');
        return;
      }

      if (loadMore) {
        _currentPage++;
      } else {
        _currentPage = 0;
        // Load cached conversations first for instant UI
        print('[DM Service NDK] Loading cached conversations...');
        await _loadCachedConversations();
        print('[DM Service NDK] After loading cache, conversations count: ${_conversations.length}');
      }

      // Cancel existing subscriptions
      await _cancelNdkSubscriptions();

      // Get timestamp for 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = thirtyDaysAgo.millisecondsSinceEpoch ~/ 1000;

      print('[DM Service NDK] Loading conversations page $_currentPage...');

      // Subscribe to gift-wrapped messages (NIP-59)
      final giftWrapFilter = Filter(
        kinds: [1059], // Gift wrap kind
        tags: {'p': [_currentUserPubkey!]}, // Messages sent to us
        since: thirtyDaysAgoTimestamp,
        limit: _conversationsPerPage * 2,
      );

      // Also subscribe to old-style DMs for compatibility (NIP-04)
      final legacyDmFilter = Filter(
        kinds: [4], // Legacy encrypted DM kind
        tags: {'p': [_currentUserPubkey!]},
        since: thirtyDaysAgoTimestamp,
        limit: _conversationsPerPage * 2,
      );
      
      // Subscribe to our own messages
      final outgoingFilter = Filter(
        kinds: [4, 1059],
        authors: [_currentUserPubkey!],
        since: thirtyDaysAgoTimestamp,
        limit: _conversationsPerPage * 2,
      );

      // Create subscriptions
      final giftWrapRequest = _ndkService.ndk.requests.subscription(filters: [giftWrapFilter]);
      _ndkSubscriptions['gift_wrap'] = giftWrapRequest.stream
          .listen(_handleGiftWrapMessage);
          
      final legacyRequest = _ndkService.ndk.requests.subscription(filters: [legacyDmFilter]);
      _ndkSubscriptions['legacy'] = legacyRequest.stream
          .listen((event) => _handleLegacyMessage(event, false));

      final outgoingRequest = _ndkService.ndk.requests.subscription(filters: [outgoingFilter]);
      _ndkSubscriptions['outgoing'] = outgoingRequest.stream
          .listen((event) {
            if (event.kind == 1059) {
              _handleGiftWrapMessage(event);
            } else {
              _handleLegacyMessage(event, true);
            }
          });

      print('[DM Service NDK] Subscriptions created');
    } catch (e) {
      print('[DM Service NDK] Error loading conversations: $e');
    }
  }

  /// Handle incoming gift-wrapped message
  Future<void> _handleGiftWrapMessage(Nip01Event event) async {
    // Skip gift wrap for now since API differs
    // TODO: Implement when gift wrap API is stable
    print('[DM Service NDK] Skipping gift wrap message (not implemented)');
  }
  
  /// Handle legacy encrypted message (NIP-04)
  Future<void> _handleLegacyMessage(Nip01Event event, bool isOutgoing) async {
    try {
      print('[DM Service NDK] Handling legacy NIP-04 message');
      
      String otherPubkey;
      String senderPubkey;
      String recipientPubkey;
      
      if (isOutgoing) {
        senderPubkey = _currentUserPubkey!;
        // Get recipient from p tag
        final pTag = event.tags.firstWhere(
          (tag) => tag.isNotEmpty && tag[0] == 'p',
          orElse: () => [],
        );
        if (pTag.length < 2) return;
        recipientPubkey = pTag[1];
        otherPubkey = recipientPubkey;
      } else {
        senderPubkey = event.pubKey;
        recipientPubkey = _currentUserPubkey!;
        otherPubkey = senderPubkey;
      }

      // Check cache first
      final cacheKey = '${event.id}_${event.content.hashCode}';
      String? decryptedContent = _decryptedMessageCache[cacheKey];
      
      if (decryptedContent == null) {
        // Decrypt the message
        final privateKey = await _keyManagementService.getPrivateKey();
        if (privateKey == null) return;

        // Decrypt in background using compute
        try {
          decryptedContent = await compute(
            _decryptMessageInBackground,
            _DecryptParams(
              encryptedContent: event.content,
              privateKey: privateKey,
              publicKey: otherPubkey,
            ),
          );
          
          if (decryptedContent != null) {
            // Cache the decrypted message
            _addToCache(cacheKey, decryptedContent);
          }
        } catch (e) {
          print('[DM Service NDK] Error decrypting in background: $e');
          // Fallback to main thread decryption
          decryptedContent = await _decryptMessage(
            event.content,
            privateKey,
            otherPubkey,
          );
        }
      }

      if (decryptedContent == null) return;

      // Create DirectMessage object
      final message = DirectMessage(
        id: event.id,
        content: decryptedContent,
        senderPubkey: senderPubkey,
        recipientPubkey: recipientPubkey,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        isFromMe: isOutgoing,
        isRead: isOutgoing,
      );

      // Store message
      if (!_messagesByPubkey.containsKey(otherPubkey)) {
        _messagesByPubkey[otherPubkey] = [];
      }
      
      // Check if we already have this message
      final existingMessages = _messagesByPubkey[otherPubkey]!;
      if (!existingMessages.any((m) => m.id == message.id)) {
        existingMessages.add(message);
        existingMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        print('[DM Service NDK] Added legacy message to conversation with $otherPubkey');
        
        // Emit the new message immediately for real-time updates
        _messagesController.add(message);
        
        // Update conversation
        await _updateConversation(otherPubkey, message);
        
        // Save to cache
        await _saveMessagesToCache(otherPubkey);
      }
    } catch (e) {
      print('[DM Service NDK] Error handling legacy message: $e');
    }
  }

  /// Update conversation with new message
  Future<void> _updateConversation(String pubkey, DirectMessage message) async {
    try {
      // Get or create profile
      NostrProfile? profile = _conversations[pubkey]?.profile;
      if (profile == null) {
        profile = await _nostrService.getProfile(pubkey);
        if (profile == null) {
          // Create minimal profile
          profile = NostrProfile(
            pubkey: pubkey,
            name: pubkey.substring(0, 8),
            displayName: null,
            about: null,
            picture: null,
            banner: null,
            nip05: null,
            lud16: null,
            website: null,
            createdAt: DateTime.now(),
          );
        }
      }

      // Update conversation
      final existingConversation = _conversations[pubkey];
      final unreadCount = existingConversation?.unreadCount ?? 0;
      
      _conversations[pubkey] = Conversation(
        profile: profile,
        lastMessage: message.content,
        lastMessageTime: message.createdAt,
        unreadCount: message.isFromMe ? 0 : (message.isRead ? unreadCount : unreadCount + 1),
      );
      
      print('[DM Service NDK] Updated conversation for $pubkey');

      // Emit updated conversations list
      _conversationsController.add(conversations);
    } catch (e) {
      print('[DM Service NDK] Error updating conversation: $e');
    }
  }

  /// Get messages for a specific pubkey
  Future<List<DirectMessage>> getMessagesForPubkey(String pubkey) async {
    print('[DM Service NDK] Getting messages for pubkey: $pubkey');
    
    var messages = _messagesByPubkey[pubkey] ?? [];
    print('[DM Service NDK] Found ${messages.length} messages in memory for $pubkey');
    
    // If no messages in memory, try to load from cache
    if (messages.isEmpty) {
      print('[DM Service NDK] No messages in memory, trying cache...');
      final cachedMessages = await _cacheService.loadMessages(pubkey);
      if (cachedMessages.isNotEmpty) {
        print('[DM Service NDK] Found ${cachedMessages.length} messages in cache');
        _messagesByPubkey[pubkey] = cachedMessages;
        messages = cachedMessages;
      }
    }
    
    // If still no messages, try to load specifically for this pubkey
    if (messages.isEmpty && _currentUserPubkey != null) {
      print('[DM Service NDK] No messages in cache, attempting to load from relays...');
      
      await _ensureNdkInitialized();
      
      // Query for messages for this specific conversation
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = thirtyDaysAgo.millisecondsSinceEpoch ~/ 1000;
      
      // Gift wrap messages
      final giftWrapFilter = Filter(
        kinds: [1059],
        tags: {'p': [_currentUserPubkey!, pubkey]},
        since: thirtyDaysAgoTimestamp,
        limit: 50,
      );
      
      // Legacy incoming messages
      final incomingFilter = Filter(
        kinds: [4],
        authors: [pubkey],
        tags: {'p': [_currentUserPubkey!]},
        since: thirtyDaysAgoTimestamp,
        limit: 50,
      );
      
      // Legacy outgoing messages
      final outgoingFilter = Filter(
        kinds: [4],
        authors: [_currentUserPubkey!],
        tags: {'p': [pubkey]},
        since: thirtyDaysAgoTimestamp,
        limit: 50,
      );

      // Query events
      final giftWrapEvents = <Nip01Event>[];
      final incomingEvents = <Nip01Event>[];
      final outgoingEvents = <Nip01Event>[];
      
      // Query gift wrap events (skip for now)
      // TODO: Enable when gift wrap is implemented
      
      // Query incoming events
      final incomingRequest = _ndkService.ndk.requests.query(filters: [incomingFilter]);
      await for (final event in incomingRequest.stream) {
        incomingEvents.add(event);
      }
      
      // Query outgoing events
      final outgoingRequest = _ndkService.ndk.requests.query(filters: [outgoingFilter]);
      await for (final event in outgoingRequest.stream) {
        outgoingEvents.add(event);
      }

      // Process messages
      for (final event in giftWrapEvents) {
        await _handleGiftWrapMessage(event);
      }
      for (final event in incomingEvents) {
        await _handleLegacyMessage(event, false);
      }
      for (final event in outgoingEvents) {
        await _handleLegacyMessage(event, true);
      }
      
      // Return any messages that came in
      final updatedMessages = _messagesByPubkey[pubkey] ?? [];
      print('[DM Service NDK] After loading attempt, found ${updatedMessages.length} messages');
      return updatedMessages;
    }
    
    return messages;
  }
  
  /// Subscribe to real-time messages for a specific conversation
  Future<void> subscribeToConversationMessages(String otherPubkey) async {
    if (_currentUserPubkey == null) {
      _currentUserPubkey = await _keyManagementService.getPublicKey();
      if (_currentUserPubkey == null) {
        print('[DM Service NDK] Cannot subscribe: no user pubkey');
        return;
      }
    }
    
    await _ensureNdkInitialized();
    
    print('[DM Service NDK] Subscribing to conversation messages with $otherPubkey');
    
    // Cancel existing conversation-specific subscriptions
    _ndkSubscriptions['conv_gift']?.cancel();
    _ndkSubscriptions['conv_in']?.cancel();
    _ndkSubscriptions['conv_out']?.cancel();
    
    // Get recent messages and all future messages
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final oneMinuteAgoTimestamp = oneMinuteAgo.millisecondsSinceEpoch ~/ 1000;
    
    // Subscribe to gift wrap messages in this conversation
    final giftWrapFilter = Filter(
      kinds: [1059],
      tags: {'p': [_currentUserPubkey!, otherPubkey]},
      since: oneMinuteAgoTimestamp,
      limit: 20,
    );
    
    // Subscribe to incoming legacy messages from the other user
    final incomingFilter = Filter(
      kinds: [4],
      authors: [otherPubkey],
      tags: {'p': [_currentUserPubkey!]},
      since: oneMinuteAgoTimestamp,
      limit: 20,
    );
    
    // Subscribe to our sent messages
    final outgoingFilter = Filter(
      kinds: [4, 1059],
      authors: [_currentUserPubkey!],
      tags: {'p': [otherPubkey]},
      since: oneMinuteAgoTimestamp,
      limit: 20,
    );
    
    final giftRequest = _ndkService.ndk.requests.subscription(filters: [giftWrapFilter]);
    _ndkSubscriptions['conv_gift'] = giftRequest.stream
        .listen(_handleGiftWrapMessage);
        
    final inRequest = _ndkService.ndk.requests.subscription(filters: [incomingFilter]);
    _ndkSubscriptions['conv_in'] = inRequest.stream
        .listen((event) => _handleLegacyMessage(event, false));
        
    final outRequest = _ndkService.ndk.requests.subscription(filters: [outgoingFilter]);
    _ndkSubscriptions['conv_out'] = outRequest.stream
        .listen((event) {
          if (event.kind == 1059) {
            _handleGiftWrapMessage(event);
          } else {
            _handleLegacyMessage(event, true);
          }
        });
  }

  /// Mark conversation as read
  void markConversationAsRead(String pubkey) {
    final messages = _messagesByPubkey[pubkey];
    if (messages != null) {
      for (var i = 0; i < messages.length; i++) {
        if (!messages[i].isFromMe && !messages[i].isRead) {
          messages[i] = messages[i].copyWith(isRead: true);
        }
      }
    }

    final conversation = _conversations[pubkey];
    if (conversation != null) {
      _conversations[pubkey] = conversation.copyWith(unreadCount: 0);
      _conversationsController.add(conversations);
    }
  }

  /// Encrypt a message using NIP-04 specification (for backward compatibility)
  Future<String> _encryptMessage(String message, String senderPrivkey, String recipientPubkey) async {
    try {
      // Convert hex keys to bytes
      final privateKeyBytes = Uint8List.fromList(hex.decode(senderPrivkey));
      final publicKeyBytes = Uint8List.fromList(hex.decode(recipientPubkey));

      // Generate shared secret using ECDH
      final sharedSecret = _computeSharedSecret(privateKeyBytes, publicKeyBytes);

      // Generate random IV
      final secureRandom = FortunaRandom();
      
      // Properly seed the random number generator
      final seed = Uint8List(32);
      final random = Random.secure();
      for (int i = 0; i < seed.length; i++) {
        seed[i] = random.nextInt(256);
      }
      
      secureRandom.seed(KeyParameter(seed));
      final iv = secureRandom.nextBytes(16);

      // Encrypt the message
      final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
      final params = ParametersWithIV(KeyParameter(sharedSecret), iv);
      cipher.init(true, PaddedBlockCipherParameters(params, null));

      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final encrypted = cipher.process(messageBytes);

      // According to NIP-04: base64-encoded encrypted string appended by the base64-encoded IV
      final encryptedBase64 = base64.encode(encrypted);
      final ivBase64 = base64.encode(iv);
      final result = '$encryptedBase64?iv=$ivBase64';
      
      return result;
    } catch (e) {
      print('Encryption error: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypt a message using NIP-04 specification
  Future<String?> _decryptMessage(String encryptedContent, String privateKey, String publicKey) async {
    try {
      // Parse the encrypted content format: <encrypted>?iv=<iv>
      final parts = encryptedContent.split('?iv=');
      if (parts.length != 2) {
        print('[DM Service NDK] Invalid encrypted content format');
        return null;
      }

      final encryptedBase64 = parts[0];
      final ivBase64 = parts[1];

      final encrypted = base64.decode(encryptedBase64);
      final iv = base64.decode(ivBase64);

      // Convert hex keys to bytes
      final privateKeyBytes = Uint8List.fromList(hex.decode(privateKey));
      final publicKeyBytes = Uint8List.fromList(hex.decode(publicKey));

      // Generate shared secret using ECDH
      final sharedSecret = _computeSharedSecret(privateKeyBytes, publicKeyBytes);

      // Decrypt the message
      final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
      final params = ParametersWithIV(KeyParameter(sharedSecret), iv);
      cipher.init(false, PaddedBlockCipherParameters(params, null));

      final decrypted = cipher.process(encrypted);
      return utf8.decode(decrypted);
    } catch (e) {
      print('[DM Service NDK] Error decrypting message: $e');
      return null;
    }
  }

  /// Compute ECDH shared secret
  Uint8List _computeSharedSecret(Uint8List privateKey, Uint8List publicKey) {
    try {
      // secp256k1 curve parameters
      final curve = ECCurve_secp256k1();
      final domainParams = ECDomainParametersImpl('secp256k1', curve.curve, curve.G, curve.n, curve.h, curve.seed);

      // Create private key parameter
      final d = BigInt.parse(hex.encode(privateKey), radix: 16);
      final privKey = ECPrivateKey(d, domainParams);

      // Create public key point
      ECPoint? pubPoint;
      if (publicKey.length == 32) {
        // Nostr public key - just X coordinate
        final compressed = Uint8List(33);
        compressed[0] = 0x02; // Assume even Y coordinate
        compressed.setRange(1, 33, publicKey);
        pubPoint = curve.curve.decodePoint(compressed);
      } else if (publicKey.length == 33) {
        // Already compressed
        pubPoint = curve.curve.decodePoint(publicKey);
      } else if (publicKey.length == 65) {
        // Uncompressed public key
        pubPoint = curve.curve.decodePoint(publicKey);
      } else {
        throw Exception('Invalid public key length: ${publicKey.length}');
      }

      if (pubPoint == null) {
        throw Exception('Failed to decode public key point');
      }

      // Compute shared secret: private key * public point
      final sharedPoint = pubPoint * d;
      if (sharedPoint == null) {
        throw Exception('Failed to compute shared point');
      }

      // Return X coordinate of shared point as shared secret (NIP-04 spec)
      final sharedX = sharedPoint.x!.toBigInteger()!;
      final sharedBytes = _bigIntToBytes(sharedX, 32);
      
      return sharedBytes;
    } catch (e) {
      print('Error computing shared secret: $e');
      throw Exception('Failed to compute shared secret: $e');
    }
  }

  /// Convert BigInt to fixed-length byte array
  Uint8List _bigIntToBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var hex = value.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }
    final valueBytes = Uint8List.fromList(List<int>.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ));
    
    final offset = length - valueBytes.length;
    bytes.setRange(offset, length, valueBytes);
    return bytes;
  }

  /// Cancel all NDK subscriptions
  Future<void> _cancelNdkSubscriptions() async {
    for (final subscription in _ndkSubscriptions.values) {
      await subscription.cancel();
    }
    _ndkSubscriptions.clear();
  }

  void dispose() {
    _eventsSubscription?.cancel();
    _cancelNdkSubscriptions();
    _messagesController.close();
    _conversationsController.close();
    _dmRelayService.dispose();
  }
  
  /// Reset the singleton instance (useful for logout)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  /// Debug method to check cache state
  Future<void> debugCacheState() async {
    print('[DM Service NDK] === DEBUG CACHE STATE ===');
    print('[DM Service NDK] In-memory conversations: ${_conversations.length}');
    print('[DM Service NDK] In-memory messages by pubkey: ${_messagesByPubkey.keys.toList()}');
    
    final cachedPubkeys = await _cacheService.getCachedConversations();
    print('[DM Service NDK] Cached conversation pubkeys: $cachedPubkeys');
    
    for (final pubkey in cachedPubkeys) {
      final messages = await _cacheService.loadMessages(pubkey);
      print('[DM Service NDK] Cached messages for $pubkey: ${messages.length}');
    }
    
    print('[DM Service NDK] Current user pubkey: $_currentUserPubkey');
    print('[DM Service NDK] Is NDK initialized: ${_ndkService.isInitialized}');
    print('[DM Service NDK] Is NDK logged in: ${_ndkService.isLoggedIn}');
    print('[DM Service NDK] ========================');
    
    // Try to force load from cache
    if (cachedPubkeys.isNotEmpty && _conversations.isEmpty) {
      print('[DM Service NDK] Force loading from cache...');
      await _loadCachedConversations();
      print('[DM Service NDK] After force load: ${_conversations.length} conversations');
      _conversationsController.add(conversations);
    }
  }
  
  /// Add to cache with size management
  void _addToCache(String key, String value) {
    _decryptedMessageCache[key] = value;
    
    // Remove oldest entries if cache is too large
    if (_decryptedMessageCache.length > _maxCacheSize) {
      final keysToRemove = _decryptedMessageCache.keys
          .take(_decryptedMessageCache.length - _maxCacheSize)
          .toList();
      for (final key in keysToRemove) {
        _decryptedMessageCache.remove(key);
      }
    }
  }
  
  /// Get paginated conversations
  List<Conversation> getPaginatedConversations() {
    final allConversations = conversations;
    print('[DM Service NDK] getPaginatedConversations - total: ${allConversations.length}, page: $_currentPage');
    final startIndex = 0;
    final endIndex = (_currentPage + 1) * _conversationsPerPage;
    
    if (endIndex >= allConversations.length) {
      _hasMoreConversations = false;
      return allConversations;
    }
    
    return allConversations.sublist(0, endIndex);
  }
  
  /// Check if more conversations can be loaded
  bool get hasMoreConversations => _hasMoreConversations;
  
  /// Load cached conversations for instant UI
  Future<void> _loadCachedConversations() async {
    try {
      final cachedPubkeys = await _cacheService.getCachedConversations();
      print('[DM Service NDK] Loading ${cachedPubkeys.length} cached conversations');
      
      for (final pubkey in cachedPubkeys) {
        final messages = await _cacheService.loadMessages(pubkey);
        if (messages.isNotEmpty) {
          _messagesByPubkey[pubkey] = messages;
          
          // Get or create profile
          NostrProfile? profile = await _nostrService.getProfile(pubkey);
          if (profile == null) {
            profile = NostrProfile(
              pubkey: pubkey,
              name: pubkey.substring(0, 8),
              displayName: null,
              about: null,
              picture: null,
              banner: null,
              nip05: null,
              lud16: null,
              website: null,
              createdAt: DateTime.now(),
            );
          }
          
          // Create conversation from cached data
          final lastMessage = messages.last;
          _conversations[pubkey] = Conversation(
            profile: profile,
            lastMessage: lastMessage.content,
            lastMessageTime: lastMessage.createdAt,
            unreadCount: messages.where((m) => !m.isFromMe && !m.isRead).length,
          );
        }
      }
      
      // Emit cached conversations immediately
      _conversationsController.add(conversations);
    } catch (e) {
      print('[DM Service NDK] Error loading cached conversations: $e');
    }
  }
  
  /// Save messages to cache
  Future<void> _saveMessagesToCache(String pubkey) async {
    try {
      final messages = _messagesByPubkey[pubkey];
      if (messages != null && messages.isNotEmpty) {
        await _cacheService.saveMessages(pubkey, messages);
      }
    } catch (e) {
      print('[DM Service NDK] Error saving messages to cache: $e');
    }
  }
}

/// Parameters for background decryption
class _DecryptParams {
  final String encryptedContent;
  final String privateKey;
  final String publicKey;
  
  _DecryptParams({
    required this.encryptedContent,
    required this.privateKey,
    required this.publicKey,
  });
}

/// Top-level function for background decryption
Future<String?> _decryptMessageInBackground(_DecryptParams params) async {
  try {
    // Parse the encrypted content format: <encrypted>?iv=<iv>
    final parts = params.encryptedContent.split('?iv=');
    if (parts.length != 2) {
      return null;
    }

    final encryptedBase64 = parts[0];
    final ivBase64 = parts[1];

    final encrypted = base64.decode(encryptedBase64);
    final iv = base64.decode(ivBase64);

    // Convert hex keys to bytes
    final privateKeyBytes = Uint8List.fromList(hex.decode(params.privateKey));
    final publicKeyBytes = Uint8List.fromList(hex.decode(params.publicKey));

    // Generate shared secret using ECDH
    final sharedSecret = _computeSharedSecretBackground(privateKeyBytes, publicKeyBytes);

    // Decrypt the message
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    final cipherParams = ParametersWithIV(KeyParameter(sharedSecret), iv);
    cipher.init(false, PaddedBlockCipherParameters(cipherParams, null));

    final decrypted = cipher.process(encrypted);
    return utf8.decode(decrypted);
  } catch (e) {
    return null;
  }
}

/// Compute shared secret in background
Uint8List _computeSharedSecretBackground(Uint8List privateKey, Uint8List publicKey) {
  try {
    // secp256k1 curve parameters
    final curve = ECCurve_secp256k1();
    final domainParams = ECDomainParametersImpl('secp256k1', curve.curve, curve.G, curve.n, curve.h, curve.seed);

    // Create private key parameter
    final d = BigInt.parse(hex.encode(privateKey), radix: 16);
    final privKey = ECPrivateKey(d, domainParams);

    // Create public key point
    ECPoint? pubPoint;
    if (publicKey.length == 32) {
      // Nostr public key - just X coordinate
      final compressed = Uint8List(33);
      compressed[0] = 0x02; // Assume even Y coordinate
      compressed.setRange(1, 33, publicKey);
      pubPoint = curve.curve.decodePoint(compressed);
    } else if (publicKey.length == 33) {
      // Already compressed
      pubPoint = curve.curve.decodePoint(publicKey);
    } else if (publicKey.length == 65) {
      // Uncompressed public key
      pubPoint = curve.curve.decodePoint(publicKey);
    } else {
      throw Exception('Invalid public key length: ${publicKey.length}');
    }

    if (pubPoint == null) {
      throw Exception('Failed to decode public key point');
    }

    // Compute shared secret: private key * public point
    final sharedPoint = pubPoint * d;
    if (sharedPoint == null) {
      throw Exception('Failed to compute shared point');
    }

    // Return X coordinate of shared point as shared secret (NIP-04 spec)
    final sharedX = sharedPoint.x!.toBigInteger()!;
    return _bigIntToBytesBackground(sharedX, 32);
  } catch (e) {
    throw Exception('Failed to compute shared secret: $e');
  }
}

/// Convert BigInt to fixed-length byte array in background
Uint8List _bigIntToBytesBackground(BigInt value, int length) {
  final bytes = Uint8List(length);
  var hexStr = value.toRadixString(16);
  if (hexStr.length % 2 != 0) {
    hexStr = '0$hexStr';
  }
  final valueBytes = Uint8List.fromList(List<int>.generate(
    hexStr.length ~/ 2,
    (i) => int.parse(hexStr.substring(i * 2, i * 2 + 2), radix: 16),
  ));
  
  final offset = length - valueBytes.length;
  bytes.setRange(offset, length, valueBytes);
  return bytes;
}