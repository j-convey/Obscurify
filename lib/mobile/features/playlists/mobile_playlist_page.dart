import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/models/playlist.dart';
import '../../../../core/models/track.dart';
import '../../../../core/services/plex/plex_services.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/audio_player_service.dart';
import '../library/widgets/track_options_sheet.dart';

class MobilePlaylistPage extends StatefulWidget {
  final Playlist playlist;
  final AudioPlayerService? audioPlayerService;

  const MobilePlaylistPage({
    super.key,
    required this.playlist,
    this.audioPlayerService,
  });

  @override
  State<MobilePlaylistPage> createState() => _MobilePlaylistPageState();
}

class _MobilePlaylistPageState extends State<MobilePlaylistPage> {
  final DatabaseService _db = DatabaseService();
  final PlexServerService _serverService = PlexServerService();
  final StorageService _storageService = StorageService();

  List<Track> _tracks = [];
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
      // Load playlist tracks
      // Using repository directly if available, otherwise might need custom query
      // PlaylistRepository usually has a getTracks method
      final tracks = await _db.playlists.getTracks(widget.playlist.id);
      
      final token = await _storageService.getPlexToken();
      Map<String, String> urls = {};
      if (token != null) {
        urls = await _serverService.fetchServerUrlMap(token);
      }

      if (mounted) {
        setState(() {
          _tracks = tracks;
          _currentToken = token;
          _serverUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading playlist data: $e');
    }
  }

  Future<void> _playTrack(Track track) async {
    if (widget.audioPlayerService == null || _currentToken == null) return;

    final serverUrl = _serverUrls[track.serverId] ?? _serverUrls[widget.playlist.serverId];
    if (serverUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot play track: Server not found')),
      );
      return;
    }

    final trackMaps = _tracks.map((t) => t.toJson()).toList();
    final index = _tracks.indexOf(track);

    widget.audioPlayerService!.setPlayQueue(trackMaps, index);
    await widget.audioPlayerService!.playTrack(
      track.toJson(),
      _currentToken!,
      serverUrl,
    );
  }

  Future<void> _playAll() async {
    if (_tracks.isNotEmpty) {
      await _playTrack(_tracks.first);
    }
  }

  void _showTrackOptions(Track track, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TrackOptionsSheet(
        track: track,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construct playlist image URL
    String? playlistImageUrl;
    if (widget.playlist.composite != null && _currentToken != null && widget.playlist.serverId.isNotEmpty) {
      final serverUrl = _serverUrls[widget.playlist.serverId];
      if (serverUrl != null) {
        playlistImageUrl = '$serverUrl${widget.playlist.composite!}?X-Plex-Token=$_currentToken';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image (Blurred or simple gradient)
                      playlistImageUrl != null
                          ? Image.network(
                              playlistImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                            )
                          : Container(color: Colors.grey[900]),
                      
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              const Color(0xFF121212),
                            ],
                          ),
                        ),
                      ),

                      // Playlist Info
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.playlist.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.playlist.leafCount} songs',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Play Button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _playAll,
                          backgroundColor: const Color(0xFF1DB954),
                          shape: const CircleBorder(),
                          child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.green)),
                )
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _tracks[index];
                      String? trackImageUrl;
                      final serverUrl = _serverUrls[track.serverId];
                      if (track.thumb != null && serverUrl != null && _currentToken != null) {
                        trackImageUrl = '$serverUrl${track.thumb!}?X-Plex-Token=$_currentToken';
                      }

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: trackImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    trackImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.music_note, color: Colors.grey),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artistName,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () => _showTrackOptions(track, trackImageUrl),
                        ),
                        onTap: () => _playTrack(track),
                      );
                    },
                    childCount: _tracks.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
          
          // Custom App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              color: const Color(0xFF121212).withOpacity(_opacity),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5 * (1 - _opacity)),
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
                        widget.playlist.title,
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
