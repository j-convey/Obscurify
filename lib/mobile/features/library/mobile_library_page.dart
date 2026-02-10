import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/track.dart';
import '../../../core/services/plex/plex_services.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/library_change_notifier.dart';
import 'widgets/track_options_sheet.dart';
import 'widgets/sort_bottom_sheet.dart';
import '../../shared/widgets/track_tile.dart';
import '../../shared/widgets/plex_image.dart';

/// Library page for mobile showing all songs from the server.
class MobileLibraryPage extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;

  const MobileLibraryPage({
    super.key,
    this.audioPlayerService,
  });

  @override
  State<MobileLibraryPage> createState() => _MobileLibraryPageState();
}

class _MobileLibraryPageState extends State<MobileLibraryPage> {
  final DatabaseService _db = DatabaseService();
  final PlexServerService _serverService = PlexServerService();
  final StorageService _storageService = StorageService();
  final LibraryChangeNotifier _libraryNotifier = LibraryChangeNotifier();
  late Future<List<Track>> _tracksFuture;

  String? _currentToken;
  Map<String, String> _serverUrls = {};
  bool _isShuffleOn = false;
  SortOption _currentSort = SortOption.recentlyAdded;
  List<Track>? _cachedSortedTracks;

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _loadServerUrls();
    _libraryNotifier.addListener(_refreshTracks);
  }

  @override
  void dispose() {
    _libraryNotifier.removeListener(_refreshTracks);
    super.dispose();
  }

  void _loadTracks() {
    _tracksFuture = _db.tracks.getAll();
  }

  Future<void> _loadServerUrls() async {
    final token = await _storageService.getPlexToken();
    if (token != null) {
      final urls = await _serverService.fetchServerUrlMap(token);
      if (mounted) {
        setState(() {
          _currentToken = token;
          _serverUrls = urls;
        });

        // Provide server URLs to audio player service
        widget.audioPlayerService?.setServerUrls(urls);
      }
    }
  }

  Future<void> _refreshTracks() async {
    _cachedSortedTracks = null; // Clear cache when tracks refresh
    setState(() {
      _loadTracks();
    });
    await _loadServerUrls();
  }

  void _showTrackOptions(BuildContext context, Track track, String? serverUrl) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TrackOptionsSheet(
        track: track,
        serverUrl: serverUrl,
        token: _currentToken,
      ),
    );
  }

  Future<void> _playTrack(Track track, List<Track> allTracks) async {
    if (widget.audioPlayerService == null || _currentToken == null) return;

    final serverUrl = _serverUrls[track.serverId];
    if (serverUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot play track: Server not found')),
      );
      return;
    }

    final trackMaps = allTracks.map((t) => t.toJson()).toList();
    final index = allTracks.indexOf(track);

    widget.audioPlayerService!.setPlayQueue(trackMaps, index);
    await widget.audioPlayerService!.playTrack(
      track.toJson(),
      _currentToken!,
      serverUrl,
    );
  }

  Future<void> _playAll(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final list = _isShuffleOn ? (List<Track>.from(tracks)..shuffle()) : tracks;
    await _playTrack(list.first, list);
  }

  /// Collect unique genres from the track list.
  List<String> _extractGenres(List<Track> tracks) {
    final seen = <String>{};
    final genres = <String>[];
    for (final t in tracks) {
      final g = t.genre;
      if (g != null && g.isNotEmpty && seen.add(g)) {
        genres.add(g);
      }
    }
    return genres;
  }

  /// Show sort bottom sheet
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SortBottomSheet(
        currentSort: _currentSort,
        onSortChanged: (option) {
          if (_currentSort != option) {
            _currentSort = option;
            _cachedSortedTracks = null; // Clear cache to trigger re-sort
            setState(() {});
          }
        },
      ),
    );
  }

  /// Sort tracks based on current sort option (with caching)
  List<Track> _getSortedTracks(List<Track> tracks) {
    // Return cached result if available
    if (_cachedSortedTracks != null) {
      return _cachedSortedTracks!;
    }

    // Sort and cache
    final sorted = List<Track>.from(tracks);
    
    switch (_currentSort) {
      case SortOption.title:
        sorted.sort((a, b) => a.sortableTitle.compareTo(b.sortableTitle));
        break;
      case SortOption.artist:
        sorted.sort((a, b) {
          final artistCompare = a.artistName.toLowerCase().compareTo(b.artistName.toLowerCase());
          if (artistCompare != 0) return artistCompare;
          return a.sortableTitle.compareTo(b.sortableTitle);
        });
        break;
      case SortOption.album:
        sorted.sort((a, b) {
          final albumCompare = a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase());
          if (albumCompare != 0) return albumCompare;
          final trackNumA = a.trackNumber ?? 999999;
          final trackNumB = b.trackNumber ?? 999999;
          return trackNumA.compareTo(trackNumB);
        });
        break;
      case SortOption.recentlyAdded:
        sorted.sort((a, b) {
          final addedA = a.addedAt ?? 0;
          final addedB = b.addedAt ?? 0;
          return addedB.compareTo(addedA); // Most recent first
        });
        break;
    }
    
    _cachedSortedTracks = sorted;
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<Track>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Your library is empty',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final tracks = _getSortedTracks(snapshot.data!);
          final genres = _extractGenres(tracks);
          // Grab the first track's thumb as header artwork
          final firstTrack = tracks.first;
          final headerServerUrl = _serverUrls[firstTrack.serverId];

          return RefreshIndicator(
            onRefresh: _refreshTracks,
            color: const Color(0xFF1DB954),
            child: CustomScrollView(
              slivers: [
                // ── Gradient header ──────────────────────────────
                SliverToBoxAdapter(
                  child: _buildHeader(
                    context,
                    tracks: tracks,
                    genres: genres,
                    headerThumb: firstTrack.thumb ?? firstTrack.albumThumb,
                    headerServerUrl: headerServerUrl,
                  ),
                ),

                // ── Track list ───────────────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final serverUrl = _serverUrls[track.serverId];
                      return TrackTile(
                        track: track,
                        serverUrl: serverUrl,
                        token: _currentToken,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.grey, size: 20),
                          onPressed: () =>
                              _showTrackOptions(context, track, serverUrl),
                        ),
                        onLongPress: () =>
                            _showTrackOptions(context, track, serverUrl),
                        onTap: () => _playTrack(track, tracks),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),

                // Bottom padding so list isn't hidden behind mini-player
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  Header (gradient + search + title + actions + chips)
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context, {
    required List<Track> tracks,
    required List<String> genres,
    required String? headerThumb,
    required String? headerServerUrl,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3B2874), // deep purple-blue
            Color(0xFF2A1B5E), // mid purple
            Color(0xFF1A1040), // dark transition
            Color(0xFF121212), // background
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Back button ────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 16),

              // ── Search bar + Sort button ───────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Find in Library',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Text(
                      'Sort',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────
              const Text(
                'Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // ── Song count ─────────────────────────────────
              Text(
                '${tracks.length} songs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // ── Action row: artwork, download, shuffle, play
              Row(
                children: [
                  // Small album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: PlexImage(
                      serverUrl: headerServerUrl,
                      token: _currentToken,
                      thumbPath: headerThumb,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Download icon
                  Icon(Icons.arrow_circle_down,
                      color: Colors.white.withValues(alpha: 0.7), size: 26),
                  const Spacer(),
                  // Shuffle
                  GestureDetector(
                    onTap: () => setState(() => _isShuffleOn = !_isShuffleOn),
                    child: Icon(
                      Icons.shuffle,
                      color: _isShuffleOn
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.7),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Green play button
                  GestureDetector(
                    onTap: () => _playAll(tracks),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.black, size: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Genre chips (horizontal scroll) ────────────
              if (genres.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: genres.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          genres[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (genres.isNotEmpty) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
