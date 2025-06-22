# NDK Migration Plan for Yestr

## Executive Summary

This document outlines a comprehensive plan for migrating the Yestr application from `dart_nostr` (v4.0.0) to `ndk` (v0.4.0). The migration will provide several benefits including built-in NIP-44 encryption, NIP-59 gift wrap support, automatic relay discovery, and better caching mechanisms.

## Current State Analysis

### Dependencies
- **Current**: `dart_nostr: ^4.0.0`
- **Target**: `ndk: ^0.4.0`

### dart_nostr Usage in Codebase

The application currently uses `dart_nostr` in three main areas:

1. **Key Management** (`lib/services/key_management_service.dart`)
   - Uses `Nostr.instance.keysService.derivePublicKey()` for public key derivation

2. **Event Handling** (`lib/services/nostr_service.dart`)
   - Imports as `import 'package:dart_nostr/dart_nostr.dart' as nostr;`
   - Limited usage visible in current implementation

3. **Follow Service** (`lib/services/follow_service.dart`)
   - Imports dart_nostr but minimal direct usage

### Custom Implementations
- **NIP-04 encryption**: Custom implementation in `direct_message_service.dart`
- **NIP-17/NIP-44**: Custom implementation in `nip17_dm_service.dart`
- **Event signing**: Custom implementation in `event_signer.dart`
- **Relay management**: Custom implementation in `relay_pool.dart`

## Migration Benefits

1. **Built-in NIP-44 and NIP-59 Support**
   - Replace custom `nip17_dm_service.dart` with NDK's gift wrap functionality
   - More secure and maintained encryption implementation

2. **Automatic Relay Discovery**
   - NDK includes outbox model support
   - Better relay selection based on user preferences

3. **Improved Caching**
   - Built-in response caching
   - Pluggable cache interface

4. **Better Event Management**
   - Simplified event filtering and subscription management
   - Automatic deduplication

5. **Future-Proofing**
   - Active development and maintenance
   - Support for upcoming NIPs

## Migration Strategy

### Phase 1: Preparation (1-2 days)

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/ndk-migration
   ```

2. **Add NDK Dependency**
   ```yaml
   dependencies:
     ndk: ^0.4.0
     # Keep dart_nostr temporarily for gradual migration
     dart_nostr: ^4.0.0
   ```

3. **Create Compatibility Layer**
   - Create `lib/services/ndk_adapter.dart` to wrap NDK functionality
   - Implement interfaces matching current service contracts

### Phase 2: Key Management Migration (1 day)

1. **Update KeyManagementService**
   ```dart
   // OLD: dart_nostr
   final publicKey = Nostr.instance.keysService.derivePublicKey(
     privateKey: hexPrivateKey,
   );
   
   // NEW: NDK
   import 'package:ndk/ndk.dart';
   final keyPair = NDKKeyPair.fromPrivateKey(hexPrivateKey);
   final publicKey = keyPair.publicKey;
   ```

2. **Test Key Operations**
   - Verify key derivation produces same results
   - Test nsec/npub conversion
   - Ensure backward compatibility

### Phase 3: Event Handling Migration (2-3 days)

1. **Replace NostrService Core**
   - Initialize NDK instance
   - Configure relay pool
   - Set up event subscriptions

2. **NDK Initialization Example**
   ```dart
   class NostrServiceNDK {
     late final NDK _ndk;
     
     Future<void> initialize() async {
       _ndk = NDK();
       
       // Configure relays
       _ndk.relays = [
         'wss://relay.yestr.social',
         'wss://relay.damus.io',
         'wss://relay.primal.net',
         // ... other relays
       ];
       
       // Connect
       await _ndk.connect();
     }
   }
   ```

3. **Update Event Subscriptions**
   ```dart
   // OLD: Manual WebSocket handling
   _channel!.stream.listen(_handleMessage);
   
   // NEW: NDK subscriptions
   final subscription = _ndk.query(
     filters: [
       NDKFilter(kinds: [0], limit: 100),
     ],
   ).stream.listen((event) {
     // Handle event
   });
   ```

### Phase 4: Direct Message Migration (2 days)

1. **Replace Custom Encryption**
   - Remove `nip17_dm_service.dart`
   - Remove custom NIP-44 implementation
   - Use NDK's gift wrap functionality

2. **NDK Gift Wrap Usage**
   ```dart
   // Create rumor
   final rumor = _ndk.giftWrap.createRumor(
     kind: 14,
     content: message,
     tags: [['p', recipientPubkey]],
   );
   
   // Wrap for recipient
   final giftWrap = await _ndk.giftWrap.toGiftWrap(
     rumor: rumor,
     recipientPubkey: recipientPubkey,
   );
   
   // Publish
   await _ndk.publish(giftWrap);
   ```

### Phase 5: Follow Service Migration (1 day)

1. **Update Contact List Management**
   - Use NDK's NIP-02 support
   - Migrate to NDK's list management

2. **Example Implementation**
   ```dart
   // Get user's contact list
   final contacts = await _ndk.getUserContacts(userPubkey);
   
   // Add follow
   await _ndk.addContact(pubkeyToFollow);
   ```

### Phase 6: Testing and Validation (2-3 days)

1. **Unit Tests**
   - Update all service tests
   - Verify encryption/decryption
   - Test relay connectivity

2. **Integration Tests**
   - Test profile discovery
   - Test direct messages
   - Test follow/unfollow
   - Test saved profiles

3. **Performance Testing**
   - Compare relay connection times
   - Measure event processing speed
   - Check memory usage

### Phase 7: Cleanup and Optimization (1 day)

1. **Remove dart_nostr**
   - Remove dependency from pubspec.yaml
   - Delete custom implementations replaced by NDK
   - Clean up unused imports

2. **Optimize NDK Usage**
   - Configure caching
   - Set up relay preferences
   - Implement error handling

## Impact Analysis

### Services to Modify

1. **High Impact**
   - `nostr_service.dart` - Complete rewrite
   - `direct_message_service.dart` - Replace with NDK
   - `nip17_dm_service.dart` - Delete (use NDK)
   - `key_management_service.dart` - Update key derivation

2. **Medium Impact**
   - `follow_service.dart` - Update to use NDK lists
   - `saved_profiles_service.dart` - Update event handling
   - `relay_pool.dart` - Potentially remove (NDK handles this)

3. **Low Impact**
   - `event_signer.dart` - May keep for custom signing
   - UI components - Should work unchanged

### Breaking Changes

1. **Event Structure**
   - NDK may use different event models
   - Need to update model mappings

2. **Subscription Management**
   - Different API for creating/managing subscriptions
   - May need to update stream handling

3. **Error Handling**
   - NDK has different error types
   - Update error handling logic

## Risk Mitigation

1. **Gradual Migration**
   - Keep both libraries during migration
   - Use feature flags to switch between implementations

2. **Comprehensive Testing**
   - Test each phase thoroughly
   - Have rollback plan for each phase

3. **Data Compatibility**
   - Ensure events created by NDK are compatible
   - Test with other Nostr clients

## Timeline

- **Total Estimated Time**: 10-14 days
- **Critical Path**: Event handling and DM migration
- **Parallelizable**: Testing can overlap with later phases

## Post-Migration Benefits

1. **Reduced Code Maintenance**
   - Remove ~500 lines of custom encryption code
   - Remove custom relay management

2. **Better Performance**
   - NDK's optimized relay selection
   - Built-in caching

3. **Future Features**
   - Easy to add NIP-47 wallet support
   - Built-in zap functionality
   - Better list management

## Rollback Plan

If migration fails:
1. Keep git history clean with atomic commits
2. Maintain feature flags for easy switching
3. Keep dart_nostr functional until fully migrated
4. Have database backups before migration

## Success Criteria

1. All existing features work as before
2. DMs are properly encrypted with NIP-44
3. Performance is equal or better
4. No data loss during migration
5. Code is cleaner and more maintainable

## Resources

- [NDK Documentation](https://pub.dev/packages/ndk)
- [NDK Examples](https://github.com/example-apps)
- [Migration Support](https://github.com/ndk/issues)

## Notes for Implementation

1. Start with a proof of concept in a separate branch
2. Keep detailed logs of API differences discovered
3. Document any workarounds needed
4. Consider contributing improvements back to NDK
5. Plan for a beta testing period with limited users

---

*This migration plan should be reviewed and updated as the implementation progresses. Each phase should be completed and tested before moving to the next.*