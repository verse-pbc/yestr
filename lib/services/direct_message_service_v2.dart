import 'dart:async';
import '../models/nostr_profile.dart';
import '../models/direct_message.dart';
import '../models/conversation.dart';
import 'key_management_service.dart';
import 'direct_message_service_ndk.dart';
import 'direct_message_service.dart' as legacy;

/// DirectMessageService v2 - Uses NDK with gift wrap support
/// This is a wrapper that provides the same API as the original DirectMessageService
/// but uses the NDK implementation underneath
class DirectMessageService {
  // Singleton instance
  static DirectMessageService? _instance;
  
  final KeyManagementService _keyManagementService;
  late final DirectMessageServiceNdk _ndkService;
  
  DirectMessageService._internal(this._keyManagementService) {
    _ndkService = DirectMessageServiceNdk(_keyManagementService);
  }
  
  // Factory constructor for singleton
  factory DirectMessageService(KeyManagementService keyManagementService) {
    if (_instance == null) {
      print('[DM Service V2] Creating new DirectMessageService instance with NDK');
      _instance = DirectMessageService._internal(keyManagementService);
    } else {
      print('[DM Service V2] Returning existing DirectMessageService instance');
    }
    return _instance!;
  }

  // Delegate all methods to NDK service
  Stream<DirectMessage> get messagesStream => _ndkService.messagesStream;
  Stream<List<Conversation>> get conversationsStream => _ndkService.conversationsStream;
  List<Conversation> get conversations => _ndkService.conversations;
  
  Future<bool> sendDirectMessage(String recipientPubkey, String content) => 
    _ndkService.sendDirectMessage(recipientPubkey, content);
    
  Future<void> loadConversations({bool loadMore = false}) => 
    _ndkService.loadConversations(loadMore: loadMore);
    
  Future<List<DirectMessage>> getMessagesForPubkey(String pubkey) => 
    _ndkService.getMessagesForPubkey(pubkey);
    
  Future<void> subscribeToConversationMessages(String otherPubkey) => 
    _ndkService.subscribeToConversationMessages(otherPubkey);
    
  void markConversationAsRead(String pubkey) => 
    _ndkService.markConversationAsRead(pubkey);
    
  void dispose() => _ndkService.dispose();
  
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  Future<void> debugCacheState() => _ndkService.debugCacheState();
  
  List<Conversation> getPaginatedConversations() => 
    _ndkService.getPaginatedConversations();
    
  bool get hasMoreConversations => _ndkService.hasMoreConversations;
}