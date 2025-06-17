import 'package:flutter/material.dart';
import '../models/nostr_profile.dart';
import '../services/direct_message_service.dart';
import '../services/key_management_service.dart';

class DirectMessageComposer extends StatefulWidget {
  final NostrProfile recipient;
  final VoidCallback? onMessageSent;

  const DirectMessageComposer({
    Key? key,
    required this.recipient,
    this.onMessageSent,
  }) : super(key: key);

  @override
  State<DirectMessageComposer> createState() => _DirectMessageComposerState();
}

class _DirectMessageComposerState extends State<DirectMessageComposer> {
  final TextEditingController _messageController = TextEditingController();
  final KeyManagementService _keyManagementService = KeyManagementService();
  late final DirectMessageService _dmService;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _dmService = DirectMessageService(_keyManagementService);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Check if user is logged in
      final isLoggedIn = await _keyManagementService.hasPrivateKey();
      
      if (!isLoggedIn) {
        throw Exception('You need to be logged in to send messages');
      }
      
      // Send the encrypted message
      final success = await _dmService.sendDirectMessage(message, widget.recipient);
      
      if (!success) {
        throw Exception('Failed to send message to any relay');
      }
      
      // Clear the input field
      _messageController.clear();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to ${widget.recipient.displayNameOrName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Call the callback
      widget.onMessageSent?.call();
    } catch (e) {
      // Show error feedback
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bottom sheet drag handle and title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send Message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.recipient.picture != null
                    ? NetworkImage(widget.recipient.picture!)
                    : null,
                child: widget.recipient.picture == null
                    ? const Icon(Icons.person)
                    : null,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message to ${widget.recipient.displayNameOrName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.recipient.nip05 != null)
                      Text(
                        widget.recipient.nip05!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'sendDmButton',
                onPressed: _isSending ? null : _sendMessage,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}