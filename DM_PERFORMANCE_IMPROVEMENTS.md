# DM Performance Improvements

## Current Issues
1. **Too many relays**: Connecting to 5 relays simultaneously
2. **No time limits**: Requesting ALL encrypted messages ever sent
3. **No message limits**: Downloading thousands of messages
4. **Synchronous decryption**: Decrypting all messages on the main thread
5. **Waiting for all relays**: UI blocked until all relays respond

## Implemented Improvements

### 1. Time-based Filtering
- Only load messages from the last 30 days
- Reduces the amount of data transferred significantly

### 2. Message Limits
- Limited to 200 messages per subscription
- Prevents downloading entire message history

### 3. Timeout for Loading
- 3-second timeout for the loading indicator
- Shows partial results even if some relays are slow

### 4. Optimized Relay Service (dm_relay_service.dart)
- Priority relays for DMs:
  - `wss://relay.damus.io` (fast and reliable)
  - `wss://nos.lol` (good for DMs)
  - `wss://relay.primal.net` (Primal's relay)
- Only connects to 2-3 relays instead of 5
- 1-second connection timeout per relay
- 2-second timeout for batch connections

## Additional Optimizations to Consider

### 1. Pagination
- Load only the most recent 10 conversations initially
- Load more as user scrolls

### 2. Background Decryption
- Move message decryption to an isolate/background thread
- Prevents UI freezing during decryption

### 3. Local Caching
- Cache decrypted messages locally
- Only fetch new messages since last sync

### 4. Relay Selection
- Allow users to choose their preferred relays
- Auto-detect fastest relays based on ping times

### 5. Progressive Loading
- Show conversation list immediately
- Load message previews asynchronously
- Update UI as messages are decrypted

## Usage
The current implementation already includes time limits and message limits. To use the optimized relay service:

```dart
// Replace NostrService with DmRelayService for DMs
final dmRelayService = DmRelayService();
await dmRelayService.connectForDMs();

// Subscribe to DMs
dmRelayService.subscribeToFilter({
  'kinds': [4],
  '#p': [userPubkey],
  'since': thirtyDaysAgo,
  'limit': 200,
});
```