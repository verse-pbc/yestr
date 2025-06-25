import 'dart:async';
import 'dm_relay_service.dart';

/// Service to manage real-time subscriptions for specific conversations
class ConversationSubscriptionService {
  final DmRelayService _dmRelayService = DmRelayService();
  Timer? _refreshTimer;
  String? _activeConversationPubkey;
  String? _currentUserPubkey;
  String? _subscriptionId;
  
  /// Start a real-time subscription for a specific conversation
  Future<void> subscribeToConversation(String userPubkey, String otherPubkey) async {
    print('[ConversationSub] Setting up real-time subscription for conversation with $otherPubkey');
    
    _activeConversationPubkey = otherPubkey;
    _currentUserPubkey = userPubkey;
    
    // Make sure we're connected
    if (!_dmRelayService.isConnected) {
      await _dmRelayService.connectForDMs();
    }
    
    // Cancel any existing subscription
    if (_subscriptionId != null) {
      _dmRelayService.closeSubscription(_subscriptionId!);
    }
    
    // Subscribe to real-time messages for this conversation
    _subscribeToMessages();
    
    // Set up periodic refresh to catch any missed messages
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      print('[ConversationSub] Refreshing conversation subscription...');
      _subscribeToMessages();
    });
  }
  
  void _subscribeToMessages() {
    if (_currentUserPubkey == null || _activeConversationPubkey == null) return;
    
    // Get current timestamp minus 1 minute to catch recent messages
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final timestamp = oneMinuteAgo.millisecondsSinceEpoch ~/ 1000;
    
    // Create a unique subscription ID
    _subscriptionId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    
    print('[ConversationSub] Creating subscription with ID: $_subscriptionId');
    
    // Subscribe to messages from the other user to us
    _dmRelayService.subscribeToFilter({
      'kinds': [4],
      'authors': [_activeConversationPubkey!],
      '#p': [_currentUserPubkey!],
      'since': timestamp,
    });
    
    // Also subscribe to our messages to them (to see our own sent messages)
    _dmRelayService.subscribeToFilter({
      'kinds': [4],
      'authors': [_currentUserPubkey!],
      '#p': [_activeConversationPubkey!],
      'since': timestamp,
    });
  }
  
  /// Stop the real-time subscription
  void unsubscribe() {
    print('[ConversationSub] Stopping real-time subscription');
    
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    if (_subscriptionId != null) {
      _dmRelayService.closeSubscription(_subscriptionId!);
      _subscriptionId = null;
    }
    
    _activeConversationPubkey = null;
    _currentUserPubkey = null;
  }
  
  void dispose() {
    unsubscribe();
  }
}