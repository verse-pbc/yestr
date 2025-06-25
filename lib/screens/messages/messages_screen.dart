import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/direct_message_service.dart';
import '../../services/nostr_service.dart';
import '../../services/key_management_service.dart';
import '../../models/nostr_profile.dart';
import '../../models/conversation.dart';
import '../../widgets/app_drawer.dart';
import 'conversation_screen.dart';
import '../../widgets/gradient_background.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final KeyManagementService _keyService = KeyManagementService();
  late final DirectMessageService _dmService;
  final NostrService _nostrService = NostrService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _dmService = DirectMessageService(_keyService);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Make sure we're connected to Nostr
      if (!_nostrService.isConnected) {
        await _nostrService.connect();
      }

      // Load conversations from the service
      await _dmService.loadConversations();
      
      // Listen to conversation updates
      _conversationSubscription = _dmService.conversationsStream.listen((conversations) {
        if (mounted) {
          setState(() {
            _conversations = conversations;
            // Don't set loading to false here, let timeout handle it
          });
        }
      });

      // Get initial conversations
      setState(() {
        _conversations = _dmService.conversations;
      });
      
      // Set a timeout to stop loading indicator after 3 seconds
      // This allows showing partial results even if some relays are slow
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
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
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? Center(
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
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start swiping to connect with people!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
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
                              backgroundImage: conversation.profile.picture != null
                                  ? NetworkImage(conversation.profile.picture!)
                                  : null,
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