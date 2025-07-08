import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bech32/bech32.dart';
import 'dart:async';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nostr_profile.dart';
import '../services/nostr_service.dart';
import '../services/nostr_band_api_service.dart';
import '../services/yestr_relay_service.dart';
import '../services/service_migration_helper.dart';
import '../services/service_migration_helper_web.dart';
import '../services/saved_profiles_service.dart';
import '../services/web_background_service.dart';
import '../widgets/profile_card.dart';
import 'card_overlay_screen_web_init.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dm_composer.dart';
import '../widgets/gradient_background.dart';
import '../services/key_management_service.dart';
import '../services/direct_message_service_v2.dart';
import '../services/dm_notification_service.dart';
import '../screens/messages/conversation_screen.dart';
import '../utils/avatar_helper.dart';
import '../utils/profile_image_preloader.dart';
import '../utils/image_cache_warmer.dart';
import '../services/app_initialization_service.dart';

class CardOverlayScreen extends StatefulWidget {
  const CardOverlayScreen({super.key});

  @override
  State<CardOverlayScreen> createState() => _CardOverlayScreenState();
}

class _CardOverlayScreenState extends State<CardOverlayScreen> with WebNdkInitializer {
  final CardSwiperController controller = CardSwiperController();
  final NostrService _nostrService = NostrService();
  final NostrBandApiService _nostrBandApiService = NostrBandApiService();
  final YestrRelayService _yestrRelayService = YestrRelayService();
  late final dynamic _followService;
  final KeyManagementService _keyService = KeyManagementService();
  late final SavedProfilesService _savedProfilesService;
  late final DirectMessageService _dmService;
  late final DmNotificationService _notificationService;
  List<NostrProfile> _profiles = [];
  bool _isLoading = true;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    
    
    // Initialize services
    _followService = kIsWeb 
        ? ServiceMigrationHelperWeb.getFollowService() 
        : ServiceMigrationHelper.getFollowService();
    _savedProfilesService = SavedProfilesService(_nostrService);
    _dmService = kIsWeb 
        ? ServiceMigrationHelperWeb.getDirectMessageService()
        : ServiceMigrationHelper.getDirectMessageService();
    _notificationService = DmNotificationService(_dmService, _keyService);
    
    // Set main background when screen loads
    WebBackgroundService.setMainBackground();
    
    // Initialize notifications
    _initializeNotifications();
    
    // Start loading conversations in the background immediately after login
    _preloadConversations();
    
    _loadProfiles();
  }
  
  Future<void> _preloadConversations() async {
    try {
      print('[CardOverlayScreen] Starting background conversation preload...');
      
      // Check if user is logged in
      final hasPrivateKey = await _keyService.hasPrivateKey();
      if (!hasPrivateKey) {
        print('[CardOverlayScreen] User not logged in, skipping conversation preload');
        return;
      }
      
      // Wait a bit to ensure NostrService is connected
      // This runs in parallel with profile loading
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          // Ensure NostrService is connected
          if (!_nostrService.isConnected) {
            print('[CardOverlayScreen] Waiting for NostrService connection...');
            await _nostrService.connect();
          }
          
          // Load conversations in the background without blocking UI
          // This will populate the cache so when the user opens Messages, 
          // conversations are already loaded
          print('[CardOverlayScreen] Starting conversation load...');
          await _dmService.loadConversations();
          
          print('[CardOverlayScreen] Background conversation loading completed');
          print('[CardOverlayScreen] Preloaded ${_dmService.conversations.length} conversations');
          
          // Also subscribe to conversation updates to keep them fresh
          _dmService.conversationsStream.listen((conversations) {
            print('[CardOverlayScreen] Background update: ${conversations.length} conversations available');
          });
        } catch (error) {
          print('[CardOverlayScreen] Error in delayed conversation loading: $error');
        }
      });
    } catch (e) {
      print('[CardOverlayScreen] Error in preloadConversations: $e');
    }
  }
  
  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    
    // Clear current conversation since we're on discover screen
    _notificationService.setCurrentConversation(null);
    
    // Listen for DM notifications
    _notificationSubscription = _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        // Show snackbar with custom action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: CachedNetworkImageProvider(
                    AvatarHelper.getThumbnail(notification.senderProfile.pubkey),
                  ),
                  child: notification.senderProfile.picture == null
                      ? Text(
                          notification.senderProfile.displayNameOrName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New message from ${notification.senderProfile.displayNameOrName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        notification.message.content.length > 50
                            ? '${notification.message.content.substring(0, 50)}...'
                            : notification.message.content,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () {
                // Navigate to conversation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationScreen(
                      profile: notification.senderProfile,
                    ),
                  ),
                );
              },
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF2a2c32),
          ),
        );
      }
    });
  }

  Future<void> _loadProfiles() async {
    try {
      // Check if we have preloaded profiles
      final initService = AppInitializationService();
      if (initService.isInitialized && initService.preloadedProfiles.isNotEmpty) {
        print('CardOverlayScreen: Using preloaded profiles');
        
        // Use preloaded profiles immediately
        final preloadedProfiles = initService.preloadedProfiles;
        
        if (mounted) {
          setState(() {
            _profiles = List.from(preloadedProfiles);
            
            // Insert special profile at position 10 if we have enough profiles
            if (_profiles.length >= 10) {
              _insertSpecialProfile();
            }
            
            _isLoading = false;
          });
          
          print('\n=== USING PRELOADED PROFILES ===');
          print('Total profiles: ${_profiles.length}');
          print('================================\n');
        }
        
        // Clear preloaded data to free memory
        initService.clearPreloadedData();
        
        // Connect to Nostr for other services in background
        _nostrService.connect();
        _savedProfilesService.loadSavedProfiles();
        
        return; // Exit early, we're done
      }
      
      // If no preloaded profiles, continue with normal flow
      print('CardOverlayScreen: No preloaded profiles, fetching fresh...');
      
      // Connect to Nostr for other services (follow, saved profiles, etc)
      await _nostrService.connect();
      
      // Load saved profiles (service already listens to events internally)
      await _savedProfilesService.loadSavedProfiles();
      
      bool apiSuccess = false;
      
      // Try to use Yestr Relay for random profiles
      try {
        print('CardOverlayScreen: Fetching random profiles from Yestr relay...');
        final profiles = await _yestrRelayService.getRandomProfiles(count: 50);
        
        if (profiles.isNotEmpty && mounted) {
          // Store profiles but don't update UI yet
          final loadedProfiles = List<NostrProfile>.from(profiles);
          
          // Insert special profile at position 10 if we have enough profiles
          if (loadedProfiles.length >= 10) {
            // Insert special profile into the list
            const specialPubkey = '08bfc00b7f72e015f45c326f486bec16e4d5236b70e44543f1c5e86a8e21c76a'; // u32Luke for debugging
            final specialProfile = NostrProfile(
              pubkey: specialPubkey,
              name: 'u32Luke',
              displayName: 'u32Luke',
              about: 'Mining, markets, and systems design',
              picture: null,
              banner: null,
              nip05: null,
              lud16: null,
              website: null,
              createdAt: DateTime.now(),
            );
            loadedProfiles.insert(9, specialProfile);
          }
          
          // Start preloading images in parallel
          final preloadFuture = ProfileImagePreloader.preloadProfileImages(
            context,
            loadedProfiles.take(10).toList(), // Preload first 10 profiles
            includeThumbnails: false,
            includeMedium: true,
          );
          
          // Don't wait for preload to complete, but give it a small head start
          // This allows images to start loading before UI updates
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
            print('Profile images preloaded successfully');
          }).catchError((e) {
            print('Error preloading images: $e');
          });
          
          // Request special profile if needed
          if (loadedProfiles.length >= 10) {
            _requestSpecificProfile('e77b246867ba5172e22c08b6add1c7de1049de997ad2fe6ea0a352131f9a0e9a');
          }
          
          print('\n=== RANDOM PROFILES LOADED IN APP ===');
          print('Total profiles in app: ${loadedProfiles.length}');
          for (int i = 0; i < loadedProfiles.length && i < 10; i++) {
            print('${i + 1}. ${loadedProfiles[i].pubkey} - ${loadedProfiles[i].displayNameOrName}');
          }
          print('=====================================\n');
        }
      } catch (apiError) {
        print('CardOverlayScreen: Yestr relay fetch failed: $apiError');
        print('CardOverlayScreen: Falling back to Nostr relay profiles');
      }
      
      // If API failed or returned no profiles, fall back to Nostr relay profiles
      if (!apiSuccess) {
        print('\n!!! FALLBACK TO RELAY PROFILES !!!');
        print('CardOverlayScreen: Using Nostr relay profiles as fallback');
        
        // Request profiles from Nostr relays
        await _nostrService.requestProfilesWithLimit(limit: 100);
        
        // Listen for profiles from Nostr
        final profileBuffer = <NostrProfile>[];
        _nostrService.profilesStream.listen((profile) {
          if (mounted) {
            // Buffer profiles to batch UI updates
            profileBuffer.add(profile);
            print('RELAY PROFILE ADDED: ${profile.pubkey} - ${profile.displayNameOrName}');
            
            // Update UI in batches
            if (profileBuffer.length >= 5 || (_profiles.isEmpty && profileBuffer.isNotEmpty)) {
              final newProfiles = List<NostrProfile>.from(profileBuffer);
              profileBuffer.clear();
              
              // Start preloading images for new profiles
              ProfileImagePreloader.preloadProfileImages(
                context,
                newProfiles,
                includeThumbnails: false,
                includeMedium: true,
              );
              
              setState(() {
                _profiles.addAll(newProfiles);
                
                // Insert special profile at position 10 if we have enough profiles
                if (_profiles.length >= 10 && _profiles.length - newProfiles.length < 10) {
                  _insertSpecialProfile();
                }
                
                // Stop loading once we have enough profiles
                if (_profiles.length >= 10) {
                  _isLoading = false;
                }
              });
            }
          }
        });
        
        // Wait a bit for profiles to load
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted && _profiles.isEmpty) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      
      // Listen for any new trending profile fetches
      _nostrBandApiService.profilesStream.listen((profiles) {
        if (mounted && _profiles.isEmpty) {
          final loadedProfiles = List<NostrProfile>.from(profiles);
          
          // Start preloading images immediately
          ProfileImagePreloader.preloadProfileImages(
            context,
            loadedProfiles.take(10).toList(),
            includeThumbnails: false,
            includeMedium: true,
          );
          
          setState(() {
            _profiles = loadedProfiles;
            
            // Insert special profile at position 10 if we have enough profiles
            if (_profiles.length >= 10) {
              _insertSpecialProfile();
            }
          });
        }
      });
    } catch (e) {
      print('Error loading profiles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _insertSpecialProfile() {
    const specialPubkey = '08bfc00b7f72e015f45c326f486bec16e4d5236b70e44543f1c5e86a8e21c76a'; // u32Luke for debugging
    
    // Check if special profile already exists
    if (_profiles.any((p) => p.pubkey == specialPubkey)) {
      return;
    }
    
    print('Inserting special profile at position 10');
    
    // Create a basic profile with the special pubkey
    final specialProfile = NostrProfile(
      pubkey: specialPubkey,
      name: 'u32Luke',
      displayName: 'u32Luke',
      about: 'Mining, markets, and systems design',
      picture: null,
      banner: null,
      nip05: null,
      lud16: null,
      website: null,
      createdAt: DateTime.now(),
    );
    
    // Insert at position 9 (10th card, 0-indexed)
    if (_profiles.length >= 9) {
      _profiles.insert(9, specialProfile);
    } else {
      _profiles.add(specialProfile);
    }
    
    // Request the full profile data
    _requestSpecificProfile(specialPubkey);
  }

  String? _npubToHex(String npub) {
    try {
      final decoded = bech32.decode(npub);
      final data = convertBits(decoded.data, 5, 8, false);
      final hexKey = hex.encode(data);
      print('Decoded npub: $npub to hex: $hexKey');
      return hexKey;
    } catch (e) {
      print('Error decoding npub: $e');
      return null;
    }
  }

  List<int> convertBits(List<int> data, int from, int to, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    for (final value in data) {
      acc = (acc << from) | value;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & ((1 << to) - 1));
      }
    }
    if (pad && bits > 0) {
      result.add((acc << (to - bits)) & ((1 << to) - 1));
    }
    return result;
  }

  void _requestSpecificProfile(String pubkey) async {
    print('Requesting specific profile for pubkey: $pubkey');
    
    // Try to fetch profile from multiple relays directly
    try {
      final profile = await _fetchProfileFromRelays(pubkey);
      if (profile != null && mounted) {
        print('Successfully fetched profile: ${profile.displayNameOrName}');
        setState(() {
          final index = _profiles.indexWhere((p) => p.pubkey == pubkey);
          if (index != -1) {
            _profiles[index] = profile;
            print('Updated special profile at index $index');
          }
        });
      }
    } catch (e) {
      print('Error fetching specific profile: $e');
    }
  }

  Future<NostrProfile?> _fetchProfileFromRelays(String pubkey) async {
    // Use multiple popular relays
    final relays = [
      'wss://relay.damus.io',
      'wss://relay.primal.net',
      'wss://nos.lol',
      'wss://relay.nostr.band',
      'wss://relay.yestr.social',
    ];
    
    for (final relay in relays) {
      try {
        print('Trying to fetch profile from $relay');
        final profile = await _fetchProfileFromRelay(relay, pubkey);
        if (profile != null) {
          return profile;
        }
      } catch (e) {
        print('Failed to fetch from $relay: $e');
      }
    }
    
    return null;
  }

  Future<NostrProfile?> _fetchProfileFromRelay(String relayUrl, String pubkey) async {
    final completer = Completer<NostrProfile?>();
    final subscriptionId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      
      // Send subscription request
      final request = [
        "REQ",
        subscriptionId,
        {
          "kinds": [0],
          "authors": [pubkey],
          "limit": 1,
        }
      ];
      
      channel.sink.add(jsonEncode(request));
      
      // Set up timeout
      final timer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        channel.sink.close();
      });
      
      // Listen for responses
      channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as List<dynamic>;
            if (data.length >= 3 && data[0] == 'EVENT' && data[1] == subscriptionId) {
              final eventData = data[2] as Map<String, dynamic>;
              if (eventData['kind'] == 0) {
                final profile = NostrProfile.fromNostrEvent(eventData);
                print('Fetched profile from $relayUrl: ${profile.displayNameOrName}');
                print('Profile picture URL: ${profile.picture}');
                if (!completer.isCompleted) {
                  completer.complete(profile);
                }
                timer.cancel();
                channel.sink.close();
              }
            }
          } catch (e) {
            print('Error parsing relay response: $e');
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Error connecting to relay $relayUrl: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    controller.dispose();
    // Don't dispose singleton services
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we have profiles but still showing loading
    if (_profiles.length >= 10 && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('CardOverlayScreen: Building widget - isLoading: $_isLoading, profiles: ${_profiles.length}');
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make scaffold transparent to show gradient
        drawerScrimColor: Colors.black.withOpacity(0.6), // Dim background when drawer is open
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
                        child: Text('No profiles found'),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: CardSwiper(
                          controller: controller,
                          cardsCount: _profiles.length,
                          onSwipe: _onSwipe,
                          onUndo: _onUndo,
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
                          ) =>
                              Stack(
                            children: [
                              ProfileCard(
                                profile: _profiles[index],
                                onSkip: () {
                                  // Skip to the next card
                                  controller.swipe(CardSwiperDirection.bottom);
                                },
                              ),
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
                              // Skip overlay
                              if (verticalThresholdPercentage > 50)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.yellow.withOpacity(
                                        ((verticalThresholdPercentage - 50) / 50 * 0.5).clamp(0.0, 0.5),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.skip_next,
                                        size: 100,
                                        color: Colors.white.withOpacity(
                                          ((verticalThresholdPercentage - 50) / 50).clamp(0.0, 1.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
                                      Icons.close,
                                      'Left',
                                      Colors.red,
                                      'Nope',
                                      () => controller.swipe(CardSwiperDirection.left),
                                    ),
                                    _buildIndicator(
                                      Icons.skip_next,
                                      'Down',
                                      Colors.yellow,
                                      'Skip',
                                      () => controller.swipe(CardSwiperDirection.bottom),
                                    ),
                                    _buildIndicator(
                                      Icons.bookmark,
                                      'Up',
                                      Colors.blue,
                                      'Save',
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
    final profile = _profiles[previousIndex];
    
    // Check if we're running low on profiles and fetch more
    if (currentIndex != null && _profiles.length - currentIndex < 10) {
      _loadMoreProfiles();
    }
    
    String action;
    switch (direction) {
      case CardSwiperDirection.left:
        action = 'Nope';
        break;
      case CardSwiperDirection.right:
        action = 'Follow';
        // Handle follow action
        _handleFollow(profile);
        break;
      case CardSwiperDirection.top:
        action = 'Save';
        // Save profile to bookmarks
        _handleSaveProfile(profile);
        break;
      case CardSwiperDirection.bottom:
        action = 'Skip';
        break;
      case CardSwiperDirection.none:
        action = 'None';
        break;
    }
    
    print('$action on ${profile.displayNameOrName}');
    
    // No snack bar messages for swipe actions
    // Follow action (right swipe) has its own feedback in _handleFollow
    
    return true;
  }
  
  Future<void> _loadMoreProfiles() async {
    try {
      print('CardOverlayScreen: Loading more profiles...');
      
      // Note: Nostr Band API returns all trending profiles at once, 
      // so we can't really load "more" trending profiles.
      // We'll just fetch the latest trending profiles again.
      
      try {
        // Try Nostr Band API first
        final newProfiles = await _nostrBandApiService.fetchTrendingProfiles();
        
        if (mounted && newProfiles.isNotEmpty) {
          // Filter out profiles we already have
          final existingPubkeys = _profiles.map((p) => p.pubkey).toSet();
          final uniqueNewProfiles = newProfiles
              .where((p) => !existingPubkeys.contains(p.pubkey))
              .toList();
          
          if (uniqueNewProfiles.isNotEmpty) {
            setState(() {
              // Add new unique profiles at the end
              _profiles.addAll(uniqueNewProfiles);
            });
            
            // Preload new profile images
            ProfileImagePreloader.preloadProfileImages(
              context,
              uniqueNewProfiles.take(5).toList(), // Preload next 5 profiles
              includeThumbnails: false,
              includeMedium: true,
            );
            
            return;
          }
        }
      } catch (apiError) {
        print('CardOverlayScreen: Nostr Band API fetch failed for more profiles: $apiError');
      }
      
      // Fallback to requesting more from Nostr if API fails or returns no new profiles
      print('CardOverlayScreen: Falling back to Nostr for more profiles');
      await _nostrService.requestProfilesWithLimit(limit: 50);
      
    } catch (e) {
      print('Error loading more profiles: $e');
    }
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
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
            recipient: profile,
            onMessageSent: () {
              // Close the bottom sheet after message is sent
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  Future<void> _handleSaveProfile(NostrProfile profile) async {
    try {
      final saved = await _savedProfilesService.saveProfile(profile.pubkey);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${profile.displayNameOrName}'),
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

  Future<void> _handleFollow(NostrProfile profile) async {
    try {
      // Call non-blocking follow method
      final success = await _followService.followProfileNonBlocking(profile.pubkey);
      
      if (success && mounted) {
        // Show success immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${profile.displayNameOrName} 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (!success && mounted) {
        // Show failure only if initial check failed (not logged in)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to follow users'),
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
}