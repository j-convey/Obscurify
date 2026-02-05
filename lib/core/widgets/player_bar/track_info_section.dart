import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import '../../services/plex/plex_services.dart';
import '../../../features/artist/artist_page.dart';

class TrackInfoSection extends StatefulWidget {
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
  State<TrackInfoSection> createState() => _TrackInfoSectionState();
}

class _TrackInfoSectionState extends State<TrackInfoSection> {
  bool _isArtistHovered = false;

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
          child: widget.track['thumb'] != null &&
                  widget.playerService.currentServerUrl != null &&
                  widget.playerService.currentToken != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    '${widget.playerService.currentServerUrl}${widget.track['thumb']}?X-Plex-Token=${widget.playerService.currentToken}',
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
                widget.track['title'] as String,
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
                  final artistId = widget.track['grandparentRatingKey']?.toString();
                  final artistName = widget.track['artist'] as String? ??
                      widget.track['grandparentTitle'] as String? ??
                      'Unknown Artist';
                  final token = widget.playerService.currentToken;
                  final trackServerId = widget.track['serverId'] as String?;

                  // Use centralized server URL lookup
                  String? serverUrl = widget.playerService.currentServerUrl;
                  if (token != null && trackServerId != null) {
                    try {
                      serverUrl = await serverService.getUrlForServer(token, trackServerId);
                      debugPrint('PLAYER_BAR: Got URL for server $trackServerId: $serverUrl');
                    } catch (e) {
                      debugPrint('PLAYER_BAR: Error getting server URL: $e');
                    }
                  }
                  
                  // Fallback to current server URL if lookup failed
                  serverUrl ??= widget.playerService.currentServerUrl;

                  debugPrint('PLAYER_BAR: Artist tap - artistId: $artistId, serverUrl: $serverUrl, token exists: ${token != null}');

                  if (artistId != null &&
                      serverUrl != null &&
                      token != null &&
                      widget.onNavigate != null) {
                    debugPrint('PLAYER_BAR: Navigating to artist page for: $artistName with serverUrl: $serverUrl');
                    widget.onNavigate!(
                      ArtistPage(
                        artistId: artistId,
                        artistName: artistName,
                        serverUrl: serverUrl,
                        token: token,
                        audioPlayerService: widget.playerService,
                        onNavigate: widget.onNavigate,
                      ),
                    );
                  } else {
                    debugPrint('PLAYER_BAR: Cannot navigate - missing data. artistId: $artistId, serverUrl: $serverUrl, token: ${token != null}, onNavigate: ${widget.onNavigate != null}');
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isArtistHovered = true),
                  onExit: (_) => setState(() => _isArtistHovered = false),
                  child: Text(
                    widget.track['artist'] as String? ?? 'Unknown Artist',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: _isArtistHovered ? FontWeight.bold : FontWeight.normal,
                      decoration: _isArtistHovered ? TextDecoration.underline : TextDecoration.none,
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
