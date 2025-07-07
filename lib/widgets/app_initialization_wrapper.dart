import 'package:flutter/material.dart';
import '../services/app_initialization_service.dart';
import '../screens/login_screen.dart';

/// Wrapper widget that handles app initialization
class AppInitializationWrapper extends StatelessWidget {
  const AppInitializationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Start initialization immediately when context is available
    final initService = AppInitializationService();
    if (!initService.isInitialized && context.mounted) {
      // Use Future.microtask to ensure this runs after build
      Future.microtask(() => initService.initialize(context));
    }
    
    // Always show LoginScreen, initialization happens in background
    return const LoginScreen();
  }
}