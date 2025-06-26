import 'dart:async';
import 'package:flutter/material.dart';
import '../models/direct_message.dart';
import '../models/nostr_profile.dart';
import 'direct_message_service_v2.dart';
import 'key_management_service.dart';
import 'nostr_service.dart';

class DmNotificationService {
  // Singleton instance
  static DmNotificationService? _instance;
  
  final DirectMessageService _dmService;
  final KeyManagementService _keyService;
  final NostrService _nostrService = NostrService();
  
  // Track current conversation to avoid showing notifications for it
  String? _currentConversationPubkey;
  
  // Unread counts by pubkey
  final Map<String, int> _unreadCounts = {};
  
  // Stream controllers
  final _totalUnreadController = StreamController<int>.broadcast();
  final _notificationController = StreamController<DmNotification>.broadcast();
  
  // Subscriptions
  StreamSubscription? _messageSubscription;
  String? _currentUserPubkey;
  
  DmNotificationService._internal(this._dmService, this._keyService);
  
  // Factory constructor for singleton
  factory DmNotificationService(
    DirectMessageService dmService,
    KeyManagementService keyService,
  ) {
    _instance ??= DmNotificationService._internal(dmService, keyService);
    return _instance!;
  }
  
  // Getters
  Stream<int> get totalUnreadStream => _totalUnreadController.stream;
  Stream<DmNotification> get notificationStream => _notificationController.stream;
  int get totalUnreadCount => _unreadCounts.values.fold(0, (sum, count) => sum + count);
  
  /// Initialize the notification service
  Future<void> initialize() async {
    _currentUserPubkey = await _keyService.getPublicKey();
    if (_currentUserPubkey == null) return;
    
    // Listen to all incoming messages
    _messageSubscription = _dmService.messagesStream.listen(_handleNewMessage);
    
    // Calculate initial unread counts from conversations
    _updateUnreadCountsFromConversations();
    
    // Listen to conversation updates
    _dmService.conversationsStream.listen((_) {
      _updateUnreadCountsFromConversations();
    });
  }
  
  /// Update unread counts from conversations
  void _updateUnreadCountsFromConversations() {
    _unreadCounts.clear();
    
    for (final conversation in _dmService.conversations) {
      if (conversation.unreadCount > 0) {
        _unreadCounts[conversation.profile.pubkey] = conversation.unreadCount;
      }
    }
    
    _totalUnreadController.add(totalUnreadCount);
  }
  
  /// Handle new incoming messages
  void _handleNewMessage(DirectMessage message) async {
    // Only process messages that are not from the current user
    if (message.isFromMe || message.senderPubkey == _currentUserPubkey) return;
    
    // Don't show notification if we're in the conversation with this user
    if (_currentConversationPubkey == message.senderPubkey) {
      print('[DmNotificationService] Skipping notification - user is in conversation');
      return;
    }
    
    // Get sender profile
    NostrProfile? senderProfile = _dmService.conversations
        .firstWhere(
          (conv) => conv.profile.pubkey == message.senderPubkey,
          orElse: () => throw StateError('No conversation found'),
        )
        .profile;
    
    // If profile not found in conversations, try to fetch it
    if (senderProfile == null) {
      senderProfile = await _nostrService.getProfile(message.senderPubkey);
    }
    
    // Create notification
    final notification = DmNotification(
      message: message,
      senderProfile: senderProfile ?? NostrProfile(
        pubkey: message.senderPubkey,
        name: message.senderPubkey.substring(0, 8),
        displayName: null,
        about: null,
        picture: null,
        banner: null,
        nip05: null,
        lud16: null,
        website: null,
        createdAt: DateTime.now(),
      ),
    );
    
    // Emit notification
    _notificationController.add(notification);
    
    // Update unread count for this sender
    _unreadCounts[message.senderPubkey] = (_unreadCounts[message.senderPubkey] ?? 0) + 1;
    _totalUnreadController.add(totalUnreadCount);
    
    print('[DmNotificationService] New DM notification from ${notification.senderProfile.displayNameOrName}');
  }
  
  /// Set the current conversation (to avoid showing notifications for it)
  void setCurrentConversation(String? pubkey) {
    _currentConversationPubkey = pubkey;
    print('[DmNotificationService] Current conversation set to: $pubkey');
    
    // If entering a conversation, clear its unread count
    if (pubkey != null && _unreadCounts.containsKey(pubkey)) {
      _unreadCounts.remove(pubkey);
      _totalUnreadController.add(totalUnreadCount);
    }
  }
  
  /// Clear all unread counts
  void clearAllUnreadCounts() {
    _unreadCounts.clear();
    _totalUnreadController.add(0);
  }
  
  /// Get unread count for a specific pubkey
  int getUnreadCountForPubkey(String pubkey) {
    return _unreadCounts[pubkey] ?? 0;
  }
  
  void dispose() {
    _messageSubscription?.cancel();
    _totalUnreadController.close();
    _notificationController.close();
  }
  
  /// Reset the singleton instance
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Class representing a DM notification
class DmNotification {
  final DirectMessage message;
  final NostrProfile senderProfile;
  
  DmNotification({
    required this.message,
    required this.senderProfile,
  });
}