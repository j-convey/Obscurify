import 'package:flutter/material.dart';
import 'package:obscurify/core/models/artist.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'mobile_artist_page.dart';
import 'widgets/artist_grid_item.dart';

class MobileArtistsListPage extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;

  const MobileArtistsListPage({
    super.key,
    this.audioPlayerService,
  });

  @override
  State<MobileArtistsListPage> createState() => _MobileArtistsListPageState();
}

class _MobileArtistsListPageState extends State<MobileArtistsListPage> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<Artist> _artists = [];
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
    final artists = await _dbService.artists.getAll();

    if (mounted) {
      setState(() {
        _token = token;
        _serverUrl = serverUrl;
        _artists = artists;
        _isLoading = false;
      });
    }
  }

  void _navigateToArtist(Artist artist) {
    if (_token == null || _serverUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileArtistPage(
          artistId: artist.ratingKey,
          artistName: artist.name,
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
              titlePadding: EdgeInsets.zero, // We handle padding ourselves
              centerTitle: true,
              title: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Get the settings to calculate the collapse percentage
                  final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
                  final delta = settings.maxExtent - settings.minExtent;
                  final t = (1.0 - (settings.currentExtent - settings.minExtent) / delta).clamp(0.0, 1.0);
                  
                  return Opacity(
                    opacity: t,
                    child: const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 16)),
                  );
                },
              ),
              background: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(
                    'Artists',
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
                '${_artists.length} artists',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artist = _artists[index];
                        return ArtistGridItem(
                          artist: artist,
                          serverUrl: _serverUrl,
                          token: _token,
                          onTap: () => _navigateToArtist(artist),
                        );
                      },
                      childCount: _artists.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
