import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import '../models/direct_message.dart';
import '../models/conversation.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'dm_relay_service.dart';
import 'message_cache_service.dart';
import 'event_signer.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';

class DirectMessageService {
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();
  final DmRelayService _dmRelayService = DmRelayService();
  final MessageCacheService _cacheService = MessageCacheService();
  
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

  DirectMessageService(this._keyManagementService);

  // Getters for streams and data
  Stream<DirectMessage> get messagesStream => _messagesController.stream;
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  List<Conversation> get conversations => _conversations.values.toList()
    ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

  /// Send a direct message to a recipient using NIP-04 encryption
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

  /// Send a direct message to a recipient using NIP-04 encryption
  Future<bool> _sendDirectMessage(String content, NostrProfile recipient) async {
    print('[DM Service] Starting sendDirectMessage...');
    print('[DM Service] Content: "$content"');
    print('[DM Service] Recipient: ${recipient.displayNameOrName} (${recipient.pubkey})');
    
    try {
      // Check if user is logged in
      print('[DM Service] Checking login status...');
      final hasPrivateKey = await _keyManagementService.hasPrivateKey();
      print('[DM Service] Has private key: $hasPrivateKey');
      if (!hasPrivateKey) {
        throw Exception('You must be logged in to send messages');
      }

      // Get sender's keys
      print('[DM Service] Getting sender keys...');
      final privateKey = await _keyManagementService.getPrivateKey();
      final publicKey = await _keyManagementService.getPublicKey();
      print('[DM Service] Private key: ${privateKey != null ? 'Present' : 'NULL'}');
      print('[DM Service] Public key: ${publicKey != null ? publicKey : 'NULL'}');
      if (privateKey == null || publicKey == null) {
        throw Exception('Unable to get sender keys');
      }

      // Encrypt the message content using NIP-04
      print('[DM Service] Encrypting message...');
      final encryptedContent = await _encryptMessage(content, privateKey, recipient.pubkey);
      print('[DM Service] Encrypted content: ${encryptedContent.substring(0, 50)}...');

      // Create tags for the direct message
      final List<List<String>> tags = [
        ['p', recipient.pubkey],
      ];

      // Create event data with signature using EventSigner
      print('[DM Service] Creating signed event...');
      final eventData = EventSigner.createSignedEvent(
        privateKeyHex: privateKey,
        publicKeyHex: publicKey,
        kind: 4, // Kind 4 is for encrypted direct messages
        tags: tags,
        content: encryptedContent,
      );
      print('[DM Service] Event created with ID: ${eventData['id']}');

      // Publish to multiple relays directly
      final relays = [
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
        'wss://relay.nostr.band',
        'wss://relay.yestr.social',
      ];
      
      bool publishedToAnyRelay = false;
      print('[DM Service] Publishing to ${relays.length} relays...');
      
      for (final relay in relays) {
        try {
          print('[DM Service] Publishing to $relay...');
          final success = await _publishToRelay(relay, eventData);
          if (success) {
            publishedToAnyRelay = true;
            print('[DM Service] ✓ Successfully published DM to $relay');
          } else {
            print('[DM Service] ✗ Failed to publish to $relay');
          }
        } catch (e) {
          print('[DM Service] ✗ Error publishing to $relay: $e');
        }
      }

      print('[DM Service] Published to any relay: $publishedToAnyRelay');
      return publishedToAnyRelay;
    } catch (e) {
      print('[DM Service] ERROR in sendDirectMessage: $e');
      print('[DM Service] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Encrypt a message using NIP-04 specification
  Future<String> _encryptMessage(String message, String senderPrivkey, String recipientPubkey) async {
    try {
      // Convert hex keys to bytes
      final privateKeyBytes = Uint8List.fromList(hex.decode(senderPrivkey));
      final publicKeyBytes = Uint8List.fromList(hex.decode(recipientPubkey));

      // Generate shared secret using ECDH
      final sharedSecret = _computeSharedSecret(privateKeyBytes, publicKeyBytes);
      print('[DM Service] Shared secret length: ${sharedSecret.length}');

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
      print('[DM Service] IV length: ${iv.length}');

      // Encrypt the message
      final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
      final params = ParametersWithIV(KeyParameter(sharedSecret), iv);
      cipher.init(true, PaddedBlockCipherParameters(params, null));

      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final encrypted = cipher.process(messageBytes);
      print('[DM Service] Encrypted length: ${encrypted.length}');

      // According to NIP-04: base64-encoded encrypted string appended by the base64-encoded IV
      final encryptedBase64 = base64.encode(encrypted);
      final ivBase64 = base64.encode(iv);
      final result = '$encryptedBase64?iv=$ivBase64';
      
      print('[DM Service] Final encrypted content format: <encrypted>?iv=<iv>');
      return result;
    } catch (e) {
      print('Encryption error: $e');
      throw Exception('Failed to encrypt message: $e');
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
      // For Nostr, public keys are 32-byte X coordinates
      // We need to prepend 0x02 to make it a valid compressed public key
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
      
      print('[DM Service] Shared secret (X coordinate): ${hex.encode(sharedBytes)}');
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

  /// Publish event to a specific relay
  Future<bool> _publishToRelay(String relayUrl, Map<String, dynamic> eventData) async {
    print('[DM Service - Relay] Connecting to $relayUrl...');
    final completer = Completer<bool>();
    
    try {
      final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      
      // Send event
      final message = ["EVENT", eventData];
      final messageJson = jsonEncode(message);
      print('[DM Service - Relay] Sending EVENT to $relayUrl');
      print('[DM Service - Relay] Message: ${messageJson.substring(0, 100)}...');
      channel.sink.add(messageJson);
      
      // Set up timeout
      final timer = Timer(const Duration(seconds: 5), () {
        print('[DM Service - Relay] Timeout waiting for response from $relayUrl');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        channel.sink.close();
      });
      
      // Listen for OK response
      channel.stream.listen(
        (message) {
          print('[DM Service - Relay] Received from $relayUrl: $message');
          try {
            final data = jsonDecode(message as String) as List<dynamic>;
            if (data.length >= 3 && data[0] == 'OK' && data[1] == eventData['id']) {
              final success = data[2] as bool;
              print('[DM Service - Relay] Got OK response from $relayUrl: $success');
              if (data.length >= 4) {
                print('[DM Service - Relay] OK message: ${data[3]}');
              }
              if (!completer.isCompleted) {
                completer.complete(success);
              }
              timer.cancel();
              channel.sink.close();
            }
          } catch (e) {
            print('[DM Service - Relay] Error parsing response from $relayUrl: $e');
          }
        },
        onError: (error) {
          print('[DM Service - Relay] Stream error from $relayUrl: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('[DM Service - Relay] Error connecting to $relayUrl: $e');
      return false;
    }
  }

  /// Load conversations from Nostr relays with pagination
  Future<void> loadConversations({bool loadMore = false}) async {
    try {
      _currentUserPubkey = await _keyManagementService.getPublicKey();
      if (_currentUserPubkey == null) {
        print('[DM Service] No user public key available');
        return;
      }

      if (loadMore) {
        _currentPage++;
      } else {
        _currentPage = 0;
        _conversations.clear();
        _messagesByPubkey.clear();
        
        // Load cached conversations first for instant UI
        await _loadCachedConversations();
      }

      // Connect to optimized DM relays
      if (!_dmRelayService.isConnected) {
        print('[DM Service] Connecting to optimized DM relays...');
        await _dmRelayService.connectForDMs();
      }

      // Get timestamp for 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = thirtyDaysAgo.millisecondsSinceEpoch ~/ 1000;

      print('[DM Service] Loading conversations page $_currentPage...');

      // Listen for events from DM relay service
      _dmRelayService.eventsStream.listen((eventData) {
        _handleDirectMessageEvent(eventData);
      });

      // Subscribe to encrypted direct messages (kind 4) with pagination
      final limit = _conversationsPerPage * 2; // Request more to account for duplicates
      final offset = _currentPage * _conversationsPerPage;
      
      _dmRelayService.subscribeToFilter({
        'kinds': [4],
        '#p': [_currentUserPubkey!], // Messages where we are tagged
        'since': thirtyDaysAgoTimestamp, // Only messages from last 30 days
        'limit': limit,
      });

      // Also subscribe to messages we sent
      _dmRelayService.subscribeToFilter({
        'kinds': [4],
        'authors': [_currentUserPubkey!],
        'since': thirtyDaysAgoTimestamp, // Only messages from last 30 days
        'limit': limit,
      });
    } catch (e) {
      print('[DM Service] Error loading conversations: $e');
    }
  }

  /// Handle incoming direct message events
  void _handleDirectMessageEvent(Map<String, dynamic> eventData) async {
    try {
      final event = NostrEvent.fromJson(eventData);
      if (event.kind != 4) return;

      // Get the other party's pubkey
      String otherPubkey;
      bool isFromMe = event.pubkey == _currentUserPubkey;
      
      if (isFromMe) {
        // We sent this message, get recipient from p tag
        final pTag = event.tags.firstWhere(
          (tag) => tag.isNotEmpty && tag[0] == 'p',
          orElse: () => [],
        );
        if (pTag.isEmpty || pTag.length < 2) return;
        otherPubkey = pTag[1];
      } else {
        // We received this message
        otherPubkey = event.pubkey;
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
          print('[DM Service] Error decrypting in background: $e');
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
        senderPubkey: event.pubkey,
        recipientPubkey: isFromMe ? otherPubkey : _currentUserPubkey!,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
        isFromMe: isFromMe,
        isRead: isFromMe, // Messages we sent are already read
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
        
        // Emit the new message
        _messagesController.add(message);
        
        // Update conversation
        await _updateConversation(otherPubkey, message);
        
        // Save to cache
        await _saveMessagesToCache(otherPubkey);
      }
    } catch (e) {
      print('[DM Service] Error handling direct message event: $e');
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

      // Emit updated conversations list
      _conversationsController.add(conversations);
    } catch (e) {
      print('[DM Service] Error updating conversation: $e');
    }
  }

  /// Get messages for a specific pubkey
  Future<List<DirectMessage>> getMessagesForPubkey(String pubkey) async {
    return _messagesByPubkey[pubkey] ?? [];
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

  /// Decrypt a message using NIP-04 specification
  Future<String?> _decryptMessage(String encryptedContent, String privateKey, String publicKey) async {
    try {
      // Parse the encrypted content format: <encrypted>?iv=<iv>
      final parts = encryptedContent.split('?iv=');
      if (parts.length != 2) {
        print('[DM Service] Invalid encrypted content format');
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
      print('[DM Service] Error decrypting message: $e');
      return null;
    }
  }

  void dispose() {
    _messagesController.close();
    _conversationsController.close();
    _dmRelayService.dispose();
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
      print('[DM Service] Loading ${cachedPubkeys.length} cached conversations');
      
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
      print('[DM Service] Error loading cached conversations: $e');
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
      print('[DM Service] Error saving messages to cache: $e');
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