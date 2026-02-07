import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/models/playlist.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/audio_player_service.dart';
import 'widgets/playlist_grid_item.dart';
import 'mobile_playlist_page.dart';

class MobilePlaylistsPage extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;

  const MobilePlaylistsPage({
    super.key,
    this.audioPlayerService,
  });

  @override
  State<MobilePlaylistsPage> createState() => _MobilePlaylistsPageState();
}

class _MobilePlaylistsPageState extends State<MobilePlaylistsPage> {
  final DatabaseService _db = DatabaseService();
  final StorageService _storageService = StorageService();

  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _token;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = await _storageService.getPlexToken();
    final serverUrl = await _storageService.getSelectedServerUrl() ??
        await _storageService.getServerUrl();
    final playlists = await _db.playlists.getAll();

    if (mounted) {
      setState(() {
        _token = token;
        _serverUrl = serverUrl;
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  void _navigateToPlaylist(Playlist playlist) {
    if (_token == null || _serverUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobilePlaylistPage(
          playlist: playlist,
          audioPlayerService: widget.audioPlayerService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              centerTitle: true,
              title: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
                  final delta = settings.maxExtent - settings.minExtent;
                  final t = (1.0 - (settings.currentExtent - settings.minExtent) / delta).clamp(0.0, 1.0);
                  
                  return Opacity(
                    opacity: t,
                    child: const Text('Playlists', style: TextStyle(color: Colors.white, fontSize: 16)),
                  );
                },
              ),
              background: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(
                    'Playlists',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                '${_playlists.length} playlists',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.green)),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final playlist = _playlists[index];
                        return PlaylistGridItem(
                          playlist: playlist,
                          serverUrl: _serverUrl,
                          token: _token,
                          onTap: () => _navigateToPlaylist(playlist),
                        );
                      },
                      childCount: _playlists.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
