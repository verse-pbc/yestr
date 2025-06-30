import 'dart:async';
import 'package:ndk/ndk.dart';
import '../../../models/nostr_event.dart';
import '../ndk_service.dart';

/// Adapter to convert between NDK events and our NostrEvent model
class EventAdapter {
  final NdkService _ndkService;
  
  EventAdapter(this._ndkService);
  
  /// Convert NDK Nip01Event to our NostrEvent model
  NostrEvent ndkEventToNostrEvent(Nip01Event ndkEvent) {
    return NostrEvent(
      id: ndkEvent.id ?? '',
      pubkey: ndkEvent.pubKey,
      createdAt: ndkEvent.createdAt,
      kind: ndkEvent.kind,
      tags: ndkEvent.tags,
      content: ndkEvent.content,
      sig: ndkEvent.sig ?? '',
    );
  }
  
  /// Convert our NostrEvent model to NDK Nip01Event
  Nip01Event nostrEventToNdkEvent(NostrEvent event) {
    return Nip01Event(
      pubKey: event.pubkey,
      createdAt: event.createdAt,
      kind: event.kind,
      tags: event.tags,
      content: event.content,
      // Note: NDK events don't have id or sig fields - they're computed internally
    );
  }
  
  /// Query events with filters
  Stream<NostrEvent> queryEvents({
    required List<Filter> filters,
    String? relayUrl,
  }) {
    final controller = StreamController<NostrEvent>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      
      // Use explicit relays if specific relay is requested
      List<String>? explicitRelays;
      if (relayUrl != null) {
        explicitRelays = [relayUrl];
      }
      
      // Query events
      final response = ndk.requests.query(
        filters: filters,
        explicitRelays: explicitRelays,
      );
      
      // Convert and forward events
      final subscription = response.stream.listen(
        (ndkEvent) {
          try {
            controller.add(ndkEventToNostrEvent(ndkEvent));
          } catch (e) {
            print('Error converting event: $e');
          }
        },
        onError: (error) => controller.addError(error),
        onDone: () => controller.close(),
      );
      
      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      controller.addError('Error querying events: $e');
    }
    
    return controller.stream;
  }
  
  /// Subscribe to events (real-time updates)
  Stream<NostrEvent> subscribeToEvents({
    required List<Filter> filters,
    String? relayUrl,
  }) {
    final controller = StreamController<NostrEvent>.broadcast();
    
    try {
      final ndk = _ndkService.ndk;
      
      // Use explicit relays if specific relay is requested
      List<String>? explicitRelays;
      if (relayUrl != null) {
        explicitRelays = [relayUrl];
      }
      
      // Subscribe to events
      final response = ndk.requests.subscription(
        filters: filters,
        explicitRelays: explicitRelays,
      );
      
      // Convert and forward events
      final subscription = response.stream.listen(
        (ndkEvent) {
          try {
            controller.add(ndkEventToNostrEvent(ndkEvent));
          } catch (e) {
            print('Error converting event: $e');
          }
        },
        onError: (error) => controller.addError(error),
      );
      
      controller.onCancel = () {
        subscription.cancel();
        // NDK response doesn't have a close method - subscription cancel is sufficient
      };
    } catch (e) {
      controller.addError('Error subscribing to events: $e');
    }
    
    return controller.stream;
  }
  
  /// Publish an event
  Future<bool> publishEvent(NostrEvent event) async {
    try {
      final ndk = _ndkService.ndk;
      final ndkEvent = nostrEventToNdkEvent(event);
      
      final response = ndk.broadcast.broadcast(
        nostrEvent: ndkEvent,
      );
      
      // Wait for broadcast to complete
      await response.broadcastDoneFuture;
      return true;
    } catch (e) {
      print('Error publishing event: $e');
      return false;
    }
  }
  
  /// Create and publish a text note
  Future<NostrEvent?> publishTextNote(String content, {List<List<String>>? tags}) async {
    try {
      final ndk = _ndkService.ndk;
      final account = ndk.accounts.getLoggedAccount();
      
      if (account == null) return null;
      
      // Create event
      final event = Nip01Event(
        pubKey: account.pubkey,
        kind: 1, // Text note
        content: content,
        tags: tags ?? [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      // Sign event
      await account.signer.sign(event);
      
      // Broadcast
      final response = ndk.broadcast.broadcast(
        nostrEvent: event,
      );
      
      await response.broadcastDoneFuture;
      return ndkEventToNostrEvent(event);
      
      return null;
    } catch (e) {
      print('Error publishing text note: $e');
      return null;
    }
  }
  
  /// Delete events
  Future<bool> deleteEvents(List<String> eventIds) async {
    try {
      final ndk = _ndkService.ndk;
      final account = ndk.accounts.getLoggedAccount();
      
      if (account == null) return false;
      
      // Create deletion event (NIP-09)
      final deletionEvent = Nip01Event(
        pubKey: account.pubkey,
        kind: 5, // Deletion
        content: 'Deleted',
        tags: eventIds.map((id) => ['e', id]).toList(),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      // Sign event
      await account.signer.sign(deletionEvent);
      
      // Broadcast
      final response = ndk.broadcast.broadcast(
        nostrEvent: deletionEvent,
      );
      
      await response.broadcastDoneFuture;
      return true;
    } catch (e) {
      print('Error deleting events: $e');
      return false;
    }
  }
  
  /// React to an event (like, emoji, etc)
  Future<bool> reactToEvent({
    required String eventId,
    required String eventPubkey,
    String reaction = '+',
  }) async {
    try {
      final ndk = _ndkService.ndk;
      final account = ndk.accounts.getLoggedAccount();
      
      if (account == null) return false;
      
      // Create reaction event (NIP-25)
      final reactionEvent = Nip01Event(
        pubKey: account.pubkey,
        kind: 7, // Reaction
        content: reaction,
        tags: [
          ['e', eventId],
          ['p', eventPubkey],
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      // Sign event
      await account.signer.sign(reactionEvent);
      
      // Broadcast
      final response = ndk.broadcast.broadcast(
        nostrEvent: reactionEvent,
      );
      
      await response.broadcastDoneFuture;
      return true;
    } catch (e) {
      print('Error reacting to event: $e');
      return false;
    }
  }
}