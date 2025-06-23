import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'widgets/responsive_wrapper.dart';
import 'services/nostr_band_api_service.dart';

void main() {
  // Start prefetching trending profiles immediately when the app launches
  NostrBandApiService().prefetchProfiles();
  
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
      home: const LoginScreen(),
    );
  }
}