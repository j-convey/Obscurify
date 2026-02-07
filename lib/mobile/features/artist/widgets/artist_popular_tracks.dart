import 'package:flutter/material.dart';
import '../../../../core/models/track.dart';

class ArtistPopularTrackItem extends StatelessWidget {
  final int index;
  final Track track;
  final String? imageUrl;
  final VoidCallback onTap;

  const ArtistPopularTrackItem({
    super.key,
    required this.index,
    required this.track,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(4),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.grey),
                    ),
                  )
                : const Icon(Icons.music_note, color: Colors.grey),
          ),
        ],
      ),
      title: Text(
        track.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          // TODO: Add play count or other metadata here if available
          // For now just indicator if explicit, etc.
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.isLiked)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
