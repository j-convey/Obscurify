import 'package:flutter/material.dart';
import '../../../../core/models/track.dart';
import 'plex_image.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final String? serverUrl;
  final String? token;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final int? index;
  final bool showIndex;

  const TrackTile({
    super.key,
    required this.track,
    this.serverUrl,
    this.token,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.index,
    this.showIndex = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIndex && index != null) ...[
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
          ],
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PlexImage(
              serverUrl: serverUrl,
              token: token,
              thumbPath: track.thumb,
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      title: Text(
        track.title,
        style: const TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w500
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artistName,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
