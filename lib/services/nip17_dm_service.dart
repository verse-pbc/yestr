import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:crypto/crypto.dart' as crypto;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'event_signer.dart';
import 'package:convert/convert.dart';

/// NIP-17 Private Direct Messages implementation
/// Uses NIP-44 encryption (ChaCha20-Poly1305) with gift wrapping
class Nip17DmService {
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();

  Nip17DmService(this._keyManagementService);

  /// Send a private direct message using NIP-17
  Future<bool> sendDirectMessage(String content, NostrProfile recipient) async {
    print('[NIP-17 DM] Starting sendDirectMessage...');
    print('[NIP-17 DM] Content: "$content"');
    print('[NIP-17 DM] Recipient: ${recipient.displayNameOrName} (${recipient.pubkey})');
    
    try {
      // Check if user is logged in
      final hasPrivateKey = await _keyManagementService.hasPrivateKey();
      if (!hasPrivateKey) {
        throw Exception('You must be logged in to send messages');
      }

      // Get sender's keys
      final senderPrivateKey = await _keyManagementService.getPrivateKey();
      final senderPublicKey = await _keyManagementService.getPublicKey();
      if (senderPrivateKey == null || senderPublicKey == null) {
        throw Exception('Unable to get sender keys');
      }

      // Step 1: Create the rumor (unsigned chat message)
      print('[NIP-17 DM] Creating rumor event...');
      final rumor = _createRumor(content, recipient.pubkey, senderPublicKey);
      
      // Step 2: Create and sign the seal (kind 13)
      print('[NIP-17 DM] Creating sealed event...');
      final seal = await _createSeal(rumor, recipient.pubkey, senderPrivateKey, senderPublicKey);
      
      // Step 3: Create the gift wrap (kind 1059)
      print('[NIP-17 DM] Creating gift wrap...');
      final giftWrap = await _createGiftWrap(seal, recipient.pubkey);
      
      // Publish the gift wrap to relays
      final relays = [
        'wss://relay.damus.io',
        'wss://relay.primal.net',
        'wss://nos.lol',
        'wss://relay.nostr.band',
        'wss://relay.yestr.social',
      ];
      
      bool publishedToAnyRelay = false;
      print('[NIP-17 DM] Publishing to ${relays.length} relays...');
      
      for (final relay in relays) {
        try {
          print('[NIP-17 DM] Publishing to $relay...');
          final success = await _publishToRelay(relay, giftWrap);
          if (success) {
            publishedToAnyRelay = true;
            print('[NIP-17 DM] ✓ Successfully published to $relay');
          } else {
            print('[NIP-17 DM] ✗ Failed to publish to $relay');
          }
        } catch (e) {
          print('[NIP-17 DM] ✗ Error publishing to $relay: $e');
        }
      }

      print('[NIP-17 DM] Published to any relay: $publishedToAnyRelay');
      return publishedToAnyRelay;
    } catch (e) {
      print('[NIP-17 DM] ERROR in sendDirectMessage: $e');
      print('[NIP-17 DM] Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Create a rumor event (unsigned kind 14 chat message)
  Map<String, dynamic> _createRumor(String content, String recipientPubkey, String senderPubkey) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return {
      'pubkey': senderPubkey,
      'created_at': now,
      'kind': 14, // Chat message
      'tags': [
        ['p', recipientPubkey],
      ],
      'content': content,
    };
  }

  /// Create a sealed event (kind 13) containing the encrypted rumor
  Future<Map<String, dynamic>> _createSeal(
    Map<String, dynamic> rumor,
    String recipientPubkey,
    String senderPrivateKey,
    String senderPublicKey,
  ) async {
    // Serialize and encrypt the rumor using NIP-44
    final rumorJson = jsonEncode(rumor);
    final encryptedRumor = await _encryptNip44(rumorJson, senderPrivateKey, recipientPubkey);
    
    // Create the seal event
    final sealEvent = EventSigner.createSignedEvent(
      privateKeyHex: senderPrivateKey,
      publicKeyHex: senderPublicKey,
      kind: 13, // Seal
      tags: [],
      content: encryptedRumor,
    );
    
    return sealEvent;
  }

  /// Create a gift wrap (kind 1059) containing the encrypted seal
  Future<Map<String, dynamic>> _createGiftWrap(
    Map<String, dynamic> seal,
    String recipientPubkey,
  ) async {
    // Generate ephemeral keys for the gift wrap
    final randomPrivateKey = _generateRandomPrivateKey();
    final randomPublicKey = _getPublicKey(randomPrivateKey);
    
    // Randomize created_at within 2 days in the past
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final randomOffset = Random().nextInt(172800); // 2 days in seconds
    final randomCreatedAt = twoDaysAgo.millisecondsSinceEpoch ~/ 1000 + randomOffset;
    
    // Encrypt the seal using NIP-44
    final sealJson = jsonEncode(seal);
    final encryptedSeal = await _encryptNip44(sealJson, randomPrivateKey, recipientPubkey);
    
    // Create gift wrap event manually to control created_at
    final giftWrapData = {
      'pubkey': randomPublicKey,
      'created_at': randomCreatedAt,
      'kind': 1059, // Gift wrap
      'tags': [
        ['p', recipientPubkey],
      ],
      'content': encryptedSeal,
    };
    
    // Sign the gift wrap event using EventSigner static method
    final giftWrapEvent = EventSigner.createSignedEvent(
      privateKeyHex: randomPrivateKey,
      publicKeyHex: randomPublicKey,
      kind: 1059,
      content: encryptedSeal,
      tags: [
        ['p', recipientPubkey],
      ],
    );
    
    return giftWrapEvent;
  }

  /// Encrypt using NIP-44 (ChaCha20-Poly1305)
  Future<String> _encryptNip44(String plaintext, String senderPrivkey, String recipientPubkey) async {
    try {
      // Convert keys to bytes
      final privateKeyBytes = Uint8List.fromList(hex.decode(senderPrivkey));
      final publicKeyBytes = Uint8List.fromList(hex.decode(recipientPubkey));
      
      // Compute shared secret using ECDH
      final sharedSecret = _computeSharedSecret(privateKeyBytes, publicKeyBytes);
      
      // Derive conversation key using HKDF
      final conversationKey = await _deriveConversationKey(sharedSecret);
      
      // Generate random nonce (12 bytes for ChaCha20)
      final nonce = _generateRandomBytes(12);
      
      // Pad the message according to NIP-44
      final paddedMessage = _padMessage(plaintext);
      
      // Encrypt using ChaCha20-Poly1305
      final algorithm = Chacha20.poly1305Aead();
      final secretKey = SecretKey(conversationKey);
      final secretBox = await algorithm.encrypt(
        paddedMessage,
        secretKey: secretKey,
        nonce: nonce,
      );
      
      // Create NIP-44 v2 payload
      final payload = Uint8List(1 + nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length);
      payload[0] = 0x02; // Version 2
      payload.setAll(1, nonce);
      payload.setAll(1 + nonce.length, secretBox.cipherText);
      payload.setAll(1 + nonce.length + secretBox.cipherText.length, secretBox.mac.bytes);
      
      return base64.encode(payload);
    } catch (e) {
      print('[NIP-17 DM] Encryption error: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Derive conversation key using HKDF-SHA256
  Future<List<int>> _deriveConversationKey(Uint8List sharedSecret) async {
    final hkdf = Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    );
    
    final secretKey = SecretKey(sharedSecret);
    final derivedKey = await hkdf.deriveKey(
      secretKey: secretKey,
      info: utf8.encode('nip44-v2'),
      nonce: utf8.encode('nip44-v2'), // Using info as salt as per NIP-44
    );
    
    return await derivedKey.extractBytes();
  }

  /// Pad message according to NIP-44 specification
  Uint8List _padMessage(String message) {
    final messageBytes = utf8.encode(message);
    final messageLength = messageBytes.length;
    
    // Calculate padded length (minimum 32 bytes, then powers of 2)
    int paddedLength = 32;
    while (paddedLength < messageLength + 2) {
      paddedLength *= 2;
    }
    
    // Ensure we don't exceed maximum size
    if (paddedLength > 65535) {
      throw Exception('Message too long');
    }
    
    // Create padded buffer with 2-byte length prefix
    final padded = Uint8List(paddedLength);
    padded[0] = (messageLength >> 8) & 0xFF;
    padded[1] = messageLength & 0xFF;
    padded.setRange(2, 2 + messageLength, messageBytes);
    
    // Fill remaining with zeros (already initialized to 0)
    return padded;
  }

  /// Compute ECDH shared secret (same as NIP-04 but for NIP-44)
  Uint8List _computeSharedSecret(Uint8List privateKey, Uint8List publicKey) {
    try {
      // secp256k1 curve parameters
      final curve = pc.ECCurve_secp256k1();
      final domainParams = pc.ECDomainParametersImpl('secp256k1', curve.curve, curve.G, curve.n, curve.h, curve.seed);

      // Create private key parameter
      final d = BigInt.parse(hex.encode(privateKey), radix: 16);
      final privKey = pc.ECPrivateKey(d, domainParams);

      // Create public key point
      pc.ECPoint? pubPoint;
      if (publicKey.length == 32) {
        // Nostr public key - just X coordinate
        final compressed = Uint8List(33);
        compressed[0] = 0x02; // Assume even Y coordinate
        compressed.setRange(1, 33, publicKey);
        pubPoint = curve.curve.decodePoint(compressed);
      } else if (publicKey.length == 33) {
        // Already compressed
        pubPoint = curve.curve.decodePoint(publicKey);
      } else {
        throw Exception('Invalid public key length: ${publicKey.length}');
      }

      if (pubPoint == null) {
        throw Exception('Failed to decode public key point');
      }

      // Compute shared point
      final sharedPoint = pubPoint * d;
      if (sharedPoint == null) {
        throw Exception('Failed to compute shared point');
      }

      // Return X coordinate of shared point
      final sharedX = sharedPoint.x!.toBigInteger()!;
      return _bigIntToBytes(sharedX, 32);
    } catch (e) {
      print('[NIP-17 DM] Error computing shared secret: $e');
      throw Exception('Failed to compute shared secret: $e');
    }
  }

  /// Convert BigInt to fixed-length byte array
  Uint8List _bigIntToBytes(BigInt value, int length) {
    final bytes = Uint8List(length);
    var hexStr = value.toRadixString(16);
    if (hexStr.length % 2 != 0) {
      hexStr = '0$hexStr';
    }
    final valueBytes = Uint8List.fromList(hex.decode(hexStr));
    
    final offset = length - valueBytes.length;
    bytes.setRange(offset, length, valueBytes);
    return bytes;
  }

  /// Generate random private key
  String _generateRandomPrivateKey() {
    final random = Random.secure();
    final privateKeyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      privateKeyBytes[i] = random.nextInt(256);
    }
    return hex.encode(privateKeyBytes);
  }

  /// Get public key from private key
  String _getPublicKey(String privateKeyHex) {
    final privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
    
    // secp256k1 curve parameters
    final curve = pc.ECCurve_secp256k1();
    final domainParams = pc.ECDomainParametersImpl('secp256k1', curve.curve, curve.G, curve.n, curve.h, curve.seed);
    
    // Create private key
    final d = BigInt.parse(privateKeyHex, radix: 16);
    final privKey = pc.ECPrivateKey(d, domainParams);
    
    // Calculate public key point
    final pubPoint = curve.G * d;
    if (pubPoint == null) {
      throw Exception('Failed to compute public key');
    }
    
    // Return X coordinate only (Nostr format)
    final pubX = pubPoint.x!.toBigInteger()!;
    return hex.encode(_bigIntToBytes(pubX, 32));
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Publish event to a specific relay
  Future<bool> _publishToRelay(String relayUrl, Map<String, dynamic> eventData) async {
    print('[NIP-17 DM - Relay] Connecting to $relayUrl...');
    final completer = Completer<bool>();
    
    try {
      final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      
      // Send event
      final message = ["EVENT", eventData];
      final messageJson = jsonEncode(message);
      print('[NIP-17 DM - Relay] Sending EVENT to $relayUrl');
      channel.sink.add(messageJson);
      
      // Set up timeout
      final timer = Timer(const Duration(seconds: 5), () {
        print('[NIP-17 DM - Relay] Timeout waiting for response from $relayUrl');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        channel.sink.close();
      });
      
      // Listen for OK response
      channel.stream.listen(
        (message) {
          print('[NIP-17 DM - Relay] Received from $relayUrl: $message');
          try {
            final data = jsonDecode(message as String) as List<dynamic>;
            if (data.length >= 3 && data[0] == 'OK' && data[1] == eventData['id']) {
              final success = data[2] as bool;
              print('[NIP-17 DM - Relay] Got OK response from $relayUrl: $success');
              if (data.length >= 4) {
                print('[NIP-17 DM - Relay] OK message: ${data[3]}');
              }
              if (!completer.isCompleted) {
                completer.complete(success);
              }
              timer.cancel();
              channel.sink.close();
            }
          } catch (e) {
            print('[NIP-17 DM - Relay] Error parsing response from $relayUrl: $e');
          }
        },
        onError: (error) {
          print('[NIP-17 DM - Relay] Stream error from $relayUrl: $error');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('[NIP-17 DM - Relay] Error connecting to $relayUrl: $e');
      return false;
    }
  }
}