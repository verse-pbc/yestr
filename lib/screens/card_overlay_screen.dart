import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bech32/bech32.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nostr_profile.dart';
import '../services/nostr_service.dart';
import '../services/follow_service.dart';
import '../services/web_background_service.dart';
import '../widgets/profile_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dm_composer.dart';

class CardOverlayScreen extends StatefulWidget {
  const CardOverlayScreen({super.key});

  @override
  State<CardOverlayScreen> createState() => _CardOverlayScreenState();
}

class _CardOverlayScreenState extends State<CardOverlayScreen> {
  final CardSwiperController controller = CardSwiperController();
  final NostrService _nostrService = NostrService();
  final FollowService _followService = FollowService();
  List<NostrProfile> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set main background when screen loads
    WebBackgroundService.setMainBackground();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      await _nostrService.connect();
      
      // Special profile to insert at position 10
      const specialPubkey = 'e77b246867ba5172e22c08b6add1c7de1049de997ad2fe6ea0a352131f9a0e9a';
      print('Special profile pubkey: $specialPubkey');
      
      // Listen for profiles
      _nostrService.profilesStream.listen((profile) {
        if (mounted) {
          setState(() {
            // Check if this is an update for the special profile
            if (profile.pubkey == specialPubkey) {
              // Find and update the special profile if it's already in the list
              final index = _profiles.indexWhere((p) => p.pubkey == specialPubkey);
              if (index != -1) {
                _profiles[index] = profile;
                print('Updated special profile with real data: ${profile.displayNameOrName}');
                return;
              }
            }
            
            // Insert special profile at position 9 (10th card, 0-indexed)
            if (_profiles.length == 9) {
              print('Inserting special profile at position 10');
              // Create a basic profile with the special pubkey
              final specialProfile = NostrProfile(
                pubkey: specialPubkey,
                name: 'Special Profile',
                displayName: 'Special Profile',
                about: 'Loading profile...',
                picture: null,
                banner: null,
                nip05: null,
                lud16: null,
                website: null,
                createdAt: DateTime.now(),
              );
              _profiles.add(specialProfile);
              
              // Send a specific request for this profile
              _requestSpecificProfile(specialPubkey);
            }
            
            // Add regular profiles
            if (_profiles.length < 50) {
              _profiles.add(profile);
              if (_profiles.length >= 50) {
                _isLoading = false;
              }
            }
          });
        }
      });

      // Wait a bit for profiles to load
      await Future.delayed(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profiles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    controller.dispose();
    _nostrService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                          numberOfCardsDisplayed: 3,
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
                                      Icons.message,
                                      'Up',
                                      Colors.blue,
                                      'Send DM',
                                      () {
                                        // For Send DM, we need to get the current profile and show the composer
                                        if (_profiles.isNotEmpty && _currentIndex < _profiles.length) {
                                          _showMessageBottomSheet(context, _profiles[_currentIndex]);
                                        }
                                      },
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
    
    // Update current index
    if (currentIndex != null) {
      setState(() {
        _currentIndex = currentIndex;
      });
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
        action = 'Send DM';
        // Show DM composer bottom sheet
        _showMessageBottomSheet(context, profile);
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

  Future<void> _handleFollow(NostrProfile profile) async {
    try {
      final success = await _followService.followProfile(profile.pubkey);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Following ${profile.displayNameOrName}'),
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
}