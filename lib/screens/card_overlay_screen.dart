import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/nostr_profile.dart';
import '../services/nostr_service.dart';
import '../widgets/profile_card.dart';

class CardOverlayScreen extends StatefulWidget {
  const CardOverlayScreen({super.key});

  @override
  State<CardOverlayScreen> createState() => _CardOverlayScreenState();
}

class _CardOverlayScreenState extends State<CardOverlayScreen> {
  final CardSwiperController controller = CardSwiperController();
  final NostrService _nostrService = NostrService();
  List<NostrProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      await _nostrService.connect();
      
      // Listen for profiles
      _nostrService.profilesStream.listen((profile) {
        if (mounted && _profiles.length < 10) {
          setState(() {
            _profiles.add(profile);
            if (_profiles.length >= 10) {
              _isLoading = false;
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

  @override
  void dispose() {
    controller.dispose();
    _nostrService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/yestr_logo.svg',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
                          padding: const EdgeInsets.all(24.0),
                          cardBuilder: (
                            context,
                            index,
                            horizontalThresholdPercentage,
                            verticalThresholdPercentage,
                          ) =>
                              Stack(
                            children: [
                              ProfileCard(profile: _profiles[index]),
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
                              // Super like overlay
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
                                        Icons.star,
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
                                    ),
                                    _buildIndicator(
                                      Icons.favorite,
                                      'Right',
                                      Colors.green,
                                      'Like',
                                    ),
                                    _buildIndicator(
                                      Icons.star,
                                      'Up',
                                      Colors.blue,
                                      'Super Like',
                                    ),
                                    _buildIndicator(
                                      Icons.skip_next,
                                      'Down',
                                      Colors.yellow,
                                      'Skip',
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
    );
  }

  Widget _buildIndicator(
    IconData icon,
    String direction,
    Color color,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
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
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final profile = _profiles[previousIndex];
    String action;
    switch (direction) {
      case CardSwiperDirection.left:
        action = 'Nope';
        break;
      case CardSwiperDirection.right:
        action = 'Like';
        break;
      case CardSwiperDirection.top:
        action = 'Super Like';
        break;
      case CardSwiperDirection.bottom:
        action = 'Skip';
        break;
      case CardSwiperDirection.none:
        action = 'None';
        break;
    }
    
    print('$action on ${profile.displayNameOrName}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action ${profile.displayNameOrName}'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: direction == CardSwiperDirection.right
            ? Colors.green
            : direction == CardSwiperDirection.left
                ? Colors.red
                : direction == CardSwiperDirection.top
                    ? Colors.blue
                    : Colors.orange,
      ),
    );
    
    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    return true;
  }
}