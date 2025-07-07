import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../models/nostr_profile.dart';
import '../services/nostr_service.dart';
import '../services/nostr_band_api_service.dart';
import '../services/saved_profiles_service.dart';
import '../services/service_migration_helper.dart';
import '../widgets/profile_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_background.dart';
import '../widgets/dm_composer.dart';
import '../services/key_management_service.dart';
import '../services/direct_message_service_v2.dart';
import '../utils/profile_image_preloader.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final CardSwiperController controller = CardSwiperController();
  final NostrService _nostrService = NostrService();
  final NostrBandApiService _nostrBandApiService = NostrBandApiService();
  late final dynamic _followService;
  final KeyManagementService _keyService = KeyManagementService();
  late final SavedProfilesService _savedProfilesService;
  late final DirectMessageService _dmService;
  List<NostrProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize services
    _followService = ServiceMigrationHelper.getFollowService();
    _savedProfilesService = SavedProfilesService(_nostrService);
    _dmService = ServiceMigrationHelper.getDirectMessageService();
    
    _loadTrendingProfiles();
  }

  Future<void> _loadTrendingProfiles() async {
    try {
      // Connect to Nostr for other services (follow, saved profiles, etc)
      await _nostrService.connect();
      
      // Load saved profiles (service already listens to events internally)
      await _savedProfilesService.loadSavedProfiles();
      
      bool apiSuccess = false;
      
      // Try to use Nostr Band API for trending profiles
      try {
        print('TrendingScreen: Fetching trending profiles...');
        _nostrBandApiService.clearCache();
        final profiles = await _nostrBandApiService.fetchTrendingProfiles();
        
        if (profiles.isNotEmpty && mounted) {
          // Store profiles but don't update UI yet
          final loadedProfiles = List<NostrProfile>.from(profiles);
          
          // Start preloading images in parallel
          final preloadFuture = ProfileImagePreloader.preloadProfileImages(
            context,
            loadedProfiles.take(10).toList(), // Preload first 10 profiles
            includeThumbnails: false,
            includeMedium: true,
          );
          
          // Give images a small head start to begin loading
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Now update the UI
          if (mounted) {
            setState(() {
              _profiles = loadedProfiles;
              _isLoading = false;
            });
            apiSuccess = true;
          }
          
          // Continue preloading in background
          preloadFuture.then((_) {
            print('Trending profile images preloaded successfully');
          }).catchError((e) {
            print('Error preloading trending images: $e');
          });
          
          print('\n=== TRENDING PROFILES LOADED ===');
          print('Total profiles: ${loadedProfiles.length}');
          print('================================\n');
        }
      } catch (apiError) {
        print('TrendingScreen: Nostr Band API fetch failed: $apiError');
        print('TrendingScreen: Falling back to Nostr relay profiles');
      }
      
      // If API failed or returned no profiles, fall back to Nostr relay profiles
      if (!apiSuccess) {
        await _nostrService.requestProfilesWithLimit(limit: 50, useTrendingProfiles: true);
        
        // Set a timeout to ensure we update the UI even if not all profiles load
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _profiles = List.from(_nostrService.profiles);
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      print('TrendingScreen: Error loading profiles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwipe(String pubkey, bool isLike) async {
    if (isLike) {
      await _handleMatch(pubkey);
    }
  }

  Future<void> _handleMatch(String pubkey) async {
    try {
      // Call non-blocking follow method
      final success = await _followService.followProfileNonBlocking(pubkey);
      
      if (success && mounted) {
        // Show success immediately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Followed! 🎉'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Note: No error snackbar here since user might not be logged in
      // and we don't want to interrupt the swiping flow
    } catch (e) {
      print('Error following profile: $e');
    }
  }

  Future<bool> _handleSwipeAction(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (previousIndex < _profiles.length) {
      final profile = _profiles[previousIndex];
      
      switch (direction) {
        case CardSwiperDirection.right:
          await _handleSwipe(profile.pubkey, true);
          break;
        case CardSwiperDirection.left:
          await _handleSwipe(profile.pubkey, false);
          break;
        case CardSwiperDirection.top:
          // Save profile
          await _savedProfilesService.saveProfile(profile.pubkey);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile saved! 💙'),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.blue,
              ),
            );
          }
          break;
        case CardSwiperDirection.bottom:
          // Skip - do nothing
          break;
        case CardSwiperDirection.none:
          // No swipe action
          break;
      }
    }
    
    return true;
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

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawerScrimColor: Colors.black.withOpacity(0.6),
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            // App bar layer (bottom layer - lowest z-index)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1c22), // Dark background for app bar
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
                        child: SvgPicture.asset(
                          'assets/images/yestr_logo.svg',
                          height: 40,
                        ),
                      ),
                      centerTitle: true,
                      toolbarHeight: kToolbarHeight + 8,
                      titleSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            // Cards layer (top layer - highest z-index) - takes full screen
            SafeArea(
              top: false, // Allow cards to extend under the app bar
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _profiles.isEmpty
                      ? const Center(
                          child: Text(
                            'No trending profiles available',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: CardSwiper(
                              controller: controller,
                              cardsCount: _profiles.length,
                              onSwipe: _handleSwipeAction,
                              numberOfCardsDisplayed: _profiles.length >= 3 ? 3 : _profiles.length,
                              backCardOffset: const Offset(40, 40),
                              padding: const EdgeInsets.only(
                                left: 24.0,
                                right: 24.0,
                                top: kToolbarHeight + 32.0, // Add space for app bar plus some padding
                                bottom: 24.0,
                              ),
                              cardBuilder: (
                                context,
                                index,
                                horizontalThresholdPercentage,
                                verticalThresholdPercentage,
                              ) {
                                final profile = _profiles[index];
                                return GestureDetector(
                                  onDoubleTap: () {
                                    _showMessageBottomSheet(context, profile);
                                  },
                                  child: Stack(
                                    children: [
                                      ProfileCard(
                                        profile: profile,
                                        onSkip: () => controller.swipe(CardSwiperDirection.bottom),
                                      ),
                                      // Swipe indicators
                                      // Like overlay
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
                                                Icons.favorite,
                                                size: 100,
                                                color: Colors.white.withOpacity(
                                                  ((horizontalThresholdPercentage - 50) / 50).clamp(0.0, 1.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Nope overlay
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
                                                Icons.close,
                                                size: 100,
                                                color: Colors.white.withOpacity(
                                                  ((horizontalThresholdPercentage.abs() - 50) / 50).clamp(0.0, 1.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Save overlay
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
                                                Icons.bookmark,
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
                                );
                              },
                            ),
                          ),
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.close,
                                color: Colors.red,
                                onPressed: () => controller.swipe(CardSwiperDirection.left),
                              ),
                              _buildActionButton(
                                icon: Icons.skip_next,
                                color: Colors.yellow,
                                onPressed: () => controller.swipe(CardSwiperDirection.bottom),
                              ),
                              _buildActionButton(
                                icon: Icons.bookmark,
                                color: Colors.blue,
                                onPressed: () => controller.swipe(CardSwiperDirection.top),
                              ),
                              _buildActionButton(
                                icon: Icons.favorite,
                                color: Colors.green,
                                onPressed: () => controller.swipe(CardSwiperDirection.right),
                              ),
                            ],
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: color.withOpacity(0.2),
      elevation: 0,
      child: Icon(icon, color: color, size: 30),
    );
  }
}