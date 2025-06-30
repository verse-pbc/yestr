import 'package:isar/isar.dart';

part 'cached_message.g.dart';

/// Cached direct message stored in Isar database
@Collection(accessor: 'cachedMessages')
class CachedMessage {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String eventId;
  
  @Index()
  late String senderPubkey;
  
  @Index()
  late String receiverPubkey;
  
  late String encryptedContent;
  String? decryptedContent; // Cache decrypted content to avoid re-decryption
  
  @Index()
  late DateTime createdAt;
  
  late DateTime receivedAt;
  
  @Index(composite: [CompositeIndex('receiverPubkey')])
  late String conversationKey; // Composite key for quick conversation lookup
  
  bool isRead = false;
  bool isSent = true; // Track send status
  
  // For optimistic UI updates
  bool isPending = false;
  String? localId; // Temporary ID for pending messages
  
  // Error handling
  String? errorMessage;
  int retryCount = 0;
  
  // Generate conversation key (sorted pubkeys)
  static String generateConversationKey(String pubkey1, String pubkey2) {
    final sorted = [pubkey1, pubkey2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}