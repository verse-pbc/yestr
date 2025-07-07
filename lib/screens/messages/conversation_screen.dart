import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/nostr_profile.dart';
import '../../services/direct_message_service_v2.dart';
import '../../services/nostr_service.dart';
import '../../services/key_management_service.dart';
import '../../services/message_cache_service.dart';
import '../../services/conversation_subscription_service.dart';
import '../../services/dm_notification_service.dart';
import '../../models/direct_message.dart';
import '../../widgets/gradient_background.dart';
import '../../utils/avatar_helper.dart';

class ConversationScreen extends StatefulWidget {
  final NostrProfile profile;

  const ConversationScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final KeyManagementService _keyService = KeyManagementService();
  late final DirectMessageService _dmService;
  late final DmNotificationService _notificationService;
  final NostrService _nostrService = NostrService();
  final ConversationSubscriptionService _conversationSubscriptionService = ConversationSubscriptionService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<DirectMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRefreshing = false;
  StreamSubscription? _messageSubscription;
  String? _conversationSubscriptionId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _dmService = DirectMessageService(_keyService);
    _notificationService = DmNotificationService(_dmService, _keyService);
    
    // Tell notification service we're in this conversation
    _notificationService.setCurrentConversation(widget.profile.pubkey);
    
    _loadMessages();
    _setupRealTimeSubscription();
    _setupPeriodicRefresh();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('[ConversationScreen] Loading messages for ${widget.profile.pubkey}');
      print('[ConversationScreen] Profile name: ${widget.profile.displayNameOrName}');
      
      // Make sure we're connected
      if (!_nostrService.isConnected) {
        print('[ConversationScreen] Connecting to Nostr service...');
        await _nostrService.connect();
      }

      // First get any existing messages from memory
      var messages = await _dmService.getMessagesForPubkey(widget.profile.pubkey);
      print('[ConversationScreen] Found ${messages.length} existing messages in memory');
      
      // If no messages in memory, try to load from cache
      if (messages.isEmpty) {
        print('[ConversationScreen] No messages in memory, checking cache...');
        final cacheService = MessageCacheService();
        messages = await cacheService.loadMessages(widget.profile.pubkey);
        print('[ConversationScreen] Found ${messages.length} messages in cache');
      }
      
      // Update UI with cached messages first for better UX
      if (messages.isNotEmpty) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        // If still no messages, wait a bit longer and try from the service
        print('[ConversationScreen] No messages found, waiting for relay messages...');
        
        // Set a timeout to show the empty state after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _messages.isEmpty) {
            setState(() {
              _isLoading = false;
            });
          }
        });
        
        // Try to get messages again after a delay
        await Future.delayed(const Duration(seconds: 1));
        messages = await _dmService.getMessagesForPubkey(widget.profile.pubkey);
        
        if (messages.isNotEmpty) {
          print('[ConversationScreen] Found ${messages.length} messages after delay');
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }

      // Scroll to bottom after loading
      _scrollToBottom();

      // Mark messages as read
      _dmService.markConversationAsRead(widget.profile.pubkey);

      // Listen for new messages
      _messageSubscription = _dmService.messagesStream
          .where((msg) => 
              msg.senderPubkey == widget.profile.pubkey || 
              msg.recipientPubkey == widget.profile.pubkey)
          .listen((message) {
        print('[ConversationScreen] New message received: ${message.content}');
        if (mounted) {
          setState(() {
            // Add message if not already present
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            }
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      print('[ConversationScreen] Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setupRealTimeSubscription() async {
    try {
      final userPubkey = await _keyService.getPublicKey();
      if (userPubkey == null) return;
      
      // Subscribe to real-time updates for this conversation
      await _conversationSubscriptionService.subscribeToConversation(
        userPubkey,
        widget.profile.pubkey,
      );
      
      // Also tell the DM service to subscribe specifically to this conversation
      await _dmService.subscribeToConversationMessages(widget.profile.pubkey);
      
      print('[ConversationScreen] Set up real-time subscription for conversation with ${widget.profile.displayNameOrName}');
    } catch (e) {
      print('[ConversationScreen] Error setting up real-time subscription: $e');
    }
  }
  
  void _setupPeriodicRefresh() {
    // Refresh messages every 10 seconds to catch any missed messages
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshMessages();
    });
  }
  
  Future<void> _refreshMessages() async {
    if (_isRefreshing) return; // Prevent multiple refreshes
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      print('[ConversationScreen] Refreshing messages...');
      
      // Force the service to check for new messages from relays
      await _dmService.subscribeToConversationMessages(widget.profile.pubkey);
      
      // Wait a bit for messages to come in
      await Future.delayed(const Duration(seconds: 2));
      
      // Get fresh messages from the service
      final freshMessages = await _dmService.getMessagesForPubkey(widget.profile.pubkey);
      
      if (mounted) {
        // Check if we have new messages or if message list has changed
        bool hasNewMessages = freshMessages.length != _messages.length;
        
        // Also check if the last message ID is different (in case messages were deleted/changed)
        if (!hasNewMessages && freshMessages.isNotEmpty && _messages.isNotEmpty) {
          hasNewMessages = freshMessages.last.id != _messages.last.id;
        }
        
        if (hasNewMessages) {
          setState(() {
            _messages = freshMessages;
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });
          _scrollToBottom();
          print('[ConversationScreen] Refreshed with ${freshMessages.length} messages');
          
          // Don't show snackbar here since we're already in the conversation
          // The notification service will handle snackbars when not in conversation
        } else {
          print('[ConversationScreen] No new messages found');
        }
      }
    } catch (e) {
      print('[ConversationScreen] Error refreshing messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _dmService.sendDirectMessage(widget.profile.pubkey, text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    // Clear current conversation in notification service
    _notificationService.setCurrentConversation(null);
    
    _messageSubscription?.cancel();
    _refreshTimer?.cancel();
    _conversationSubscriptionService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1c22),
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: CachedNetworkImageProvider(
                  AvatarHelper.getThumbnail(widget.profile.pubkey),
                ),
                child: widget.profile.picture == null
                    ? Text(
                        widget.profile.displayNameOrName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.displayNameOrName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.profile.nip05 != null)
                      Text(
                        widget.profile.nip05!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (_isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshMessages,
                tooltip: 'Refresh messages',
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Start a conversation with ${widget.profile.displayNameOrName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.isFromMe;
                            
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFF2a2c32),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe
                                        ? const Radius.circular(16)
                                        : const Radius.circular(4),
                                    bottomRight: isMe
                                        ? const Radius.circular(4)
                                        : const Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(message.createdAt),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1c22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2c32),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}