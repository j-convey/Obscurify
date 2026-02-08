import 'package:flutter/material.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/models/playlist.dart';
import '../../../../core/models/track.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String trackId; // This is the ratingKey
  final String trackTitle;

  const AddToPlaylistSheet({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final DatabaseService _db = DatabaseService();
  List<Playlist> _playlists = [];
  Map<String, bool> _playlistMembership = {}; // playlistId -> is track in it
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final playlists = await _db.playlists.getAll();
    final membership = <String, bool>{};

    for (final playlist in playlists) {
      final isIn = await _db.playlists.isTrackInPlaylist(playlist.id, widget.trackId);
      membership[playlist.id] = isIn;
    }

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _playlistMembership = membership;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMembership(Playlist playlist) async {
    final currentlyIn = _playlistMembership[playlist.id] ?? false;
    
    try {
      if (currentlyIn) {
        await _db.playlists.removeTrack(playlist.id, widget.trackId);
      } else {
        await _db.playlists.addTrack(playlist.id, widget.trackId);
      }

      if (mounted) {
        setState(() {
          _playlistMembership[playlist.id] = !currentlyIn;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating playlist: $e')),
        );
      }
    }
  }

  Future<void> _createNewPlaylist() async {
    // Basic implementation - creates a playlist named "New Playlist X"
    final count = await _db.playlists.getCount();
    final newId = 'local_${DateTime.now().millisecondsSinceEpoch}'; // Generate local ID
    final newPlaylist = Playlist(
      id: newId,
      title: 'New Playlist ${count + 1}',
      smart: false,
      serverId: '', // Local playlist
    );

    await _db.playlists.save(newPlaylist);
    await _loadData(); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _createNewPlaylist,
                  child: const Text(
                    'New playlist',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Search Bar (Placeholder for now)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Find playlist', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Sort', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          // Playlist List
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  final isIn = _playlistMembership[playlist.id] ?? false;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      // TODO: Show playlist image
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
                    title: Text(
                      playlist.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${playlist.leafCount} songs',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: isIn
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
                    onTap: () => _toggleMembership(playlist),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
