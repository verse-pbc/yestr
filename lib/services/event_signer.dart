import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:bip340/bip340.dart' as bip340;

/// Helper class to sign Nostr events according to NIP-01
class EventSigner {
  
  /// Create and sign an event according to NIP-01
  static Map<String, dynamic> createSignedEvent({
    required String privateKeyHex,
    required String publicKeyHex,
    required int kind,
    required String content,
    required List<List<String>> tags,
  }) {
    // Current timestamp
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create the event structure (without id and sig)
    final eventForId = [
      0, // Reserved for future use
      publicKeyHex,
      createdAt,
      kind,
      tags,
      content,
    ];
    
    // Calculate event ID (sha256 hash of the serialized event)
    final eventId = _calculateEventId(eventForId);
    
    // Sign the event ID
    final signature = _signEventId(eventId, privateKeyHex);
    
    // Return complete event
    return {
      'id': eventId,
      'pubkey': publicKeyHex,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': signature,
    };
  }
  
  /// Create and sign a contact list event (kind 3)
  static Map<String, dynamic> createContactListEvent({
    required String privateKeyHex,
    required String publicKeyHex,
    required List<String> followedPubkeys,
  }) {
    // Create tags for each followed profile
    final tags = followedPubkeys.map((pubkey) => ['p', pubkey]).toList();
    
    return createSignedEvent(
      privateKeyHex: privateKeyHex,
      publicKeyHex: publicKeyHex,
      kind: 3,
      content: '',
      tags: tags,
    );
  }
  
  /// Create and sign a text note event (kind 1)
  static Map<String, dynamic> createTextNoteEvent({
    required String privateKeyHex,
    required String publicKeyHex,
    required String content,
    List<List<String>> tags = const [],
  }) {
    return createSignedEvent(
      privateKeyHex: privateKeyHex,
      publicKeyHex: publicKeyHex,
      kind: 1,
      content: content,
      tags: tags,
    );
  }
  
  /// Calculate event ID according to NIP-01
  static String _calculateEventId(List<dynamic> eventForId) {
    // Serialize to canonical JSON (no spaces)
    final jsonStr = jsonEncode(eventForId);
    
    // Calculate SHA256 hash
    final bytes = utf8.encode(jsonStr);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// Sign event ID with private key using bip340 Schnorr signatures
  static String _signEventId(String eventId, String privateKeyHex) {
    try {
      // Generate random auxiliary data (32 bytes as hex)
      final random = Random.secure();
      final randomBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final aux = hex.encode(randomBytes);
      
      // Sign using BIP340 Schnorr signatures
      final signature = bip340.sign(privateKeyHex, eventId, aux);
      return signature;
    } catch (e) {
      throw Exception('Failed to sign event: $e');
    }
  }
  
  /// Verify an event signature
  static bool verifyEvent(Map<String, dynamic> event) {
    try {
      // Recreate the event for ID calculation
      final eventForId = [
        0,
        event['pubkey'],
        event['created_at'],
        event['kind'],
        event['tags'],
        event['content'],
      ];
      
      // Calculate expected ID
      final calculatedId = _calculateEventId(eventForId);
      
      // Verify ID matches
      if (calculatedId != event['id']) {
        return false;
      }
      
      // Verify signature using BIP340
      return bip340.verify(event['pubkey'], event['id'], event['sig']);
    } catch (e) {
      return false;
    }
  }
}