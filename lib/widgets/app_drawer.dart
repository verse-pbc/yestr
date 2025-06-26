import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/key_management_service.dart';
import '../services/web_background_service.dart';
import '../services/direct_message_service.dart';
import '../services/dm_notification_service.dart';
import '../screens/login_screen.dart';
import '../screens/saved_profiles_screen.dart';
import '../screens/card_overlay_screen.dart';
import '../screens/messages/messages_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final KeyManagementService _keyService = KeyManagementService();
  late final DirectMessageService _dmService;
  late final DmNotificationService _notificationService;
  bool _isLoggedIn = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _dmService = DirectMessageService(_keyService);
    _notificationService = DmNotificationService(_dmService, _keyService);
    _checkLoginStatus();
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    
    // Listen to unread count changes
    _notificationService.totalUnreadStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
    
    // Get initial unread count
    setState(() {
      _unreadCount = _notificationService.totalUnreadCount;
    });
  }

  Future<void> _checkLoginStatus() async {
    final hasKey = await _keyService.hasPrivateKey();
    setState(() {
      _isLoggedIn = hasKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check which screen we're on by checking the widget tree
    bool isOnSavedScreen = false;
    bool isOnMessagesScreen = false;
    context.visitAncestorElements((element) {
      final typeName = element.widget.runtimeType.toString();
      if (typeName == 'SavedProfilesScreen') {
        isOnSavedScreen = true;
        return false;
      } else if (typeName == 'MessagesScreen') {
        isOnMessagesScreen = true;
        return false;
      }
      return true;
    });
    
    final isOnDiscoverScreen = !isOnSavedScreen && !isOnMessagesScreen;

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
                    if (!isOnDiscoverScreen) {
                      // Navigate back to Discover screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CardOverlayScreen(),
                        ),
                      );
                    }
                  },
                  isSelected: isOnDiscoverScreen,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.message,
                  title: 'Messages',
                  badge: _unreadCount > 0 ? _unreadCount.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isOnMessagesScreen) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagesScreen(),
                        ),
                      );
                    }
                  },
                  isSelected: isOnMessagesScreen,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bookmark,
                  title: 'Saved',
                  onTap: () {
                    Navigator.pop(context);
                    if (!isOnSavedScreen) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedProfilesScreen(),
                        ),
                      );
                    }
                  },
                  isSelected: isOnSavedScreen,
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
    String? badge,
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
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: Colors.black,
              ),
              if (badge != null)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: Colors.white70,
          ),
          if (badge != null)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
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