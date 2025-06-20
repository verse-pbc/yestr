import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  
  // iPhone 13 Pro Max dimensions (max size)
  static const double maxWidth = 428.0;
  static const double maxHeight = 926.0;
  
  // iPhone SE 3rd generation dimensions (min size)
  static const double minWidth = 375.0;
  static const double minHeight = 667.0;
  
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
        // Check if we need to apply any constraints
        final bool needsMaxConstraints = constraints.maxWidth > maxWidth;
        final bool needsMinConstraints = constraints.maxWidth < minWidth || constraints.maxHeight < minHeight;
        
        if (needsMaxConstraints) {
          // Handle large screens - constrain to max size
          final double aspectRatio = maxWidth / maxHeight;
          
          double width = maxWidth;
          double height = maxHeight;
          
          if (constraints.maxHeight < maxHeight) {
            height = constraints.maxHeight;
            width = height * aspectRatio;
          }
          
          if (width > constraints.maxWidth) {
            width = constraints.maxWidth;
            height = width / aspectRatio;
          }
          
          return Container(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    // Main shadow - simulates direct light from above
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 20),
                    ),
                    // Ambient shadow - softer and more spread out
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 10),
                    ),
                    // Close shadow - for depth
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      spreadRadius: -5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(40),
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: child,
                ),
              ),
            ),
          );
        } else if (needsMinConstraints) {
          // Handle small screens - show scrollbars
          return Container(
            color: Colors.transparent,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    width: minWidth,
                    height: minHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        // Main shadow - simulates direct light from above
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 0,
                          offset: const Offset(0, 20),
                        ),
                        // Ambient shadow - softer and more spread out
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 60,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                        // Close shadow - for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 15,
                          spreadRadius: -5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        }
        
        // For medium screens (between min and max), just return the child
        return child;
      },
    );
  }
}