import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/key_management_service.dart';
import '../services/ndk_backup/ndk_service.dart';
import '../services/follow_service_ndk.dart';
import '../services/web_background_service.dart';
import '../services/service_migration_helper.dart';
import '../services/ndk_backup/ndk_service.dart';
import '../widgets/gradient_background.dart';
import 'card_overlay_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  final KeyManagementService _keyService = KeyManagementService();
  final NdkService _ndkService = NdkService.instance;
  bool _isProcessing = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    // Set login background when screen loads
    WebBackgroundService.setLoginBackground();
  }

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _handlePrivateKeyInput() async {
    final String privateKey = _privateKeyController.text.trim();
    
    if (privateKey.isEmpty) {
      _showError('Please enter a private key');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final loginStartTime = DateTime.now();
      debugPrint('⏱️ [${loginStartTime.toIso8601String()}] Starting login process...');
      
      // Store the private key
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] Storing private key...');
      await _keyService.storePrivateKey(privateKey);
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] Private key stored (took ${DateTime.now().difference(loginStartTime).inMilliseconds}ms)');
      
      // Also login to NDK with the private key
      final ndkLoginStart = DateTime.now();
      debugPrint('⏱️ [${ndkLoginStart.toIso8601String()}] Logging into NDK...');
      await _ndkService.login(privateKey);
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] NDK login successful (took ${DateTime.now().difference(ndkLoginStart).inMilliseconds}ms)');
      
      // Verify NDK login
      final ndkPubkey = _ndkService.currentUserPubkey;
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] NDK current user pubkey: $ndkPubkey');
      
      // Skip loading contact list during login to improve speed
      // It will be loaded on-demand when needed
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] Skipping contact list load for faster login');
      
      final totalLoginTime = DateTime.now().difference(loginStartTime);
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] ✅ Login process completed (total: ${totalLoginTime.inMilliseconds}ms)');
      
      // Also login to NDK if it's enabled
      if (ServiceMigrationHelper.isUsingNdk) {
        try {
          await NdkService.instance.login(privateKey);
          print('NDK login successful after storing private key');
        } catch (ndkError) {
          print('Warning: NDK login failed: $ndkError');
          // Continue anyway - the key is stored and will be loaded on next app start
        }
      }
      
      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CardOverlayScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('⏱️ [${DateTime.now().toIso8601String()}] ❌ Login error: $e');
      _showError('Invalid private key: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleSkip() async {
    // Navigate without login for read-only mode
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const CardOverlayScreen(),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: SvgPicture.asset(
                  'assets/images/yestr_logo.svg',
                  height: 80,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to Yestr',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Discover interesting profiles from the Nostr network',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Private key input
              TextField(
                controller: _privateKeyController,
                obscureText: _isObscured,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Private Key (nsec or hex)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'nsec1...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  helperText: 'Your private key is stored locally and never sent to any server',
                  helperStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                      if (_privateKeyController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _privateKeyController.clear();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Login button
              ElevatedButton(
                onPressed: _isProcessing ? null : _handlePrivateKeyInput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login with Private Key',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Skip button
              OutlinedButton(
                onPressed: _isProcessing ? null : _handleSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Skip for now (Read-only)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}