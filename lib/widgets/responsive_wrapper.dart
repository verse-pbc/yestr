import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  // iPhone 13 Pro Max dimensions
  static const double maxWidth = 428.0;
  static const double maxHeight = 926.0;
  
  const ResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only apply constraints on web platform
    if (!kIsWeb) {
      return child;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the screen is larger than our max dimensions
        final bool needsConstraints = constraints.maxWidth > maxWidth;
        
        if (needsConstraints) {
          // Calculate the aspect ratio to maintain
          final double aspectRatio = maxWidth / maxHeight;
          
          // Calculate the actual dimensions to use
          double width = maxWidth;
          double height = maxHeight;
          
          // If the available height is less than our max height, adjust proportionally
          if (constraints.maxHeight < maxHeight) {
            height = constraints.maxHeight;
            width = height * aspectRatio;
          }
          
          // If the calculated width is still too large, constrain by width instead
          if (width > constraints.maxWidth) {
            width = constraints.maxWidth;
            height = width / aspectRatio;
          }
          
          return Container(
            color: Colors.grey[900], // Dark background for the surrounding area
            child: Center(
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(40), // Rounded corners like a phone
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: child,
                ),
              ),
            ),
          );
        }
        
        // On smaller screens, just return the child as-is
        return child;
      },
    );
  }
}