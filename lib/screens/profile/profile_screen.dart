import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/nostr_profile.dart';
import '../../models/nostr_event.dart';
import '../../services/nostr_service.dart';
import '../../services/reaction_service.dart';
import '../../services/key_management_service.dart';
import '../../services/saved_profiles_service.dart';
import '../../services/follow_service.dart';
import '../../widgets/formatted_content.dart';
import '../../widgets/share_profile_sheet.dart';
import '../../widgets/share_note_sheet.dart';
import '../../widgets/dm_composer.dart';
import '../../widgets/image_lightbox.dart';
import '../../utils/cors_helper.dart';
import '../../widgets/gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  final NostrProfile profile;
  final VoidCallback? onSkip;

  const ProfileScreen({
    super.key,
    required this.profile,
    this.onSkip,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NostrService _nostrService = NostrService();
  final ReactionService _reactionService = ReactionService();
  final KeyManagementService _keyService = KeyManagementService();
  final FollowService _followService = FollowService();
  late final SavedProfilesService _savedProfilesService;
  Future<List<NostrEvent>>? _notesFuture;
  final Set<String> _likedNotes = {}; // Track liked notes locally
  final Map<String, bool> _likingInProgress = {}; // Track ongoing like operations
  final Set<String> _repostedNotes = {}; // Track reposted notes locally
  final Map<String, bool> _repostingInProgress = {}; // Track ongoing repost operations

  @override
  void initState() {
    super.initState();
    // Initialize saved profiles service with NostrService instance
    _savedProfilesService = SavedProfilesService(_nostrService);
    print('ProfileScreen: Loading notes for ${widget.profile.displayNameOrName} (${widget.profile.pubkey})');
    _notesFuture = _nostrService.getUserNotes(widget.profile.pubkey, limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.profile.displayNameOrName),
              background: GestureDetector(
                onTap: widget.profile.picture != null
                    ? () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierColor: Colors.black.withOpacity(0.9),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ImageLightbox(
                                  imageUrl: widget.profile.picture!,
                                  heroTag: 'profile-image-${widget.profile.pubkey}',
                                ),
                              );
                            },
                          ),
                        );
                      }
                    : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Profile image
                    widget.profile.picture != null
                        ? Hero(
                            tag: 'profile-image-${widget.profile.pubkey}',
                            child: CachedNetworkImage(
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
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.person, size: 120),
                            ),
                          ),
                    // Gradient overlay (same as ProfileCard)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      ShareProfileSheet.show(context, widget.profile);
                    },
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionIndicator(
                          Icons.close,
                          'Nope',
                          Colors.red,
                          () {
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildActionIndicator(
                          Icons.skip_next,
                          'Skip',
                          Colors.yellow,
                          () {
                            Navigator.of(context).pop();
                            // Call the skip callback if provided
                            if (widget.onSkip != null) {
                              widget.onSkip!();
                            }
                          },
                        ),
                        _buildActionIndicator(
                          Icons.bookmark,
                          'Save',
                          Colors.blue,
                          () async {
                            await _handleSaveProfile();
                          },
                        ),
                        _buildActionIndicator(
                          Icons.person_add,
                          'Follow',
                          Colors.green,
                          () async {
                            await _handleFollow();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
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
                print('Error loading notes: ${snapshot.error}');
                print('Stack trace: ${snapshot.stackTrace}');
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 8),
                          Text('Error loading posts: ${snapshot.error}'),
                        ],
                      ),
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
          _showMessageBottomSheet(context);
        },
        child: const Icon(Icons.message),
      ),
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
                  icon: Icon(
                    _likedNotes.contains(note.id) 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                    color: _likedNotes.contains(note.id) 
                        ? Colors.red 
                        : null,
                  ),
                  onPressed: _likingInProgress[note.id] == true
                      ? null
                      : () => _handleLike(note),
                ),
                IconButton(
                  icon: Icon(
                    Icons.repeat,
                    color: _repostedNotes.contains(note.id) 
                        ? Colors.green 
                        : null,
                  ),
                  onPressed: _repostingInProgress[note.id] == true
                      ? null
                      : () => _handleRepost(note),
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

  Widget _buildActionIndicator(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
    ShareNoteSheet.show(context, note, widget.profile);
  }

  Future<void> _handleLike(NostrEvent note) async {
    // Check if user is logged in
    final hasPrivateKey = await _keyService.hasPrivateKey();
    if (!hasPrivateKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to like posts'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Set liking in progress
    setState(() {
      _likingInProgress[note.id] = true;
    });

    try {
      // Call the reaction service to like the post
      final success = await _reactionService.likePost(note);
      
      if (success) {
        if (mounted) {
          setState(() {
            _likedNotes.add(note.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Liked!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to like post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error liking post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error liking post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _likingInProgress[note.id] = false;
        });
      }
    }
  }

  Future<void> _handleRepost(NostrEvent note) async {
    // Check if user is logged in
    final hasPrivateKey = await _keyService.hasPrivateKey();
    if (!hasPrivateKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to repost'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Set reposting in progress
    setState(() {
      _repostingInProgress[note.id] = true;
    });

    try {
      // Call the reaction service to repost
      final success = await _reactionService.repostNote(note);
      
      if (success) {
        if (mounted) {
          setState(() {
            _repostedNotes.add(note.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reposted!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to repost'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error reposting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error reposting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _repostingInProgress[note.id] = false;
        });
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    try {
      final saved = await _savedProfilesService.saveProfile(widget.profile.pubkey);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${widget.profile.displayNameOrName}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFollow() async {
    try {
      final success = await _followService.followProfile(widget.profile.pubkey);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${widget.profile.displayNameOrName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow failed. Please login to follow users.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error following user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      // Use at least 60% of screen height and expand if keyboard is shown
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (BuildContext context) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: DirectMessageComposer(
            recipient: widget.profile,
            onMessageSent: () {
              // Close the bottom sheet after message is sent
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}