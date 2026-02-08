import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/track.dart';
import '../../../core/services/plex/plex_services.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/audio_player_service.dart';
import 'widgets/track_options_sheet.dart';
import '../../shared/widgets/track_tile.dart';

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
  late Future<List<Track>> _tracksFuture;
  
  String? _currentToken;
  Map<String, String> _serverUrls = {};

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _loadServerUrls();
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
    setState(() {
      _loadTracks();
    });
    await _loadServerUrls();
  }

  void _showTrackOptions(BuildContext context, Track track, String? serverUrl) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show over everything including mini player
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

    // Set queue with all tracks in the list
    final trackMaps = allTracks.map((t) => t.toJson()).toList();
    final index = allTracks.indexOf(track);
    
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTracks,
                color: Colors.purple,
                child: FutureBuilder<List<Track>>(
                  future: _tracksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purple));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Your library is empty',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final tracks = snapshot.data!;
                    return ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final serverUrl = _serverUrls[track.serverId];

                        return TrackTile(
                          track: track,
                          serverUrl: serverUrl,
                          token: _currentToken,
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: () => _showTrackOptions(context, track, serverUrl),
                          ),
                          onLongPress: () => _showTrackOptions(context, track, serverUrl),
                          onTap: () => _playTrack(track, tracks),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
