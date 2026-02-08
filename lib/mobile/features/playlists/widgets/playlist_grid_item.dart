import 'package:flutter/material.dart';
import '../../../../core/models/playlist.dart';
import '../../../shared/widgets/plex_image.dart';

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
                child: PlexImage(
                  serverUrl: serverUrl,
                  token: token,
                  thumbPath: playlist.composite,
                  borderRadius: BorderRadius.circular(8),
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
}
