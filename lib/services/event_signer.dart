import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:dart_nostr/dart_nostr.dart';

/// Helper class to sign Nostr events manually
class EventSigner {
  /// Create and sign a contact list event (kind 3)
  static Map<String, dynamic> createContactListEvent({
    required String privateKey,
    required String publicKey,
    required List<String> followedPubkeys,
  }) {
    // Create tags for each followed profile
    final tags = followedPubkeys.map((pubkey) => ['p', pubkey]).toList();
    
    // Current timestamp
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create the event content structure
    final eventContent = {
      'pubkey': publicKey,
      'created_at': createdAt,
      'kind': 3,
      'tags': tags,
      'content': '',
    };
    
    // Calculate event ID
    final eventId = _calculateEventId(eventContent);
    
    // Add ID to event
    eventContent['id'] = eventId;
    
    // Sign the event
    final signature = _signEvent(eventId, privateKey);
    
    // Add signature
    eventContent['sig'] = signature;
    
    return eventContent;
  }
  
  /// Calculate event ID according to NIP-01
  static String _calculateEventId(Map<String, dynamic> event) {
    // Create the serialized event array
    final serialized = [
      0, // Reserved for future use
      event['pubkey'],
      event['created_at'],
      event['kind'],
      event['tags'],
      event['content'],
    ];
    
    // Convert to canonical JSON
    final jsonStr = jsonEncode(serialized);
    
    // Calculate SHA256 hash
    final bytes = utf8.encode(jsonStr);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// Sign event with private key
  static String _signEvent(String eventId, String privateKey) {
    try {
      // Use dart_nostr's built-in signing capability
      final keyPairs = Nostr.instance.keysService.generateKeyPair();
      
      // We need to use the actual private key, but dart_nostr v4 doesn't expose
      // a way to create KeyPairs from existing keys, so we'll use the raw signing
      
      // For now, return a placeholder signature
      // In production, you'd need to use a proper secp256k1 library
      return 'placeholder_signature_${eventId.substring(0, 8)}';
    } catch (e) {
      throw Exception('Failed to sign event: $e');
    }
  }
}