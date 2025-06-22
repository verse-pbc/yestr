import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/key_management_service.dart';
import '../services/web_background_service.dart';
import '../screens/login_screen.dart';
import '../screens/saved_profiles_screen.dart';
import '../screens/card_overlay_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final KeyManagementService _keyService = KeyManagementService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final hasKey = await _keyService.hasPrivateKey();
    setState(() {
      _isLoggedIn = hasKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current route to determine which item is selected
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    return Drawer(
      backgroundColor: const Color(0xFF1a1c22),
      child: Column(
        children: [
          // Drawer Header with Yestr Logo
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1a1c22),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/yestr_logo.svg',
                height: 60,
              ),
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: Column(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.explore,
                  title: 'Discover',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (currentRoute != '/' && currentRoute != '/discover') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CardOverlayScreen(),
                          settings: const RouteSettings(name: '/discover'),
                        ),
                      );
                    }
                  },
                  isSelected: currentRoute == '/' || currentRoute == '/discover' || currentRoute == null,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bookmark,
                  title: 'Saved',
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/saved') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedProfilesScreen(),
                          settings: const RouteSettings(name: '/saved'),
                        ),
                      );
                    }
                  },
                  isSelected: currentRoute == '/saved',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon!')),
                    );
                  },
                  isSelected: false,
                ),
              ],
            ),
          ),
          
          // Logout at bottom (only show if logged in)
          if (_isLoggedIn) ...[
            const Divider(color: Colors.grey),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                // Clear stored keys
                await _keyService.clearKeys();
                
                // Set login background before navigating
                WebBackgroundService.setLoginBackground();
                
                // Navigate to login screen and remove all previous routes
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    if (isSelected) {
      // Special styling for selected item (Discover)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFbaf27c),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            icon,
            color: Colors.black,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: onTap,
        ),
      );
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon,
        color: Colors.white70,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}