import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/models/track.dart';
import '../artist/mobile_artist_page.dart';
import '../../shared/widgets/plex_image.dart';
import '../../shared/widgets/track_tile.dart';

class MobileSearchPage extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;

  const MobileSearchPage({
    super.key,
    this.audioPlayerService,
  });

  @override
  State<MobileSearchPage> createState() => _MobileSearchPageState();
}

class _MobileSearchPageState extends State<MobileSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService(); // To get token for images

  List<Track> _trackResults = [];
  List<Map<String, dynamic>> _artistResults = [];
  bool _isSearching = false;
  String? _token;
  Map<String, String> _serverUrls = {};

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final token = await _storageService.getPlexToken();
    final urlMap = await _storageService.getServerUrlMap();
    if (mounted) {
      setState(() {
        _token = token;
        _serverUrls = urlMap;
      });
    }
  }

  void _onSearchChanged() {
    final query = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _trackResults = [];
        _artistResults = [];
        _isSearching = false;
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    // Search tracks (returns Track objects directly from new repo)
    final trackResults = await _dbService.tracks.search(query);
    
    // Search artists (returns List<Artist>)
    final artistResultsObjects = await _dbService.artists.search(query);
    
    // Convert to Maps to satisfy the type of _artistResults
    final artistResults = artistResultsObjects.map((a) => a.toJson()).toList();

    if (mounted) {
      setState(() {
        _trackResults = trackResults;
        _artistResults = artistResults;
        _isSearching = false;
      });
    }
  }

  void _playTrack(Track track) {
    if (widget.audioPlayerService == null || _token == null) return;

    final serverUrl = _serverUrls[track.serverId];
    if (serverUrl == null) return;

    // Create a queue from the search results
    final queue = _trackResults.map((t) => t.toJson()).toList();
    final index = _trackResults.indexOf(track);

    widget.audioPlayerService!.setPlayQueue(queue, index);
    widget.audioPlayerService!.playTrack(track.toJson(), _token!, serverUrl);
  }

  void _navigateToArtist(Map<String, dynamic> artist) {
    // Artist search result from DB might differ slightly in structure
    final ratingKey = artist['ratingKey'] as String? ?? artist['rating_key'] as String?;
    final name = artist['name'] as String? ?? artist['title'] as String?;
    
    if (ratingKey != null && name != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobileArtistPage(
            artistId: ratingKey,
            artistName: name,
            audioPlayerService: widget.audioPlayerService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Artists, songs, or albums',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_controller.text.isEmpty) {
      return const Center(
        child: Text(
          'Search your music library',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_trackResults.isEmpty && _artistResults.isEmpty) {
      return Center(
        child: Text(
          _isSearching ? 'Searching...' : 'No results found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: [
        if (_artistResults.isNotEmpty) ...[
          const Text(
            'Artists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._artistResults.map((artist) {
            // Determine image URL
            final thumb = artist['thumb'] as String?;
            final serverId = artist['serverId'] as String? ?? artist['server_id'] as String?;
            
            final url = serverId != null ? _serverUrls[serverId] : null;

            return ListTile(
              leading: PlexImage(
                serverUrl: url,
                token: _token,
                thumbPath: thumb,
                placeholderIcon: Icons.person,
                shape: BoxShape.circle,
                width: 40,
                height: 40,
              ),
              title: Text(
                artist['name'] as String? ?? artist['title'] as String? ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text('Artist', style: TextStyle(color: Colors.grey)),
              onTap: () => _navigateToArtist(artist),
            );
          }),
          const SizedBox(height: 24),
        ],
        if (_trackResults.isNotEmpty) ...[
          const Text(
            'Songs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._trackResults.map((track) {
            final serverUrl = _serverUrls[track.serverId];
            return TrackTile(
              track: track,
              serverUrl: serverUrl,
              token: _token,
              onTap: () => _playTrack(track),
            );
          }),
          const SizedBox(height: 100), // Bottom padding
        ],
      ],
    );
  }
}
