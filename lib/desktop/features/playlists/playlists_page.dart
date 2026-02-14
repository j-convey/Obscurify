import 'package:flutter/material.dart';
import 'package:obscurify/core/models/playlist.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/plex_connection_resolver.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/desktop/features/collection/collection_page.dart';
import 'package:obscurify/desktop/features/collection/widgets/collection_header.dart';
import 'package:obscurify/core/services/playlist_service.dart';
import 'package:obscurify/desktop/features/playlists/widgets/rename_playlist_dialog.dart';

class PlaylistsPage extends StatefulWidget {
  final Function(Widget) onNavigate;
  final AudioPlayerService? audioPlayerService;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const PlaylistsPage({
    super.key,
    required this.onNavigate,
    this.audioPlayerService,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final PlaylistService _playlistService = PlaylistService();
  final StorageService _storageService = StorageService();
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  final ScrollController _scrollController = ScrollController();
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _token;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _resolver.initialise();
      final token = _resolver.userToken;
      
      debugPrint('PLAYLISTS PAGE: Token: ${token != null ? "exists" : "null"}');

      if (token == null || token.isEmpty) {
        await _loadLocalPlaylists('No token');
        return;
      }

      // Get the connection for the selected server
      final connection = await _resolver.getSelectedServerConnection();
      
      debugPrint('PLAYLISTS PAGE: Server URL from resolver: ${connection?.url}');

      if (connection == null) {
        await _loadLocalPlaylists('No server URL saved - please select a library in Settings');
        return;
      }

      _token = connection.token;
      _serverUrl = connection.url;

      // Get the serverId from the selected servers map
      final selectedServers = await _storageService.getSelectedServers();
      String? serverId;
      for (var entry in selectedServers.entries) {
        if (entry.value.isNotEmpty) {
          serverId = entry.key;
          break;
        }
      }

      if (serverId == null) {
        await _loadLocalPlaylists('No server ID found');
        return;
      }

      debugPrint('PLAYLISTS PAGE: Syncing playlists from server $serverId');
      final playlists = await _playlistService.syncPlaylists(
        _serverUrl!,
        _token!,
        serverId,
      );
      debugPrint('PLAYLISTS PAGE: Synced ${playlists.length} playlists');
      
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('PLAYLISTS PAGE: Error loading playlists: $e');
      debugPrint('PLAYLISTS PAGE: Stack trace: $stackTrace');
      await _loadLocalPlaylists('Error: $e');
    }
  }

  Future<void> _loadLocalPlaylists(String reason) async {
    debugPrint('PLAYLISTS PAGE: $reason, loading local playlists');
    try {
      final localPlaylists = await _playlistService.getLocalPlaylists();
      debugPrint('PLAYLISTS PAGE: Loaded ${localPlaylists.length} local playlists');
      if (mounted) {
        setState(() {
          _playlists = localPlaylists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PLAYLISTS PAGE: Failed to load local playlists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _PlaylistCard(
          playlist: playlist,
          serverUrl: _serverUrl ?? '',
          token: _token ?? '',
          onTap: () => _navigateToPlaylist(playlist),
        );
      },
    );
  }

  void _navigateToPlaylist(Playlist playlist) {
    final imageUrl = _resolver.buildImageUrl(
      playlist.composite,
      playlist.serverId.isNotEmpty ? playlist.serverId : null,
    ) ?? (playlist.composite != null
        ? '$_serverUrl${playlist.composite}?X-Plex-Token=$_token'
        : null);

    final serverId = playlist.serverId.isNotEmpty ? playlist.serverId : null;
    final effectiveToken = _resolver.getTokenForServer(serverId) ?? _token!;

    widget.onNavigate(
      _PlaylistDetailPage(
        playlist: playlist,
        serverUrl: _serverUrl!,
        token: effectiveToken,
        imageUrl: imageUrl,
        audioPlayerService: widget.audioPlayerService,
        playlistService: _playlistService,
        onNavigate: widget.onNavigate,
        onHomeTap: widget.onHomeTap,
        onSettingsTap: widget.onSettingsTap,
        onProfileTap: widget.onProfileTap,
      ),
    );
  }
}

/// Wrapper page that loads playlist tracks and displays CollectionPage
class _PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;
  final String serverUrl;
  final String token;
  final String? imageUrl;
  final AudioPlayerService? audioPlayerService;
  final PlaylistService playlistService;
  final Function(Widget)? onNavigate;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const _PlaylistDetailPage({
    required this.playlist,
    required this.serverUrl,
    required this.token,
    this.imageUrl,
    this.audioPlayerService,
    required this.playlistService,
    this.onNavigate,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<_PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<_PlaylistDetailPage> {
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  List<Map<String, dynamic>>? _tracks;
  bool _isLoading = true;
  String? _error;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.playlist.title;
    _loadPlaylistTracks();
  }

  Future<void> _loadPlaylistTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracks = await widget.playlistService.getPlaylistTracks(
        widget.serverUrl,
        widget.token,
        widget.playlist.id,
        serverId: widget.playlist.serverId.isNotEmpty ? widget.playlist.serverId : null,
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

  Future<void> _showRenameDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RenamePlaylistDialog(
        currentName: _currentTitle ?? widget.playlist.title,
        onRename: (newName) async {
          await widget.playlistService.renamePlaylist(
            widget.serverUrl,
            widget.token,
            widget.playlist.id,
            newName,
            serverId: widget.playlist.serverId.isNotEmpty ? widget.playlist.serverId : null,
          );
          if (mounted) {
            setState(() {
              _currentTitle = newName;
            });
          }
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist renamed successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
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
        ),
      );
    }

    final serverId = widget.playlist.serverId.isNotEmpty ? widget.playlist.serverId : null;
    final effectiveToken = _resolver.getTokenForServer(serverId) ?? widget.token;

    return CollectionPage(
      title: _currentTitle ?? widget.playlist.title,
      subtitle: '${widget.playlist.leafCount} songs',
      collectionType: CollectionType.playlist,
      audioPlayerService: widget.audioPlayerService,
      tracks: _tracks,
      imageUrl: widget.imageUrl,
      currentToken: effectiveToken,
      serverUrls: _resolver.serverUrls,
      currentServerUrl: widget.serverUrl,
      emptyMessage: 'This playlist is empty.',
      onNavigate: widget.onNavigate,
      onHomeTap: widget.onHomeTap,
      onSettingsTap: widget.onSettingsTap,
      onProfileTap: widget.onProfileTap,
      onTitleTap: _showRenameDialog,
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
    final resolver = PlexConnectionResolver();
    final serverId = playlist.serverId.isNotEmpty ? playlist.serverId : null;
    final imageUrl = resolver.buildImageUrl(playlist.composite, serverId)
        ?? (playlist.composite != null
            ? '$serverUrl${playlist.composite}?X-Plex-Token=$token'
            : null);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
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
          ),
          const SizedBox(height: 8),
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
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