import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/nostr_profile.dart';
import '../../models/nostr_event.dart';
import '../../services/nostr_service.dart';
import '../../widgets/formatted_content.dart';
import '../../widgets/share_profile_sheet.dart';
import '../../utils/cors_helper.dart';

class ProfileScreen extends StatefulWidget {
  final NostrProfile profile;

  const ProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NostrService _nostrService = NostrService();
  Future<List<NostrEvent>>? _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = _nostrService.getUserNotes(widget.profile.pubkey, limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.profile.displayNameOrName),
              background: widget.profile.picture != null
                  ? CachedNetworkImage(
                      imageUrl: CorsHelper.wrapWithCorsProxy(widget.profile.picture!),
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                        'Accept-Language': 'en-US,en;q=0.9',
                        'Referer': 'https://yestr.app/',
                      },
                      errorWidget: (context, url, error) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, size: 50),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.person, size: 120),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ShareProfileSheet.show(context, widget.profile);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NIP-05 Verification
                  if (widget.profile.nip05 != null && widget.profile.nip05!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.profile.nip05!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // About Section
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profile.about ?? 'No bio available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  // Website
                  if (widget.profile.website != null && widget.profile.website!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.profile.website!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Lightning Address
                  if (widget.profile.lud16 != null && widget.profile.lud16!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.profile.lud16!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Recent Posts Section
                  const SizedBox(height: 24),
                  Text(
                    'Recent Posts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Recent notes list
          FutureBuilder<List<NostrEvent>>(
            future: _notesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Error loading posts: ${snapshot.error}'),
                    ),
                  ),
                );
              }
              
              final notes = snapshot.data ?? [];
              
              if (notes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No posts available'),
                    ),
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(note);
                  },
                  childCount: notes.length,
                ),
              );
            },
          ),
          // Profile Info at the bottom
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Public Key', _truncatePubkey(widget.profile.pubkey)),
                      const SizedBox(height: 8),
                      if (widget.profile.createdAt != null)
                        _buildInfoRow(
                          'Profile Created',
                          _formatDate(widget.profile.createdAt!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Direct message feature coming soon!')),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildNoteCard(NostrEvent note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.profile.picture != null
                      ? CachedNetworkImageProvider(
                          CorsHelper.wrapWithCorsProxy(widget.profile.picture!),
                          headers: const {
                            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                            'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                            'Accept-Language': 'en-US,en;q=0.9',
                            'Referer': 'https://yestr.app/',
                          },
                        )
                      : null,
                  child: widget.profile.picture == null
                      ? const Icon(Icons.person)
                      : null,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.displayNameOrName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _formatDate(note.createdDateTime),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FormattedContent(
              content: note.content,
              textStyle: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Like feature coming soon!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.repeat),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Repost feature coming soon!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    _shareNote(note);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _truncatePubkey(String pubkey) {
    if (pubkey.length <= 16) return pubkey;
    return '${pubkey.substring(0, 8)}...${pubkey.substring(pubkey.length - 8)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  void _shareNote(NostrEvent note) {
    final text = '${widget.profile.displayNameOrName} posted:\n\n'
        '${note.content}\n\n'
        'Posted ${_formatDate(note.createdDateTime)}';
    Share.share(text);
  }
}