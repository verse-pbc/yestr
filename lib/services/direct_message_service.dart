import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:crypto/crypto.dart';
import '../models/nostr_profile.dart';
import '../models/nostr_event.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';
import 'package:convert/convert.dart';

class DirectMessageService {
  final KeyManagementService _keyManagementService;
  final NostrService _nostrService = NostrService();

  DirectMessageService(this._keyManagementService);

  /// Send a direct message to a recipient using NIP-04 encryption
  Future<bool> sendDirectMessage(String content, NostrProfile recipient) async {
    try {
      // Check if user is logged in
      final hasPrivateKey = await _keyManagementService.hasPrivateKey();
      if (!hasPrivateKey) {
        throw Exception('You must be logged in to send messages');
      }

      // Get sender's keys
      final privateKey = await _keyManagementService.getPrivateKey();
      final publicKey = await _keyManagementService.getPublicKey();
      if (privateKey == null || publicKey == null) {
        throw Exception('Unable to get sender keys');
      }

      // Encrypt the message content using NIP-04
      final encryptedContent = await _encryptMessage(content, privateKey, recipient.pubkey);

      // Create tags for the direct message
      final List<List<String>> tags = [
        ['p', recipient.pubkey],
      ];

      // Create event data with signature
      final eventData = await _createSignedEvent(
        publicKey: publicKey,
        privateKey: privateKey,
        kind: 4, // Kind 4 is for encrypted direct messages
        tags: tags,
        content: encryptedContent,
      );

      // Publish the event
      final results = await _nostrService.publishEvent(eventData);
      final success = results.values.any((v) => v);

      return success;
    } catch (e) {
      print('Error sending direct message: $e');
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
      final seedSource = Uint8List.fromList(
        List.generate(32, (i) => DateTime.now().millisecondsSinceEpoch & 0xff),
      );
      secureRandom.seed(KeyParameter(seedSource));
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

  /// Create a signed Nostr event
  Future<Map<String, dynamic>> _createSignedEvent({
    required String publicKey,
    required String privateKey,
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create event ID
    final eventData = [
      0,
      publicKey,
      createdAt,
      kind,
      tags,
      content,
    ];
    
    final serialized = jsonEncode(eventData);
    final bytes = utf8.encode(serialized);
    final hash = sha256.convert(bytes);
    final id = hex.encode(hash.bytes);
    
    // Sign the event
    final signature = await _signMessage(id, privateKey);
    
    return {
      'id': id,
      'pubkey': publicKey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': signature,
    };
  }

  /// Sign a message using secp256k1
  Future<String> _signMessage(String message, String privateKey) async {
    try {
      final privateKeyBytes = Uint8List.fromList(hex.decode(privateKey));
      final messageBytes = Uint8List.fromList(hex.decode(message));
      
      // secp256k1 curve parameters
      final curve = ECCurve_secp256k1();
      final domainParams = ECDomainParametersImpl('secp256k1', curve.curve, curve.G, curve.n, curve.h, curve.seed);
      
      // Create private key
      final d = BigInt.parse(privateKey, radix: 16);
      final privKey = ECPrivateKey(d, domainParams);
      
      // Sign the message
      final signer = ECDSASigner(SHA256Digest());
      signer.init(true, PrivateKeyParameter(privKey));
      
      final signature = signer.generateSignature(messageBytes) as ECSignature;
      
      // Convert signature to DER format
      final r = signature.r;
      final s = signature.s;
      
      // Encode r and s as fixed 32-byte values and concatenate
      final rBytes = _bigIntToBytes(r, 32);
      final sBytes = _bigIntToBytes(s, 32);
      
      final sigBytes = Uint8List(64);
      sigBytes.setAll(0, rBytes);
      sigBytes.setAll(32, sBytes);
      
      return hex.encode(sigBytes);
    } catch (e) {
      print('Error signing message: $e');
      throw Exception('Failed to sign message: $e');
    }
  }
}