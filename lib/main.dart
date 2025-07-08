import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen.dart';
import 'screens/test_image_screen.dart';
import 'widgets/responsive_wrapper.dart';
import 'widgets/app_initialization_wrapper.dart';
import 'services/nostr_band_api_service.dart';
import 'services/yestr_relay_service.dart';
import 'services/service_migration_helper.dart';
import 'services/service_migration_helper_web.dart';
import 'services/app_initialization_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize NDK services
  try {
    await ServiceMigrationHelper.enableNdkServices();
    debugPrint('NDK services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing NDK services: $e');
    debugPrint('Falling back to legacy services');
    ServiceMigrationHelper.disableNdkServices();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Card Swiper Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.pink,
          secondary: Colors.pinkAccent,
          surface: Color(0xFF2c2c37),
          background: Color(0xFF1a1c22),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF2c2c37),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.pink,
          secondary: Colors.pinkAccent,
          surface: Color(0xFF2c2c37),
          background: Color(0xFF1a1c22),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF2c2c37),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return ResponsiveWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppInitializationWrapper(),
      routes: {
        '/test-image': (context) => const TestImageScreen(),
      },
    );
  }
}