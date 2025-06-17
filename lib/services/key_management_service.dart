import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bech32/bech32.dart';

class KeyManagementService {
  static const String _privateKeyKey = 'nostr_private_key';
  static const String _publicKeyKey = 'nostr_public_key';

  // Singleton pattern
  static final KeyManagementService _instance = KeyManagementService._internal();
  factory KeyManagementService() => _instance;
  KeyManagementService._internal();

  /// Check if a private key is stored
  Future<bool> hasPrivateKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privateKey = prefs.getString(_privateKeyKey);
      return privateKey != null && privateKey.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for private key: $e');
      }
      return false;
    }
  }

  /// Get the stored public key
  Future<String?> getPublicKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_publicKeyKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting public key: $e');
      }
      return null;
    }
  }

  /// Get the stored private key (hex format)
  Future<String?> getPrivateKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_privateKeyKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting private key: $e');
      }
      return null;
    }
  }

  /// Check if a string is a valid private key
  bool isValidPrivateKey(String key) {
    if (key.isEmpty) return false;
    
    try {
      if (key.trim().startsWith('nsec')) {
        // Validate nsec format
        final decoded = _decodeNsec(key.trim());
        return decoded != null && decoded.length == 64;
      } else {
        // Validate hex format (64 hex characters)
        final hex = key.trim();
        return hex.length == 64 && 
               RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex);
      }
    } catch (e) {
      return false;
    }
  }

  /// Store a private key securely
  /// Handles both nsec and hex formats
  Future<void> storePrivateKey(String privateKey) async {
    try {
      String hexPrivateKey;
      
      // Check if it's an nsec key and decode it
      if (privateKey.trim().startsWith('nsec')) {
        final decoded = _decodeNsec(privateKey.trim());
        if (decoded == null) {
          throw Exception('Invalid nsec format');
        }
        hexPrivateKey = decoded;
        
        if (kDebugMode) {
          print('Decoded nsec to hex: ${hexPrivateKey.substring(0, 8)}...');
        }
      } else {
        // Assume it's already hex
        hexPrivateKey = privateKey.trim();
        
        // Validate hex format
        if (!isValidPrivateKey(hexPrivateKey)) {
          throw Exception('Invalid private key format');
        }
      }
      
      // Generate public key from private key
      final publicKey = Nostr.instance.keysService.derivePublicKey(
        privateKey: hexPrivateKey,
      );
      
      // Store both keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_privateKeyKey, hexPrivateKey);
      await prefs.setString(_publicKeyKey, publicKey);
      
      if (kDebugMode) {
        print('Stored private and public keys');
        print('Public key: $publicKey');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error storing private key: $e');
      }
      throw Exception('Invalid private key format: ${e.toString()}');
    }
  }

  /// Clear stored keys (logout)
  Future<void> clearKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_privateKeyKey);
      await prefs.remove(_publicKeyKey);
      
      if (kDebugMode) {
        print('Cleared stored keys');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing keys: $e');
      }
    }
  }

  /// Get stored keys for manual event signing
  Future<Map<String, String>?> getKeys() async {
    try {
      final privateKey = await getPrivateKey();
      final publicKey = await getPublicKey();
      
      if (privateKey == null || publicKey == null) return null;
      
      return {
        'private': privateKey,
        'public': publicKey,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting keys: $e');
      }
      return null;
    }
  }

  /// Decode nsec to hex private key
  String? _decodeNsec(String nsec) {
    try {
      // Use bech32 package directly
      final bech32codec = const Bech32Codec();
      final decoded = bech32codec.decode(nsec);
      
      // Convert 5-bit groups to 8-bit bytes
      final fromWords = _convertBits(decoded.data, 5, 8, false);
      if (fromWords == null) return null;
      
      // Convert bytes to hex
      return fromWords.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding nsec: $e');
      }
      return null;
    }
  }
  
  /// Convert between bit groups
  List<int>? _convertBits(List<int> data, int fromBits, int toBits, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxV = (1 << toBits) - 1;

    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        return null;
      }
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxV);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxV);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxV) != 0) {
      return null;
    }

    return result;
  }
}