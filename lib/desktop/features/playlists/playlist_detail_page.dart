import 'package:flutter/material.dart';
import 'package:obscurify/core/models/playlist.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/playlist_service.dart';
import 'package:obscurify/desktop/features/collection/collection_page.dart';
import 'package:obscurify/desktop/features/collection/widgets/collection_header.dart';

/// Full-screen detail page for a single playlist.
///
/// Loads the playlist's tracks from Plex and displays them via [CollectionPage].
class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final String serverUrl;
  final String token;
  final String? imageUrl;
  final AudioPlayerService? audioPlayerService;
  final Function(Widget)? onNavigate;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.serverUrl,
    required this.token,
    this.imageUrl,
    this.audioPlayerService,
    this.onNavigate,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final PlaylistService _playlistService = PlaylistService();
  List<Map<String, dynamic>>? _tracks;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylistTracks();
  }

  Future<void> _loadPlaylistTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracks = await _playlistService.getPlaylistTracks(
        widget.serverUrl,
        widget.token,
        widget.playlist.id,
      );

      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading playlist: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlaylistTracks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return CollectionPage(
      title: widget.playlist.title,
      subtitle: '${widget.playlist.leafCount} songs',
      collectionType: CollectionType.playlist,
      audioPlayerService: widget.audioPlayerService,
      tracks: _tracks,
      imageUrl: widget.imageUrl,
      currentToken: widget.token,
      serverUrls: {},
      currentServerUrl: widget.serverUrl,
      emptyMessage: 'This playlist is empty.',
      onNavigate: widget.onNavigate,
      onHomeTap: widget.onHomeTap,
      onSettingsTap: widget.onSettingsTap,
      onProfileTap: widget.onProfileTap,
    );
  }
}
