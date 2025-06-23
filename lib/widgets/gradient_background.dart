import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2c2c37), // Top color
            Color(0xFF1a1c22), // Bottom color
          ],
        ),
      ),
      child: child,
    );
  }
}