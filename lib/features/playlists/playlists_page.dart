import 'package:flutter/material.dart';
import '../../core/models/playlists.dart';
import '../../core/services/storage_service.dart';
import 'playlist_service.dart';

class PlaylistsPage extends StatefulWidget {
  final Function(Widget) onNavigate;

  const PlaylistsPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final PlaylistService _playlistService = PlaylistService();
  final StorageService _storageService = StorageService();
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _token;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storageService.getPlexToken();
      final serverUrl = await _storageService.getServerUrl();

      if (token == null || serverUrl == null || token.isEmpty || serverUrl.isEmpty) {
        // First, try to load from local DB
        final localPlaylists = await _playlistService.getLocalPlaylists();
        if (mounted) {
          setState(() {
            _playlists = localPlaylists;
            _isLoading = false;
            // if local is empty, we still might want to show an error or empty state
          });
        }
        return;
      }

      _token = token;
      _serverUrl = serverUrl;

      final playlists = await _playlistService.syncPlaylists(
        _serverUrl!,
        _token!,
      );
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      // Try local if sync fails
      try {
        final localPlaylists = await _playlistService.getLocalPlaylists();
        if (mounted) {
          setState(() {
            _playlists = localPlaylists;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlists.isEmpty) {
      return const Center(
        child: Text(
          'No playlists found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          return _PlaylistCard(
            playlist: _playlists[index],
            serverUrl: _serverUrl ?? '',
            token: _token ?? '',
            onTap: () {
              // TODO: Navigate to playlist details
            },
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final String serverUrl;
  final String token;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.serverUrl,
    required this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = playlist.composite != null
        ? '$serverUrl${playlist.composite}?X-Plex-Token=$token'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.music_note, size: 64, color: Colors.white24)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${playlist.leafCount} tracks',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}