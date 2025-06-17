import 'package:flutter/material.dart';
import 'screens/card_overlay_screen.dart';
import 'widgets/responsive_wrapper.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ResponsiveWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const CardOverlayScreen(),
    );
  }
}