# NDK Yestr Migration Plan

## Overview

This document outlines the migration plan for transitioning the Yestr application from its current Nostr implementation (using dart_nostr and custom implementations) to the NDK (Nostr Development Kit) library. The primary goals are to:

1. Leverage NDK's outbox model for efficient relay management
2. Improve performance and reduce bandwidth usage
3. Standardize on a well-maintained Nostr protocol implementation
4. Enhance privacy and reliability of relay connections

## Architecture Overview

### Current Architecture
```
UI Layer
    ↓
Services (NostrService, DirectMessageService, etc.)
    ↓
dart_nostr + Custom Implementations
    ↓
WebSocket Connections to Fixed Relay Set
```

### Target Architecture with NDK
```
UI Layer
    ↓
Service Adapters (minimal changes to existing API)
    ↓
NDK (with JIT Engine and Outbox Model)
    ↓
Dynamic Relay Connections based on User Relay Lists
```

## Key Benefits of Migration

### 1. Outbox Model Implementation
- **Current**: Connects to all relays for all operations
- **With NDK**: Connects only to relevant relays based on:
  - Authors' write relays for reading their events
  - Your write relays for publishing
  - Recipients' read relays for sending them messages
  - Automatic relay discovery via NIP-65 relay lists

### 2. Performance Improvements
- Reduced bandwidth usage
- Better battery life on mobile
- Faster message delivery to correct relays
- Smart caching with configurable backends

### 3. Protocol Compliance
- Proper implementation of all NIPs
- Regular updates to support new protocol features
- Battle-tested implementations

## Migration Components

### 1. Core Services Migration

#### NostrService → Ndk
**Current Functionality:**
- Relay connections management
- Profile fetching
- Event publishing
- Subscription management

**Migration Steps:**
```dart
// Before
class NostrService {
  final RelayPool _relayPool = RelayPool();
  // ... custom implementation
}

// After
class NostrService {
  late final Ndk ndk;
  
  Future<void> initialize() async {
    ndk = Ndk(
      NdkConfig(
        engine: NdkEngine.JIT, // Enable outbox model
        cache: MemCacheManager(), // Or database cache
        logLevel: NdkLogLevel.info,
      ),
    );
    await ndk.connect();
  }
}
```

#### EventSigner → NDK's EventSigner
**Current**: Custom BIP340 implementation
**After**: Use NDK's `Bip340EventSigner`

```dart
// Initialize signer
final signer = Bip340EventSigner(
  privateKey: userPrivateKey,
  publicKey: userPublicKey,
);
ndk.setSigner(signer);
```

### 2. Direct Messages Migration

#### NIP-04 Messages (Legacy)
**Current**: Custom AES-CBC implementation
**After**: Use NDK's built-in NIP-04 support

```dart
// Decrypt message
final decrypted = await signer.decrypt(
  encryptedContent,
  senderPubkey,
  nip: 04,
);
```

#### NIP-17/NIP-59 Messages (Modern)
**Current**: Custom implementation with gift wrapping
**After**: Use NDK's GiftWrap use case

```dart
// Send gift-wrapped message
final response = await ndk.giftWrap.publish(
  receiverPubkey: recipientPubkey,
  content: messageContent,
  kind: 14, // Chat message
);
```

### 3. Profile Management

**Current**: Manual fetching and caching
**After**: Use NDK's Metadata use case

```dart
// Fetch profile
final metadata = await ndk.metadata.loadMetadata(pubkey);

// Batch load profiles
final profiles = await ndk.metadata.loadMetadatas(pubkeys);

// Search profiles
final results = await ndk.metadata.searchMetadatas(
  search: "yestr",
  limit: 50,
);
```

### 4. Contact Lists (Following)

**Current**: Custom kind 3 event handling
**After**: Use NDK's Follows use case

```dart
// Get user's follows
final contactList = await ndk.follows.getContactList(userPubkey);

// Follow someone
await ndk.follows.follow(
  targetPubkey,
  relayUrls: targetRelays, // Optional relay recommendations
);
```

### 5. Relay Management with Outbox Model

#### Publishing Events
```dart
// NDK automatically publishes to your write relays
final response = await ndk.broadcast.broadcast(
  nostrEvent: event,
  specificRelays: [], // Optional, otherwise uses outbox model
);
```

#### Subscribing to Events
```dart
// NDK automatically connects to authors' write relays
final response = ndk.requests.query(
  filters: [
    Filter(
      authors: [authorPubkey],
      kinds: [1], // Text notes
    ),
  ],
);

// Listen to events
response.stream.listen((event) {
  // Process event
});
```

### 6. Implementation Phases

#### Phase 1: Core Infrastructure (Week 1)
1. Add NDK dependency
2. Create NDK initialization and configuration
3. Implement key management adapter
4. Set up caching (start with MemCache)
5. Create service adapter layer

#### Phase 2: Basic Functionality (Week 2)
1. Migrate profile fetching
2. Migrate relay connections
3. Implement event publishing
4. Basic subscription management

#### Phase 3: Direct Messages (Week 3)
1. Migrate NIP-04 decryption (for existing messages)
2. Implement NIP-59 gift wrap for new messages
3. Migrate conversation management
4. Update message caching

#### Phase 4: Social Features (Week 4)
1. Migrate contact lists (following)
2. Implement reactions and reposts
3. Update profile discovery

#### Phase 5: Optimization and Testing (Week 5)
1. Implement database caching (Isar/ObjectBox)
2. Performance testing
3. Battery usage optimization
4. Error handling improvements

## Code Examples

### 1. Initialize NDK with Outbox Model
```dart
class NdkService {
  late final Ndk ndk;
  
  Future<void> initialize(String privateKey) async {
    // Create signer
    final keyApi = Bip340.fromPrivateKey(privateKey);
    final signer = Bip340EventSigner(
      privateKey: privateKey,
      publicKey: keyApi.publicKey,
    );
    
    // Configure NDK with JIT engine for outbox model
    ndk = Ndk(
      NdkConfig(
        engine: NdkEngine.JIT,
        cache: MemCacheManager(),
        logLevel: NdkLogLevel.info,
        // Bootstrap relays for initial connection
        bootstrapRelays: [
          'wss://relay.damus.io',
          'wss://nos.lol',
          'wss://relay.primal.net',
        ],
      ),
    );
    
    ndk.setSigner(signer);
    await ndk.connect();
  }
}
```

### 2. Fetch Profile with Relay Discovery
```dart
Future<NostrProfile?> fetchProfile(String pubkey) async {
  try {
    // NDK will connect to the user's write relays automatically
    final metadata = await ndk.metadata.loadMetadata(pubkey);
    
    if (metadata != null) {
      return NostrProfile(
        pubkey: pubkey,
        name: metadata.name,
        displayName: metadata.displayName,
        about: metadata.about,
        picture: metadata.picture,
        banner: metadata.banner,
        nip05: metadata.nip05,
        lud16: metadata.lud16,
        website: metadata.website,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          metadata.updatedAt * 1000,
        ),
      );
    }
  } catch (e) {
    print('Error fetching profile: $e');
  }
  return null;
}
```

### 3. Send Direct Message with Gift Wrap
```dart
Future<bool> sendDirectMessage(String recipientPubkey, String content) async {
  try {
    // NDK handles gift wrapping and sends to recipient's relays
    final response = await ndk.giftWrap.publish(
      receiverPubkey: recipientPubkey,
      content: content,
      kind: 14, // NIP-17 chat message
    );
    
    // Wait for successful broadcast
    await response.future;
    return true;
  } catch (e) {
    print('Error sending message: $e');
    return false;
  }
}
```

### 4. Subscribe to Messages with Outbox Model
```dart
Stream<DirectMessage> subscribeToMessages() {
  // Create subscription for incoming messages
  final response = ndk.requests.subscription(
    filters: [
      Filter(
        kinds: [1059], // Gift wrapped events
        // NDK will connect to your read relays
        tags: {'p': [ndk.signer!.publicKey]},
      ),
    ],
  );
  
  // Transform events to DirectMessage objects
  return response.stream.asyncMap((event) async {
    try {
      // NDK handles unwrapping automatically
      final unwrapped = await ndk.giftWrap.unwrap(event);
      if (unwrapped != null && unwrapped.kind == 14) {
        return DirectMessage(
          id: unwrapped.id,
          content: unwrapped.content,
          senderPubkey: unwrapped.pubkey,
          recipientPubkey: ndk.signer!.publicKey,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            unwrapped.createdAt * 1000,
          ),
          isFromMe: unwrapped.pubkey == ndk.signer!.publicKey,
          isRead: false,
        );
      }
    } catch (e) {
      print('Error unwrapping message: $e');
    }
    return null;
  }).where((msg) => msg != null).cast<DirectMessage>();
}
```

## Testing Strategy

### 1. Unit Tests
- Test service adapters
- Verify encryption/decryption compatibility
- Event signing verification

### 2. Integration Tests
- Relay connection management
- Message sending/receiving
- Profile fetching with relay discovery

### 3. Performance Tests
- Measure relay connection count
- Bandwidth usage comparison
- Battery usage on mobile

### 4. Compatibility Tests
- Ensure existing messages can be decrypted
- Verify profile data migration
- Test with various Nostr clients

## Rollback Plan

If issues arise during migration:
1. Keep existing services behind feature flags
2. Implement adapter pattern to switch between implementations
3. Gradual rollout with specific features
4. Monitor error rates and performance metrics

## Success Metrics

1. **Relay Efficiency**
   - Current: ~7 relays always connected
   - Target: 2-3 relays average, connecting to others as needed

2. **Message Delivery**
   - Current: Broadcast to all relays
   - Target: Direct delivery to recipient's relays

3. **Bandwidth Usage**
   - Expected 60-80% reduction in data transfer

4. **Battery Life**
   - Reduced WebSocket connections
   - Less CPU usage for decryption

## Conclusion

Migrating to NDK will provide Yestr with a modern, efficient Nostr implementation that follows best practices for relay management. The outbox model will significantly improve performance and privacy while maintaining full compatibility with the Nostr protocol.

The phased approach allows for gradual migration with minimal disruption to users, while the adapter pattern ensures we can maintain the existing API surface for the UI layer.