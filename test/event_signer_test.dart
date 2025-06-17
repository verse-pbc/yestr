import 'package:flutter_test/flutter_test.dart';
import 'package:card_swiper_demo/services/event_signer.dart';
import 'package:convert/convert.dart';

void main() {
  group('EventSigner', () {
    test('should create a valid signed event', () {
      // Test private key (DO NOT use in production!)
      // This is a valid secp256k1 private key for testing
      const testPrivateKey = '956fb75b96e36ca125cd6d58fd8d5820e3a49be1fe4d70306e6d7d2948e3809d';
      // Corresponding public key (calculated from the private key)
      const testPublicKey = '4d7f26079104f81b90baefa8a3284bd50b6271b02c05d0ce00f3e4073c059ace';
      
      final event = EventSigner.createSignedEvent(
        privateKeyHex: testPrivateKey,
        publicKeyHex: testPublicKey,
        kind: 1,
        content: 'Hello Nostr!',
        tags: [],
      );
      
      // Verify event structure
      expect(event['id'], isNotNull);
      expect(event['pubkey'], equals(testPublicKey));
      expect(event['created_at'], isA<int>());
      expect(event['kind'], equals(1));
      expect(event['tags'], isEmpty);
      expect(event['content'], equals('Hello Nostr!'));
      expect(event['sig'], isNotNull);
      
      // Verify signature length (64 bytes = 128 hex chars)
      expect(event['sig'].length, equals(128));
      
      // Verify event ID length (32 bytes = 64 hex chars)
      expect(event['id'].length, equals(64));
    });
    
    test('should create a valid contact list event', () {
      const testPrivateKey = '5caa3df61768c178ba5845ff49c9ad6d4d9f019e8269d72169a1aaee9e9cc8f0';
      const testPublicKey = '2c5454e4c0ec708f7552a57c3d9f9b58e37b8e1b3e8ab27f31c017e30a51f6ef';
      
      final followedPubkeys = [
        'pubkey1234567890abcdef',
        'pubkey0987654321fedcba',
      ];
      
      final event = EventSigner.createContactListEvent(
        privateKeyHex: testPrivateKey,
        publicKeyHex: testPublicKey,
        followedPubkeys: followedPubkeys,
      );
      
      // Verify it's a kind 3 event
      expect(event['kind'], equals(3));
      
      // Verify tags contain followed pubkeys
      expect(event['tags'].length, equals(2));
      expect(event['tags'][0], equals(['p', 'pubkey1234567890abcdef']));
      expect(event['tags'][1], equals(['p', 'pubkey0987654321fedcba']));
      
      // Content should be empty for contact lists
      expect(event['content'], equals(''));
    });
    
    test('should create a valid text note event', () {
      const testPrivateKey = '5caa3df61768c178ba5845ff49c9ad6d4d9f019e8269d72169a1aaee9e9cc8f0';
      const testPublicKey = '2c5454e4c0ec708f7552a57c3d9f9b58e37b8e1b3e8ab27f31c017e30a51f6ef';
      
      final event = EventSigner.createTextNoteEvent(
        privateKeyHex: testPrivateKey,
        publicKeyHex: testPublicKey,
        content: 'Testing Nostr implementation!',
        tags: [['t', 'nostr'], ['t', 'test']],
      );
      
      // Verify it's a kind 1 event
      expect(event['kind'], equals(1));
      
      // Verify content
      expect(event['content'], equals('Testing Nostr implementation!'));
      
      // Verify tags
      expect(event['tags'].length, equals(2));
      expect(event['tags'][0], equals(['t', 'nostr']));
      expect(event['tags'][1], equals(['t', 'test']));
    });
    
    test('should verify valid events', () {
      const testPrivateKey = '956fb75b96e36ca125cd6d58fd8d5820e3a49be1fe4d70306e6d7d2948e3809d';
      const testPublicKey = '4d7f26079104f81b90baefa8a3284bd50b6271b02c05d0ce00f3e4073c059ace';
      
      final event = EventSigner.createSignedEvent(
        privateKeyHex: testPrivateKey,
        publicKeyHex: testPublicKey,
        kind: 1,
        content: 'Test event for verification',
        tags: [],
      );
      
      // Event should verify successfully
      final isValid = EventSigner.verifyEvent(event);
      expect(isValid, isTrue);
    });
    
    test('should reject events with invalid signatures', () {
      final invalidEvent = {
        'id': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        'pubkey': '4d7f26079104f81b90baefa8a3284bd50b6271b02c05d0ce00f3e4073c059ace',
        'created_at': 1234567890,
        'kind': 1,
        'tags': [],
        'content': 'Invalid event',
        'sig': 'invalid_signature_1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      };
      
      final isValid = EventSigner.verifyEvent(invalidEvent);
      expect(isValid, isFalse);
    });
  });
}