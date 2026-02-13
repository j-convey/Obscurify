import 'package:flutter/material.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/plex_connection_resolver.dart';
import '../../../core/services/home_data_service.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/track.dart';
import '../../../core/services/library_change_notifier.dart';
import '../../../shared/widgets/content_carousel.dart';
import 'widgets/home_nav_bar.dart';

/// Mobile home page with quick access buttons matching the desktop layout.
class MobileHomePage extends StatefulWidget {
  final VoidCallback? onNavigateToLibrary;
  final VoidCallback? onNavigateToArtists;
  final VoidCallback? onNavigateToPlaylists;
  final VoidCallback? onOpenDrawer;
  final AudioPlayerService? audioPlayerService;
  
  const MobileHomePage({
    super.key,
    this.onNavigateToLibrary,
    this.onNavigateToArtists,
    this.onNavigateToPlaylists,
    this.onOpenDrawer,
    this.audioPlayerService,
  });

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final DatabaseService _db = DatabaseService();
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  final LibraryChangeNotifier _libraryNotifier = LibraryChangeNotifier();
  final HomeDataService _homeDataService = HomeDataService();
  
  List<Track> _recentTracks = [];
  List<CarouselItem> _newReleases = [];
  bool _isLoading = true;
  String? _currentToken;
  Map<String, String> _serverUrls = {};
  String? _currentServerUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
    _libraryNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    _libraryNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load tracks
    final tracks = await _db.tracks.getRecent(limit: 20);
    
    // Load server info via resolver
    await _resolver.initialise();
    final urls = await _resolver.fetchAndCacheServerUrls();
    final serverId = urls.keys.isNotEmpty ? urls.keys.first : null;
    final serverUrl = serverId != null ? _resolver.getUrlForServer(serverId) : null;
    
    // Load new releases
    List<CarouselItem> newReleases = [];
    if (_resolver.userToken != null && serverUrl != null && serverUrl.isNotEmpty) {
      newReleases = await _homeDataService.getNewReleases(
        serverUrl: serverUrl,
        token: _resolver.userToken!,
      );
    }
    
    if (mounted) {
      setState(() {
        _recentTracks = tracks;
        _newReleases = newReleases;
        _currentToken = _resolver.userToken;
        _serverUrls = urls;
        _currentServerUrl = serverUrl;
        _isLoading = false;
      });
      
      // Update player service with server URLs and access tokens
      widget.audioPlayerService?.setServerUrls(urls);
      widget.audioPlayerService?.setServerAccessTokens(
        {for (final id in urls.keys) id: _resolver.getTokenForServer(id) ?? ''},
      );
    }
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
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

    // Set queue with recent tracks
    final trackMaps = _recentTracks.map((t) => t.toJson()).toList();
    final index = _recentTracks.indexOf(track);
    
    widget.audioPlayerService!.setPlayQueue(trackMaps, index);
    await widget.audioPlayerService!.playTrack(
      track.toJson(),
      token,
      serverUrl,
    );
  }

  void _onCarouselItemTap(CarouselItem item) {
    if (_currentToken == null || _currentServerUrl == null) return;

    switch (item.type) {
      case CarouselItemType.artist:
        // Navigate to artist page (if implemented in mobile)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artist: ${item.title}')),
        );
        break;

      case CarouselItemType.album:
        // Navigate to album page (if implemented in mobile)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Album: ${item.title}')),
        );
        break;

      case CarouselItemType.track:
        // Play the track directly
        if (widget.audioPlayerService != null && item.data != null) {
          widget.audioPlayerService!.setServerUrls(
            {item.data!['serverId'] as String? ?? '': _currentServerUrl!},
          );
          widget.audioPlayerService!.playTrack(
            item.data!,
            _currentToken!,
            _currentServerUrl!,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top navigation bar with profile and filters
            HomeNavBar(onOpenDrawer: widget.onOpenDrawer),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: Colors.purple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Good ${_getTimeOfDay()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quick access grid - 2 columns
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 3,
                        children: [
                          _QuickAccessTile(
                            icon: Icons.library_music,
                            label: 'Library',
                            color: Colors.purple,
                            onTap: () {
                              widget.onNavigateToLibrary?.call();
                            },
                          ),
                          _QuickAccessTile(
                            icon: Icons.playlist_play,
                            label: 'Playlists',
                            color: Colors.blue,
                            onTap: () {
                              widget.onNavigateToPlaylists?.call();
                            },
                          ),
                          _QuickAccessTile(
                            icon: Icons.person,
                            label: 'Artists',
                            color: Colors.orange,
                            onTap: () {
                              widget.onNavigateToArtists?.call();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // New releases carousel
                      if (_newReleases.isNotEmpty) ...[
                        ContentCarousel(
                          title: 'New Releases',
                          items: _newReleases,
                          onItemTap: _onCarouselItemTap,
                          cardHeight: 220,
                          cardWidth: 140,
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      const Text(
                        'Recently played',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator(color: Colors.purple))
                      else if (_recentTracks.isEmpty)
                        const SizedBox(
                          height: 100,
                          child: Center(
                            child: Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentTracks.length,
                          itemBuilder: (context, index) {
                            final track = _recentTracks[index];
                            final imageUrl = _resolver.buildImageUrl(track.thumb, track.serverId);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          imageUrl,
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
                              onTap: () => _playTrack(track),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
