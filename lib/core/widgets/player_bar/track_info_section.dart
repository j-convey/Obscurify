import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import '../../services/plex/plex_services.dart';
import '../../../features/artist/artist_page.dart';

class TrackInfoSection extends StatelessWidget {
  final Map<String, dynamic> track;
  final AudioPlayerService playerService;
  final void Function(Widget)? onNavigate;

  const TrackInfoSection({
    super.key,
    required this.track,
    required this.playerService,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final serverService = PlexServerService();

    return Row(
      children: [
        // Album art
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: track['thumb'] != null &&
                  playerService.currentServerUrl != null &&
                  playerService.currentToken != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    '${playerService.currentServerUrl}${track['thumb']}?X-Plex-Token=${playerService.currentToken}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.music_note,
                        color: Colors.grey,
                      );
                    },
                  ),
                )
              : const Icon(
                  Icons.music_note,
                  color: Colors.grey,
                ),
        ),
        const SizedBox(width: 12),
        // Track details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                track['title'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final artistId = track['grandparentRatingKey']?.toString();
                  final artistName = track['artist'] as String? ??
                      track['grandparentTitle'] as String? ??
                      'Unknown Artist';
                  final token = playerService.currentToken;
                  final trackServerId = track['serverId'] as String?;

                  // Use centralized server URL lookup
                  String? serverUrl = playerService.currentServerUrl;
                  if (token != null && trackServerId != null) {
                    try {
                      serverUrl = await serverService.getUrlForServer(token, trackServerId);
                      debugPrint('PLAYER_BAR: Got URL for server $trackServerId: $serverUrl');
                    } catch (e) {
                      debugPrint('PLAYER_BAR: Error getting server URL: $e');
                    }
                  }
                  
                  // Fallback to current server URL if lookup failed
                  serverUrl ??= playerService.currentServerUrl;

                  debugPrint('PLAYER_BAR: Artist tap - artistId: $artistId, serverUrl: $serverUrl, token exists: ${token != null}');

                  if (artistId != null &&
                      serverUrl != null &&
                      token != null &&
                      onNavigate != null) {
                    debugPrint('PLAYER_BAR: Navigating to artist page for: $artistName with serverUrl: $serverUrl');
                    onNavigate!(
                      ArtistPage(
                        artistId: artistId,
                        artistName: artistName,
                        serverUrl: serverUrl,
                        token: token,
                        audioPlayerService: playerService,
                        onNavigate: onNavigate,
                      ),
                    );
                  } else {
                    debugPrint('PLAYER_BAR: Cannot navigate - missing data. artistId: $artistId, serverUrl: $serverUrl, token: ${token != null}, onNavigate: ${onNavigate != null}');
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    track['artist'] as String? ?? 'Unknown Artist',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Like button
        IconButton(
          icon: const Icon(Icons.favorite_border, size: 20),
          color: Colors.grey[400],
          onPressed: () {
            // TODO: Implement like functionality
          },
        ),
      ],
    );
  }
}
