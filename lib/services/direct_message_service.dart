import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'event_signer.dart';
import 'package:convert/convert.dart';

class DirectMessageService {
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();

  DirectMessageService(this._keyManagementService);

  /// Send a direct message to a recipient using NIP-04 encryption
  Future<bool> sendDirectMessage(String content, NostrProfile recipient) async {
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

      // Combine encrypted data and IV, then base64 encode
      final combined = Uint8List(encrypted.length + iv.length);
      combined.setAll(0, encrypted);
      combined.setAll(encrypted.length, iv);

      final result = '${base64.encode(combined)}?iv=${base64.encode(iv)}';
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
      // Assuming compressed public key (33 bytes) or uncompressed (65 bytes)
      ECPoint? pubPoint;
      if (publicKey.length == 33) {
        // Compressed public key
        pubPoint = curve.curve.decodePoint(publicKey);
      } else if (publicKey.length == 65) {
        // Uncompressed public key
        pubPoint = curve.curve.decodePoint(publicKey);
      } else if (publicKey.length == 32) {
        // Only X coordinate provided, prepend 0x02 for compressed format
        final compressed = Uint8List(33);
        compressed[0] = 0x02;
        compressed.setRange(1, 33, publicKey);
        pubPoint = curve.curve.decodePoint(compressed);
      } else {
        throw Exception('Invalid public key length');
      }

      if (pubPoint == null) {
        throw Exception('Failed to decode public key point');
      }

      // Compute shared secret: private key * public point
      final sharedPoint = pubPoint * d;
      if (sharedPoint == null) {
        throw Exception('Failed to compute shared point');
      }

      // Return X coordinate of shared point as shared secret
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
}