import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nostr_event.dart';
import '../models/nostr_profile.dart';
import '../utils/nostr_utils.dart';

class ShareNoteSheet extends StatelessWidget {
  final NostrEvent note;
  final NostrProfile author;
  
  const ShareNoteSheet({
    super.key,
    required this.note,
    required this.author,
  });
  
  @override
  Widget build(BuildContext context) {
    // Generate the nevent from the event ID
    final nevent = NostrUtils.hexToNevent(note.id);
    // Create a shareable link for the note
    final noteLink = 'https://njump.me/$nevent';
    
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Share Note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // Share options
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy Link to Note'),
            subtitle: Text(noteLink, style: Theme.of(context).textTheme.bodySmall),
            onTap: () {
              Clipboard.setData(ClipboardData(text: noteLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('Copy Note ID (Nevent)'),
            subtitle: Text(nevent, style: Theme.of(context).textTheme.bodySmall),
            onTap: () {
              Clipboard.setData(ClipboardData(text: nevent));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share via...'),
            subtitle: const Text('Open system share sheet'),
            onTap: () {
              Navigator.pop(context);
              // Share via system share sheet
              final shareText = '${author.displayNameOrName} posted:\n\n${note.content}\n\n$noteLink';
              Share.share(
                shareText,
                subject: 'Note by ${author.displayNameOrName} on Nostr',
              );
            },
          ),
          const SizedBox(height: 16),
          // Cancel button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
  
  static void show(BuildContext context, NostrEvent note, NostrProfile author) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true, // This makes it appear above everything including the tab bar
      builder: (BuildContext context) {
        return ShareNoteSheet(
          note: note,
          author: author,
        );
      },
    );
  }
}