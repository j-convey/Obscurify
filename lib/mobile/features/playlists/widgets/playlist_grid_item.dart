import 'package:flutter/material.dart';
import '../../../../core/models/playlist.dart';

class PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;
  final String? serverUrl;
  final String? token;
  final VoidCallback onTap;

  const PlaylistGridItem({
    super.key,
    required this.playlist,
    this.serverUrl,
    this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square playlist image
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Playlist title
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Song count
          Text(
            '${playlist.leafCount} songs',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (playlist.composite != null && serverUrl != null && token != null) {
      return Image.network(
        '$serverUrl${playlist.composite}?X-Plex-Token=$token',
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
          Icons.music_note,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}
