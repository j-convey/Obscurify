import 'package:flutter/material.dart';
import 'package:apollo/core/models/artist.dart';
import 'package:apollo/core/database/database_service.dart';
import 'package:apollo/core/services/storage_service.dart';
import 'mobile_artist_page.dart';
import 'widgets/artist_list_item.dart';

class MobileArtistsListPage extends StatefulWidget {
  const MobileArtistsListPage({super.key});

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Artists'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                return ArtistListItem(
                  artist: artist,
                  serverUrl: _serverUrl,
                  token: _token,
                  onTap: () => _navigateToArtist(artist),
                );
              },
            ),
    );
  }
}
