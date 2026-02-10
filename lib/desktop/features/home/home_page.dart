import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/home_data_service.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/shared/widgets/content_carousel.dart';
import 'package:obscurify/desktop/features/songs/songs_page.dart';
import 'package:obscurify/desktop/features/playlists/playlists_page.dart';
import 'package:obscurify/desktop/features/artist/artists_list_page.dart';
import 'package:obscurify/desktop/features/artist/artist_page.dart';
import 'package:obscurify/desktop/features/album/album_page.dart';

class HomePage extends StatefulWidget {
  final Function(Widget)? onNavigate;
  final AudioPlayerService? audioPlayerService;
  final StorageService? storageService;
  final String? token;
  final String? serverUrl;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const HomePage({
    super.key,
    this.onNavigate,
    this.audioPlayerService,
    this.storageService,
    this.token,
    this.serverUrl,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeDataService _homeDataService = HomeDataService();
  final PlexServerService _serverService = PlexServerService();
  final StorageService _storageService = StorageService();
  final DatabaseService _dbService = DatabaseService();

  List<CarouselItem> _recentlyPlayed = [];
  List<CarouselItem> _newReleases = [];
  bool _isLoading = true;
  String? _resolvedServerUrl;
  String? _resolvedToken;
  Map<String, String> _resolvedServerUrls = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when credentials become available or change
    if (widget.token != oldWidget.token ||
        widget.serverUrl != oldWidget.serverUrl) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Resolve credentials: prefer widget props, fall back to storage/server service
      String? token = widget.token;
      String? serverUrl = widget.serverUrl;

      token ??= await _storageService.getPlexToken();

      if (token != null && (serverUrl == null || serverUrl.isEmpty)) {
        _resolvedServerUrls = await _serverService.fetchServerUrlMap(token);
        if (_resolvedServerUrls.isNotEmpty) {
          serverUrl = _resolvedServerUrls.values.first;
        }
      }

      _resolvedToken = token;
      _resolvedServerUrl = serverUrl;

      if (token == null || serverUrl == null || serverUrl.isEmpty) {
        // No credentials yet – just show empty state, don't error
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _homeDataService.getRecentlyPlayed(
          serverUrl: serverUrl,
          token: token,
        ),
        _homeDataService.getNewReleases(
          serverUrl: serverUrl,
          token: token,
        ),
      ]);

      if (mounted) {
        setState(() {
          _recentlyPlayed = results[0];
          _newReleases = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HOME_PAGE: Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCarouselItemTap(CarouselItem item) {
    if (widget.onNavigate == null) return;
    final serverUrl = _resolvedServerUrl ?? widget.serverUrl ?? '';
    final token = _resolvedToken ?? widget.token ?? '';

    switch (item.type) {
      case CarouselItemType.artist:
        widget.onNavigate!(ArtistPage(
          artistId: item.id,
          artistName: item.title,
          serverUrl: serverUrl,
          token: token,
          audioPlayerService: widget.audioPlayerService,
          onNavigate: widget.onNavigate,
        ));
        break;

      case CarouselItemType.album:
        final data = item.data ?? {};
        final albumRatingKey = item.id;
        widget.onNavigate!(AlbumPage(
          title: item.title,
          subtitle: data['artistName'] as String?,
          imageUrl: item.imageUrl,
          audioPlayerService: widget.audioPlayerService,
          currentToken: token,
          serverUrls: _resolvedServerUrls,
          currentServerUrl: serverUrl,
          onNavigate: widget.onNavigate,
          onHomeTap: widget.onHomeTap,
          onSettingsTap: widget.onSettingsTap,
          onProfileTap: widget.onProfileTap,
          onLoadTracks: () {
            return _dbService.tracks.getByAlbum(albumRatingKey).then((tracks) {
              debugPrint('HOME_PAGE: Album $albumRatingKey returned ${tracks.length} tracks');
              return tracks.map((track) => track.toJson()).toList();
            });
          },
        ));
        break;

      case CarouselItemType.track:
        // Play the track directly
        if (widget.audioPlayerService != null && item.data != null) {
          widget.audioPlayerService!.setServerUrls(
            {item.data!['serverId'] as String? ?? '': serverUrl},
          );
          widget.audioPlayerService!.playTrack(
            item.data!,
            token,
            serverUrl,
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Good ${_getTimeOfDay()}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick access tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.library_music,
                        label: 'Library',
                        color: Colors.purple,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(SongsPage(
                              audioPlayerService: widget.audioPlayerService,
                              onNavigate: widget.onNavigate,
                              onHomeTap: widget.onHomeTap,
                              onSettingsTap: widget.onSettingsTap,
                              onProfileTap: widget.onProfileTap,
                            ));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.playlist_play,
                        label: 'Playlists',
                        color: Colors.blue,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(PlaylistsPage(
                              onNavigate: widget.onNavigate!,
                              audioPlayerService: widget.audioPlayerService,
                              onHomeTap: widget.onHomeTap,
                              onSettingsTap: widget.onSettingsTap,
                              onProfileTap: widget.onProfileTap,
                            ));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.person,
                        label: 'Artists',
                        color: Colors.orange,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(ArtistsListPage(
                              onNavigate: widget.onNavigate,
                              audioPlayerService: widget.audioPlayerService,
                              onHomeTap: widget.onHomeTap,
                              onSettingsTap: widget.onSettingsTap,
                              onProfileTap: widget.onProfileTap,
                            ));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recently played carousel
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentlyPlayed.isEmpty && _newReleases.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                ContentCarousel(
                  title: 'Recently Played',
                  items: _recentlyPlayed,
                  onItemTap: _onCarouselItemTap,
                ),

                const SizedBox(height: 24),

                // New releases carousel
                ContentCarousel(
                  title: 'New Releases',
                  items: _newReleases,
                  onItemTap: _onCarouselItemTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}