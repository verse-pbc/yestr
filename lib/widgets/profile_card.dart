import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nostr_profile.dart';
import '../screens/profile/profile_screen.dart';

class ProfileCard extends StatelessWidget {
  final NostrProfile profile;
  final VoidCallback? onSkip;

  const ProfileCard({
    super.key,
    required this.profile,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              profile: profile,
              onSkip: onSkip,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070809), // Dark background color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: profile.picture != null
                  ? Builder(
                      builder: (context) {
                        return CachedNetworkImage(
                          imageUrl: profile.picture!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayNameOrName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.nip05 != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.nip05!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (profile.about != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.about!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}