import 'package:flutter/material.dart';
import 'package:apollo/core/models/artist.dart';
import '../../../shared/widgets/plex_image.dart';

class ArtistGridItem extends StatelessWidget {
  final Artist artist;
  final String? serverUrl;
  final String? token;
  final VoidCallback onTap;

  const ArtistGridItem({
    super.key,
    required this.artist,
    this.serverUrl,
    this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Circular artist image
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PlexImage(
                serverUrl: serverUrl,
                token: token,
                thumbPath: artist.thumb,
                placeholderIcon: Icons.person,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Artist name
          Text(
            artist.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            'Artist',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
