import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/avatar_helper.dart';

class TestImageScreen extends StatelessWidget {
  const TestImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const u32LukePubkey = '08bfc00b7f72e015f45c326f486bec16e4d5236b70e44543f1c5e86a8e21c76a';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Test u32Luke Image')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Testing u32Luke profile image loading:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Test thumbnail size
            const Text('Thumbnail (200px):'),
            const SizedBox(height: 8),
            _buildTestImage(AvatarHelper.getThumbnail(u32LukePubkey), 'Thumbnail'),
            const SizedBox(height: 24),
            
            // Test medium size
            const Text('Medium (400px):'),
            const SizedBox(height: 8),
            _buildTestImage(AvatarHelper.getMedium(u32LukePubkey), 'Medium'),
            const SizedBox(height: 24),
            
            // Test large size
            const Text('Large (800px):'),
            const SizedBox(height: 8),
            _buildTestImage(AvatarHelper.getLarge(u32LukePubkey), 'Large'),
            const SizedBox(height: 24),
            
            // Direct URL test
            const Text('Direct URL test:'),
            const SizedBox(height: 8),
            _buildTestImage('https://face.yestr.social/avatar/$u32LukePubkey?size=400', 'Direct'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestImage(String url, String label) {
    print('[TestImageScreen] Loading $label image: $url');
    
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          print('[TestImageScreen] Error loading $label image: $error');
          print('[TestImageScreen] Failed URL: $url');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text('Error: ${error.toString()}', textAlign: TextAlign.center),
              ],
            ),
          );
        },
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ),
    );
  }
}