import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageLightbox extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageLightbox({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  State<ImageLightbox> createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<ImageLightbox> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _showCloseButton = false;
  double _dragDistance = 0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    Matrix4 matrix = _transformationController.value;
    
    // If zoomed in, zoom out to fit
    if (matrix.getMaxScaleOnAxis() > 1.0) {
      _animation = Matrix4Tween(
        begin: matrix,
        end: Matrix4.identity(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
    } else {
      // Zoom to 100% (assuming the image is initially scaled to fit)
      _animation = Matrix4Tween(
        begin: matrix,
        end: Matrix4.identity()..scale(2.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
    }

    _animation!.addListener(() {
      setState(() {
        _transformationController.value = _animation!.value;
      });
    });

    _animationController.forward(from: 0);
  }

  void _handleSingleTap() {
    setState(() {
      _showCloseButton = !_showCloseButton;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.error,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(_opacity),
      body: GestureDetector(
        onTap: _handleSingleTap,
        onDoubleTap: _handleDoubleTap,
        onVerticalDragStart: (_) {
          setState(() {
            _dragDistance = 0;
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragDistance += details.delta.dy;
            // Calculate opacity based on drag distance
            _opacity = (1 - (_dragDistance.abs() / 300)).clamp(0.3, 1.0);
          });
        },
        onVerticalDragEnd: (details) {
          // If dragged more than 100 pixels or with sufficient velocity, close
          if (_dragDistance.abs() > 100 || details.velocity.pixelsPerSecond.dy.abs() > 300) {
            Navigator.of(context).pop();
          } else {
            // Spring back
            setState(() {
              _dragDistance = 0;
              _opacity = 1.0;
            });
          }
        },
        child: Stack(
          children: [
            // Image with drag transform
            Transform.translate(
              offset: Offset(0, _dragDistance),
              child: widget.heroTag != null
                  ? Hero(
                      tag: widget.heroTag!,
                      child: imageWidget,
                    )
                  : imageWidget,
            ),
            // Close button
            if (_showCloseButton)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}