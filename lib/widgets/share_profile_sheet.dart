import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/nostr_profile.dart';
import '../utils/nostr_utils.dart';

class ShareProfileSheet extends StatelessWidget {
  final NostrProfile profile;
  
  const ShareProfileSheet({
    super.key,
    required this.profile,
  });
  
  @override
  Widget build(BuildContext context) {
    // Generate the npub from the hex pubkey
    final npub = NostrUtils.hexToNpub(profile.pubkey);
    // Create a shareable link (you might want to customize this URL)
    final profileLink = 'https://njump.me/$npub';
    
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
              'Share Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // Share options
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy Link to Profile'),
            subtitle: Text(profileLink, style: Theme.of(context).textTheme.bodySmall),
            onTap: () {
              Clipboard.setData(ClipboardData(text: profileLink));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Copy Profile ID (Npub)'),
            subtitle: Text(npub, style: Theme.of(context).textTheme.bodySmall),
            onTap: () {
              Clipboard.setData(ClipboardData(text: npub));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile ID copied to clipboard'),
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
              final shareText = '${profile.displayNameOrName} on Nostr\n\n${profile.about ?? "Check out this profile"}\n\n$profileLink';
              Share.share(
                shareText,
                subject: '${profile.displayNameOrName} on Nostr',
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
  
  static void show(BuildContext context, NostrProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true, // This makes it appear above everything including the tab bar
      builder: (BuildContext context) {
        return ShareProfileSheet(
          profile: profile,
        );
      },
    );
  }
}