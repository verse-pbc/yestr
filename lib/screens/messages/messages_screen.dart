import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/direct_message_service_v2.dart';
import '../../services/nostr_service.dart';
import '../../services/key_management_service.dart';
import '../../services/dm_notification_service.dart';
import '../../models/nostr_profile.dart';
import '../../models/conversation.dart';
import '../../widgets/app_drawer.dart';
import 'conversation_screen.dart';
import '../../widgets/gradient_background.dart';
import '../../utils/avatar_helper.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final KeyManagementService _keyService = KeyManagementService();
  late final DirectMessageService _dmService;
  late final DmNotificationService _notificationService;
  final NostrService _nostrService = NostrService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  StreamSubscription? _conversationSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _dmService = DirectMessageService(_keyService);
    _notificationService = DmNotificationService(_dmService, _keyService);
    
    // Clear current conversation since we're on messages list
    _notificationService.setCurrentConversation(null);
    
    // Debug: Check if service has existing conversations
    print('[MessagesScreen] Initial conversations count: ${_dmService.conversations.length}');
    
    // Check login status and preloaded conversations
    _checkAndLoadConversations();
    
    // Set up scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreConversations();
      }
    });
  }

  Future<void> _checkAndLoadConversations() async {
    // Check if user is logged in first
    final hasPrivateKey = await _keyService.hasPrivateKey();
    if (!hasPrivateKey) {
      print('[MessagesScreen] User not logged in, showing empty state');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Check if we already have conversations preloaded
    if (_dmService.conversations.isNotEmpty) {
      print('[MessagesScreen] Found ${_dmService.conversations.length} preloaded conversations');
      setState(() {
        _conversations = _dmService.getPaginatedConversations();
        _isLoading = false;
      });
      
      // Still set up listener for updates
      _conversationSubscription = _dmService.conversationsStream.listen((conversations) {
        print('[MessagesScreen] Received ${conversations.length} conversations from stream');
        if (mounted) {
          setState(() {
            _conversations = _dmService.getPaginatedConversations();
            print('[MessagesScreen] Updated UI with ${_conversations.length} conversations');
          });
        }
      });
      
      // Also trigger a refresh in the background to get any new messages
      _dmService.loadConversations().catchError((error) {
        print('[MessagesScreen] Background refresh error: $error');
      });
    } else {
      // No preloaded conversations, load normally
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is logged in first
      final hasPrivateKey = await _keyService.hasPrivateKey();
      if (!hasPrivateKey) {
        print('[MessagesScreen] User not logged in, cannot load conversations');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Make sure we're connected to Nostr
      if (!_nostrService.isConnected) {
        await _nostrService.connect();
      }

      // Load conversations from the service
      await _dmService.loadConversations();
      
      // Listen to conversation updates
      _conversationSubscription = _dmService.conversationsStream.listen((conversations) {
        print('[MessagesScreen] Received ${conversations.length} conversations from stream');
        if (mounted) {
          setState(() {
            _conversations = _dmService.getPaginatedConversations();
            print('[MessagesScreen] Updated UI with ${_conversations.length} conversations');
            // Don't set loading to false here, let timeout handle it
          });
        }
      });

      // Get initial conversations
      setState(() {
        _conversations = _dmService.getPaginatedConversations();
        print('[MessagesScreen] Got ${_conversations.length} conversations from service');
      });
      
      // Check if we have cached conversations immediately
      if (_conversations.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
      } else {
        // Set a timeout to stop loading indicator after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              // Force get conversations one more time
              _conversations = _dmService.getPaginatedConversations();
              print('[MessagesScreen] After timeout, conversations: ${_conversations.length}');
            });
          }
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreConversations() async {
    if (_isLoadingMore || !_dmService.hasMoreConversations) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      await _dmService.loadConversations(loadMore: true);
      
      // Update conversations after loading more
      if (mounted) {
        setState(() {
          _conversations = _dmService.getPaginatedConversations();
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more conversations: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AppDrawer(),
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFF1a1c22),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                await _dmService.debugCacheState();
                
                // Force reload from cache
                setState(() {
                  _conversations = _dmService.getPaginatedConversations();
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Debug: ${_conversations.length} conversations in UI')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadConversations,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? FutureBuilder<bool>(
                    future: _keyService.hasPrivateKey(),
                    builder: (context, snapshot) {
                      final isLoggedIn = snapshot.data ?? false;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isLoggedIn ? 'No conversations yet' : 'Login required',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLoggedIn 
                                ? 'Start swiping to connect with people!'
                                : 'Please login to view your messages',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _conversations.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom
                        if (index == _conversations.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final conversation = _conversations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: const Color(0xFF2a2c32),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: CachedNetworkImageProvider(
                                AvatarHelper.getThumbnail(conversation.profile.pubkey),
                              ),
                              child: conversation.profile.picture == null
                                  ? Text(
                                      conversation.profile.displayNameOrName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              conversation.profile.displayNameOrName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              conversation.lastMessage ?? 'No messages yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTimestamp(conversation.lastMessageTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                if (conversation.unreadCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      conversation.unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConversationScreen(
                                    profile: conversation.profile,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}