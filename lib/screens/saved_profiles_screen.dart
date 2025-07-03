import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/nostr_profile.dart';
import '../services/nostr_service.dart';
import '../services/saved_profiles_service.dart';
import '../services/follow_service.dart';
import '../services/web_background_service.dart';
import '../widgets/profile_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dm_composer.dart';
import '../widgets/gradient_background.dart';

class SavedProfilesScreen extends StatefulWidget {
  const SavedProfilesScreen({super.key});

  @override
  State<SavedProfilesScreen> createState() => _SavedProfilesScreenState();
}

class _SavedProfilesScreenState extends State<SavedProfilesScreen> {
  final CardSwiperController controller = CardSwiperController();
  final NostrService _nostrService = NostrService();
  final FollowService _followService = FollowService();
  late final SavedProfilesService _savedProfilesService;
  List<NostrProfile> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize saved profiles service
    _savedProfilesService = SavedProfilesService(_nostrService);
    // Set main background when screen loads
    WebBackgroundService.setMainBackground();
    _loadSavedProfiles();
  }

  Future<void> _loadSavedProfiles() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _nostrService.connect();
      
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load saved profiles (service already listens to events internally)
      await _savedProfilesService.loadSavedProfiles();
      
      // Wait a bit for events to come in
      await Future.delayed(const Duration(seconds: 2));
      
      // Get saved profiles
      final savedProfiles = await _savedProfilesService.getSavedProfiles();
      
      setState(() {
        _profiles = savedProfiles;
        _isLoading = false;
      });
      
      print('Loaded ${_profiles.length} saved profiles');
      print('Saved profile pubkeys: ${_savedProfilesService.savedProfilePubkeys}');
      print('Profiles empty: ${_profiles.isEmpty}');
      for (var profile in _profiles) {
        print('Profile: ${profile.displayNameOrName} (${profile.pubkey})');
      }
    } catch (e) {
      print('Error loading saved profiles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    // Don't dispose singleton services
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawerScrimColor: Colors.black.withOpacity(0.6),
        drawer: AppDrawer(),
        body: Stack(
        children: [
          // App bar layer (bottom layer - lowest z-index)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1c22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight + 8,
                  child: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    leading: Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Saved Profiles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    centerTitle: true,
                    toolbarHeight: kToolbarHeight + 8,
                    titleSpacing: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                          onPressed: _loadSavedProfiles,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Cards layer (top layer - highest z-index)
          SafeArea(
            top: false,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_profiles.isEmpty || _profiles.length == 0)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved profiles yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Swipe up on profiles in Discover to save them',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _profiles.isNotEmpty ? CardSwiper(
                              controller: controller,
                              cardsCount: _profiles.length,
                              onSwipe: _onSwipe,
                              onUndo: _onUndo,
                              numberOfCardsDisplayed: _profiles.length >= 3 ? 3 : _profiles.length,
                              backCardOffset: const Offset(40, 40),
                              padding: const EdgeInsets.only(
                                left: 24.0,
                                right: 24.0,
                                top: kToolbarHeight + 32.0,
                                bottom: 24.0,
                              ),
                              cardBuilder: (
                                context,
                                index,
                                horizontalThresholdPercentage,
                                verticalThresholdPercentage,
                              ) =>
                                  Stack(
                                children: [
                                  ProfileCard(profile: _profiles[index]),
                                  // Follow overlay
                                  if (horizontalThresholdPercentage > 50)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.green.withOpacity(
                                            ((horizontalThresholdPercentage - 50) / 50 * 0.5).clamp(0.0, 0.5),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.person_add,
                                            size: 100,
                                            color: Colors.white.withOpacity(
                                              ((horizontalThresholdPercentage - 50) / 50).clamp(0.0, 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Remove overlay
                                  if (horizontalThresholdPercentage < -50)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.red.withOpacity(
                                            ((horizontalThresholdPercentage.abs() - 50) / 50 * 0.5).clamp(0.0, 0.5),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.bookmark_remove,
                                            size: 100,
                                            color: Colors.white.withOpacity(
                                              ((horizontalThresholdPercentage.abs() - 50) / 50).clamp(0.0, 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Send DM overlay
                                  if (verticalThresholdPercentage < -50)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.blue.withOpacity(
                                            ((verticalThresholdPercentage.abs() - 50) / 50 * 0.5).clamp(0.0, 0.5),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.message,
                                            size: 100,
                                            color: Colors.white.withOpacity(
                                              ((verticalThresholdPercentage.abs() - 50) / 50).clamp(0.0, 1.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ) : const SizedBox.shrink(),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Swipe Actions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildIndicator(
                                          Icons.bookmark_remove,
                                          'Left',
                                          Colors.red,
                                          'Remove',
                                          () => controller.swipe(CardSwiperDirection.left),
                                        ),
                                        _buildIndicator(
                                          Icons.message,
                                          'Up',
                                          Colors.blue,
                                          'Send DM',
                                          () => controller.swipe(CardSwiperDirection.top),
                                        ),
                                        _buildIndicator(
                                          Icons.person_add,
                                          'Right',
                                          Colors.green,
                                          'Follow',
                                          () => controller.swipe(CardSwiperDirection.right),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildIndicator(
    IconData icon,
    String direction,
    Color color,
    String label,
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
            Text(
              direction,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex >= _profiles.length) {
      print('Invalid index: $previousIndex, profiles count: ${_profiles.length}');
      return false;
    }
    
    final profile = _profiles[previousIndex];
    
    // Update current index
    if (currentIndex != null) {
      setState(() {
        _currentIndex = currentIndex;
      });
    }
    
    String action;
    switch (direction) {
      case CardSwiperDirection.left:
        action = 'Remove';
        // Delay the removal to allow the swipe animation to complete
        Future.delayed(const Duration(milliseconds: 300), () {
          _handleRemoveProfile(profile);
        });
        break;
      case CardSwiperDirection.right:
        action = 'Follow';
        // Handle follow action
        _handleFollow(profile);
        break;
      case CardSwiperDirection.top:
        action = 'Send DM';
        // Show DM composer bottom sheet
        _showMessageBottomSheet(context, profile);
        break;
      case CardSwiperDirection.bottom:
      case CardSwiperDirection.none:
        action = 'None';
        break;
    }
    
    print('$action on ${profile.displayNameOrName}');
    
    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    setState(() {
      _currentIndex = currentIndex;
    });
    return true;
  }

  Future<void> _handleRemoveProfile(NostrProfile profile) async {
    try {
      final removed = await _savedProfilesService.removeProfile(profile.pubkey);
      if (removed && mounted) {
        // Check if this is the last card
        if (_profiles.length == 1) {
          // If it's the last card, just clear the list
          setState(() {
            _profiles.clear();
          });
        } else {
          // Remove from local list
          setState(() {
            _profiles.removeWhere((p) => p.pubkey == profile.pubkey);
            // Reset current index if needed
            if (_currentIndex >= _profiles.length) {
              _currentIndex = _profiles.length - 1;
            }
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${profile.displayNameOrName} from saved'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error removing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove profile'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFollow(NostrProfile profile) async {
    try {
      // Call non-blocking follow method
      final success = await _followService.followProfileNonBlocking(profile.pubkey);
      
      if (success && mounted) {
        // Show success immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${profile.displayNameOrName} 🎉'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        // Show failure only if initial check failed (not logged in)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to follow users'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error following profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error following user'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageBottomSheet(BuildContext context, NostrProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
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
            recipient: profile,
            onMessageSent: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}