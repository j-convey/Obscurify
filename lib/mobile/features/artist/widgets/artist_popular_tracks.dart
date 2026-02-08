import 'package:flutter/material.dart';
import '../../../../core/models/track.dart';
import '../../../shared/widgets/track_tile.dart';

class ArtistPopularTrackItem extends StatelessWidget {
  final int index;
  final Track track;
  final String? serverUrl;
  final String? token;
  final VoidCallback onTap;

  const ArtistPopularTrackItem({
    super.key,
    required this.index,
    required this.track,
    this.serverUrl,
    this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TrackTile(
      track: track,
      serverUrl: serverUrl,
      token: token,
      index: index,
      showIndex: true,
      onTap: onTap,
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
    );
  }
}
