import 'package:flutter/material.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/plex/plex_services.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/track.dart';
import 'widgets/home_nav_bar.dart';

/// Mobile home page with quick access buttons matching the desktop layout.
class MobileHomePage extends StatefulWidget {
  final VoidCallback? onNavigateToLibrary;
  final VoidCallback? onOpenDrawer;
  final AudioPlayerService? audioPlayerService;
  
  const MobileHomePage({
    super.key,
    this.onNavigateToLibrary,
    this.onOpenDrawer,
    this.audioPlayerService,
  });

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final DatabaseService _db = DatabaseService();
  final PlexServerService _serverService = PlexServerService();
  final StorageService _storageService = StorageService();
  
  List<Track> _recentTracks = [];
  bool _isLoading = true;
  String? _currentToken;
  Map<String, String> _serverUrls = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load tracks
    final tracks = await _db.tracks.getRecent(limit: 20);
    
    // Load server info
    final token = await _storageService.getPlexToken();
    Map<String, String> urls = {};
    if (token != null) {
      urls = await _serverService.fetchServerUrlMap(token);
    }
    
    if (mounted) {
      setState(() {
        _recentTracks = tracks;
        _currentToken = token;
        _serverUrls = urls;
        _isLoading = false;
      });
      
      // Update player service with server URLs
      widget.audioPlayerService?.setServerUrls(urls);
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

    // Set queue with recent tracks
    final trackMaps = _recentTracks.map((t) => t.toJson()).toList();
    final index = _recentTracks.indexOf(track);
    
    widget.audioPlayerService!.setPlayQueue(trackMaps, index);
    await widget.audioPlayerService!.playTrack(
      track.toJson(),
      _currentToken!,
      serverUrl,
    );
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
                              // TODO: Navigate to playlists
                            },
                          ),
                          _QuickAccessTile(
                            icon: Icons.person,
                            label: 'Artists',
                            color: Colors.orange,
                            onTap: () {
                              // TODO: Navigate to artists
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
                            final serverUrl = _serverUrls[track.serverId];
                            final imageUrl = track.thumb != null && serverUrl != null && _currentToken != null
                                ? '$serverUrl${track.thumb!}?X-Plex-Token=$_currentToken'
                                : null;

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
