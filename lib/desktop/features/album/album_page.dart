import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'album_display.dart';

/// Album page that displays an album of tracks.
/// Provides the page scaffold and navigation.
class AlbumPage extends StatelessWidget {
  /// The title of the album
  final String title;

  /// Optional subtitle override
  final String? subtitle;

  /// The audio player service for playback
  final AudioPlayerService? audioPlayerService;

  /// The tracks to display
  final List<Map<String, dynamic>>? tracks;

  /// Optional cover image URL
  final String? imageUrl;

  /// Optional gradient colors for the header
  final List<Color>? gradientColors;

  /// Callback to load tracks if not provided directly
  final Future<List<Map<String, dynamic>>> Function()? onLoadTracks;

  /// Current Plex token
  final String? currentToken;

  /// Map of server IDs to URLs
  final Map<String, String>? serverUrls;

  /// Current server URL
  final String? currentServerUrl;

  /// Navigation callback for album pages
  final void Function(Widget)? onNavigate;

  /// Callback for home button
  final VoidCallback? onHomeTap;

  /// Callback for settings
  final VoidCallback? onSettingsTap;

  /// Callback for profile
  final VoidCallback? onProfileTap;

  const AlbumPage({
    super.key,
    required this.title,
    this.subtitle,
    this.audioPlayerService,
    this.tracks,
    this.imageUrl,
    this.gradientColors,
    this.onLoadTracks,
    this.currentToken,
    this.serverUrls,
    this.currentServerUrl,
    this.onNavigate,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _loadTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force rebuild by navigating back and forth
                      Navigator.of(context).pop();
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final tracksToDisplay = snapshot.data ?? tracks ?? [];

          if (tracksToDisplay.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.music_note, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No songs in this album',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Resolve album image: prefer provided imageUrl, fall back to
          // the first track's thumb — the same approach the player bar uses.
          String? resolvedImageUrl = imageUrl;
          if ((resolvedImageUrl == null || resolvedImageUrl.isEmpty) &&
              tracksToDisplay.isNotEmpty &&
              currentToken != null) {
            final firstTrack = tracksToDisplay.first;
            final thumb = firstTrack['thumb'] as String?;
            if (thumb != null && thumb.isNotEmpty) {
              final serverId = firstTrack['serverId'] as String?;
              final sUrl = serverId != null
                  ? (serverUrls?[serverId] ?? currentServerUrl)
                  : currentServerUrl;
              if (sUrl != null) {
                resolvedImageUrl = '$sUrl$thumb?X-Plex-Token=$currentToken';
              }
            }
          }

          return AlbumDisplay(
            title: title,
            subtitle: subtitle,
            audioPlayerService: audioPlayerService,
            tracks: tracksToDisplay,
            imageUrl: resolvedImageUrl,
            gradientColors: gradientColors,
            currentToken: currentToken,
            serverUrls: serverUrls,
            currentServerUrl: currentServerUrl,
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> _loadTracks() async {
    if (tracks != null) {
      return tracks;
    }
    if (onLoadTracks != null) {
      return await onLoadTracks!();
    }
    return null;
  }
}
