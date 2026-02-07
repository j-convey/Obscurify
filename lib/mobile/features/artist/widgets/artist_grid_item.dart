import 'package:flutter/material.dart';
import 'package:apollo/core/models/artist.dart';

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
              child: ClipOval(
                child: _buildImage(),
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

  Widget _buildImage() {
    if (artist.thumb != null && serverUrl != null && token != null) {
      return Image.network(
        '$serverUrl${artist.thumb}?X-Plex-Token=$token',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}
