import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/home_data_service.dart';
import 'package:obscurify/core/services/plex_connection_resolver.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/shared/widgets/content_carousel.dart';
import 'package:obscurify/desktop/features/library/library_page.dart';
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
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  final DatabaseService _dbService = DatabaseService();

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
      // Use the resolver for all URL/token resolution
      await _resolver.initialise();
      
      String? token = _resolver.userToken;
      _resolvedServerUrls = _resolver.serverUrls;
      
      // If no cached URLs, fetch from API
      if (_resolvedServerUrls.isEmpty && token != null) {
        _resolvedServerUrls = await _resolver.fetchAndCacheServerUrls();
      }

      // Get the selected server connection (respects shared server tokens)
      final connection = await _resolver.getSelectedServerConnection();
      String? serverUrl = connection?.url;
      // For API calls, use the connection token (could be shared server token)
      token = connection?.token ?? token;
      
      if (serverUrl == null && _resolvedServerUrls.isNotEmpty) {
        serverUrl = _resolvedServerUrls.values.first;
      }

      _resolvedToken = token;
      _resolvedServerUrl = serverUrl;

      if (token == null || serverUrl == null || serverUrl.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final newReleases = await _homeDataService.getNewReleases(
        serverUrl: serverUrl,
        token: token,
      );

      debugPrint('HOME_PAGE: got ${newReleases.length} new releases');
      debugPrint('HOME_PAGE: ===== NEW RELEASES ORDER RECEIVED =====');
      for (int i = 0; i < newReleases.length && i < 10; i++) {
        final item = newReleases[i];
        final originallyAvailable = item.data?['originallyAvailableAt'];
        final year = item.data?['year'];
        debugPrint('HOME_PAGE: [$i] "${item.title}" - ${item.subtitle}');
        debugPrint('         originallyAvailableAt=$originallyAvailable, year=$year');
      }
      debugPrint('HOME_PAGE: =========================================');

      if (mounted) {
        setState(() {
          _newReleases = newReleases;
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
        // For artist navigation, use per-server token if available
        final serverId = item.data?['serverId'] as String?;
        final effectiveToken = _resolver.getTokenForServer(serverId) ?? token;
        final effectiveUrl = _resolver.getUrlForServer(serverId) ?? serverUrl;
        
        widget.onNavigate!(ArtistPage(
          artistId: item.id,
          artistName: item.title,
          serverUrl: effectiveUrl,
          token: effectiveToken,
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
        // Play the track directly - use per-server token
        if (widget.audioPlayerService != null && item.data != null) {
          final serverId = item.data!['serverId'] as String?;
          final effectiveToken = _resolver.getTokenForServer(serverId) ?? token;
          final effectiveUrl = _resolver.getUrlForServer(serverId) ?? serverUrl;
          
          widget.audioPlayerService!.setServerUrls(_resolvedServerUrls);
          widget.audioPlayerService!.playTrack(
            item.data!,
            effectiveToken,
            effectiveUrl,
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
                            widget.onNavigate!(LibraryPage(
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

              // New releases carousel
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_newReleases.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No new releases',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ContentCarousel(
                  title: 'New Releases',
                  items: _newReleases,
                  onItemTap: _onCarouselItemTap,
                ),
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