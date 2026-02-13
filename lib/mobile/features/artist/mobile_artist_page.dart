import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/models/track.dart';
import '../../../../core/models/artist.dart';
import '../../../../core/services/plex_connection_resolver.dart';
import '../../../../core/services/audio_player_service.dart';
import 'widgets/artist_header.dart';
import 'widgets/artist_popular_tracks.dart';

class MobileArtistPage extends StatefulWidget {
  final String artistId;
  final String artistName;
  final AudioPlayerService? audioPlayerService;

  const MobileArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
    this.audioPlayerService,
  });

  @override
  State<MobileArtistPage> createState() => _MobileArtistPageState();
}

class _MobileArtistPageState extends State<MobileArtistPage> {
  final DatabaseService _db = DatabaseService();
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  
  List<Track> _topTracks = [];
  Artist? _artist;
  bool _isLoading = true;
  String? _currentToken;
  Map<String, String> _serverUrls = {};
  
  // For scrolling app bar effect
  final ScrollController _scrollController = ScrollController();
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset < 100) {
        if (_opacity != 0.0) setState(() => _opacity = 0.0);
      } else if (offset > 200) {
        if (_opacity != 1.0) setState(() => _opacity = 1.0);
      } else {
        setState(() => _opacity = (offset - 100) / 100);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tracks = await _db.tracks.getByArtist(widget.artistId);
      final topTracks = tracks.take(5).toList();
      await _resolver.initialise();
      final urls = await _resolver.fetchAndCacheServerUrls();
      
      Artist? artistDetails;
      if (tracks.isNotEmpty) {
        artistDetails = Artist(
          ratingKey: widget.artistId,
          name: widget.artistName,
          thumb: tracks.first.artistThumb,
          art: tracks.first.artistThumb,
          serverId: tracks.first.serverId,
        );
      }

      if (mounted) {
        setState(() {
          _topTracks = topTracks;
          _artist = artistDetails;
          _currentToken = _resolver.userToken;
          _serverUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading artist data: $e');
    }
  }

  Future<void> _playTrack(Track track) async {
    if (widget.audioPlayerService == null || _currentToken == null) return;
    
    final serverUrl = _serverUrls[track.serverId];
    if (serverUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot play track: Server not found')),
      );
      return;
    }

    final token = _resolver.getTokenForServer(track.serverId) ?? _currentToken!;

    final trackMaps = _topTracks.map((t) => t.toJson()).toList();
    final index = _topTracks.indexOf(track);
    
    widget.audioPlayerService!.setPlayQueue(trackMaps, index);
    await widget.audioPlayerService!.playTrack(
      track.toJson(),
      token,
      serverUrl,
    );
  }

  Future<void> _playAll() async {
    if (_topTracks.isNotEmpty) {
      await _playTrack(_topTracks.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine server URL for artist image
    String? artistServerUrl;
    if (_artist?.serverId.isNotEmpty == true) {
      artistServerUrl = _serverUrls[_artist!.serverId];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ArtistHeader(
                      artistName: widget.artistName,
                      serverUrl: artistServerUrl,
                      token: _currentToken,
                      thumbPath: _artist?.thumb,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              // TODO: Shuffle play
                            },
                            icon: const Icon(Icons.shuffle, color: Colors.grey, size: 28),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            onPressed: _playAll,
                            backgroundColor: const Color(0xFF1DB954),
                            shape: const CircleBorder(),
                            child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.green)),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Popular',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _topTracks[index];
                      final serverUrl = _serverUrls[track.serverId];

                      return ArtistPopularTrackItem(
                        index: index + 1,
                        track: track,
                        serverUrl: serverUrl,
                        token: _currentToken,
                        onTap: () => _playTrack(track),
                      );
                    },
                    childCount: _topTracks.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
          
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              color: const Color(0xFF121212).withValues(alpha: _opacity),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5 * (1 - _opacity)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: _opacity,
                      child: Text(
                        widget.artistName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
