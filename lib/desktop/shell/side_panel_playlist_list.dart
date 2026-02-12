import 'package:flutter/material.dart';
import 'package:obscurify/core/models/playlist.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/playlist_service.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/library_change_notifier.dart';
import 'package:obscurify/desktop/features/playlists/playlist_detail_page.dart';

/// Scrollable list of playlist thumbnails displayed inside the side panel.
///
/// When collapsed, shows a single-column grid of square artwork.
/// When expanded, shows a two-column grid with playlist titles.
/// Tapping a playlist navigates to [PlaylistDetailPage].
class SidePanelPlaylistList extends StatefulWidget {
  /// Whether the side panel is in collapsed (icon-only) mode.
  final bool isCollapsed;

  /// Navigation callback to push a new page.
  final void Function(Widget)? onNavigate;

  final AudioPlayerService? audioPlayerService;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const SidePanelPlaylistList({
    super.key,
    required this.isCollapsed,
    this.onNavigate,
    this.audioPlayerService,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<SidePanelPlaylistList> createState() => _SidePanelPlaylistListState();
}

class _SidePanelPlaylistListState extends State<SidePanelPlaylistList> {
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
    LibraryChangeNotifier().addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    LibraryChangeNotifier().removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) {
      _loadPlaylists();
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final token = await _storageService.getPlexToken();
      if (token == null || token.isEmpty) {
        await _loadLocal();
        return;
      }
      _token = token;

      final serverUrl = await _storageService.getSelectedServerUrl();
      if (serverUrl == null) {
        await _loadLocal();
        return;
      }
      _serverUrl = serverUrl;

      final selectedServers = await _storageService.getSelectedServers();
      String? serverId;
      for (var entry in selectedServers.entries) {
        if (entry.value.isNotEmpty) {
          serverId = entry.key;
          break;
        }
      }

      if (serverId == null) {
        await _loadLocal();
        return;
      }

      final playlists = await _playlistService.syncPlaylists(
        _serverUrl!,
        _token!,
        serverId,
      );

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (_) {
      await _loadLocal();
    }
  }

  Future<void> _loadLocal() async {
    try {
      final local = await _playlistService.getLocalPlaylists();
      if (mounted) {
        setState(() {
          _playlists = local;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPlaylistTap(Playlist playlist) {
    if (widget.onNavigate == null ||
        _serverUrl == null ||
        _token == null) return;

    final imageUrl = playlist.composite != null
        ? '$_serverUrl${playlist.composite}?X-Plex-Token=$_token'
        : null;

    widget.onNavigate!(
      PlaylistDetailPage(
        key: ValueKey('playlist_${playlist.id}'),
        playlist: playlist,
        serverUrl: _serverUrl!,
        token: _token!,
        imageUrl: imageUrl,
        audioPlayerService: widget.audioPlayerService,
        onNavigate: widget.onNavigate,
        onHomeTap: widget.onHomeTap,
        onSettingsTap: widget.onSettingsTap,
        onProfileTap: widget.onProfileTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_playlists.isEmpty) return const SizedBox.shrink();

    if (widget.isCollapsed) {
      return _buildCollapsedList();
    }
    return _buildExpandedGrid();
  }

  // ── Collapsed: single column of square thumbnails ─────────────────────

  Widget _buildCollapsedList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        final imageUrl = _buildImageUrl(playlist);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Tooltip(
            message: playlist.title,
            waitDuration: const Duration(milliseconds: 400),
            child: GestureDetector(
              onTap: () => _onPlaylistTap(playlist),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildThumbnail(imageUrl),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Expanded: two-column grid with titles ─────────────────────────────

  Widget _buildExpandedGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        final imageUrl = _buildImageUrl(playlist);

        return GestureDetector(
          onTap: () => _onPlaylistTap(playlist),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildThumbnail(imageUrl),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playlist.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String? _buildImageUrl(Playlist playlist) {
    if (playlist.composite == null ||
        _serverUrl == null ||
        _token == null) return null;
    return '$_serverUrl${playlist.composite}?X-Plex-Token=$_token';
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholderIcon(),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.grey[850] ?? const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.white24, size: 28),
      ),
    );
  }
}
