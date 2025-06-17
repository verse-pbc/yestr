import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FormattedContent extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;

  const FormattedContent({
    super.key,
    required this.content,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = textStyle ?? theme.textTheme.bodyMedium;
    
    final segments = _parseContentSegments(content);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment.type == _SegmentType.image) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _ImageBlock(imageUrl: segment.content),
          );
        } else {
          return Text(
            segment.content,
            style: defaultTextStyle,
          );
        }
      }).toList(),
    );
  }

  List<_ContentSegment> _parseContentSegments(String content) {
    final segments = <_ContentSegment>[];
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    
    int lastEnd = 0;
    
    for (final match in urlRegex.allMatches(content)) {
      final url = match.group(0)!;
      
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start).trim();
        if (textBefore.isNotEmpty) {
          segments.add(_ContentSegment(_SegmentType.text, textBefore));
        }
      }
      
      if (_isImageUrl(url)) {
        segments.add(_ContentSegment(_SegmentType.image, url));
      } else {
        segments.add(_ContentSegment(_SegmentType.text, url));
      }
      
      lastEnd = match.end;
    }
    
    if (lastEnd < content.length) {
      final remainingText = content.substring(lastEnd).trim();
      if (remainingText.isNotEmpty) {
        segments.add(_ContentSegment(_SegmentType.text, remainingText));
      }
    }
    
    if (segments.isEmpty) {
      segments.add(_ContentSegment(_SegmentType.text, content));
    }
    
    final mergedSegments = <_ContentSegment>[];
    for (final segment in segments) {
      if (mergedSegments.isNotEmpty && 
          mergedSegments.last.type == _SegmentType.text && 
          segment.type == _SegmentType.text) {
        mergedSegments.last = _ContentSegment(
          _SegmentType.text,
          '${mergedSegments.last.content} ${segment.content}',
        );
      } else {
        mergedSegments.add(segment);
      }
    }
    
    return mergedSegments;
  }

  bool _isImageUrl(String url) {
    final imageExtensions = RegExp(
      r'\.(jpg|jpeg|png|gif|webp|bmp|svg)(\?.*)?$',
      caseSensitive: false,
    );
    
    if (imageExtensions.hasMatch(url)) {
      return true;
    }
    
    final imageHosts = [
      'imgur.com',
      'i.imgur.com',
      'pbs.twimg.com',
      'media.tenor.com',
      'i.redd.it',
      'media.discordapp.net',
      'cdn.discordapp.com',
      'imageproxy.iris.to',
      'imgproxy.iris.to',
      'i.nostr.build',
      'nostr.build',
      'void.cat',
      'media.nicecrew.digital',
      'media.discordapp.com',
      'cdn.nostr.build',
    ];
    
    try {
      final uri = Uri.parse(url);
      return imageHosts.any((host) => uri.host.contains(host));
    } catch (e) {
      return false;
    }
  }
}

class _ImageBlock extends StatelessWidget {
  final String imageUrl;

  const _ImageBlock({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SegmentType {
  text,
  image,
}

class _ContentSegment {
  final _SegmentType type;
  final String content;

  _ContentSegment(this.type, this.content);
}