import 'package:flutter/material.dart';
import '../../core/database/database_service.dart';
import '../../core/models/playlist.dart';
import '../../core/services/plex_connection_resolver.dart';

/// A reusable dialog for adding a track to playlists.
/// Shows all playlists with checkmarks for ones the track is already in.
/// Can be used from player bar, track lists, context menus, etc.
class AddToPlaylistDialog extends StatefulWidget {
  /// The ratingKey of the track to add/remove from playlists.
  final String trackId;

  /// Display title of the track (shown in header).
  final String trackTitle;

  /// Optional server URL for loading playlist artwork.
  final String? serverUrl;

  /// Optional Plex token for loading playlist artwork.
  final String? token;

  const AddToPlaylistDialog({
    super.key,
    required this.trackId,
    required this.trackTitle,
    this.serverUrl,
    this.token,
  });

  /// Shows the dialog as a popup anchored above the given button context.
  /// The bottom-left corner of the dialog will appear above the button.
  /// Returns true if any changes were made.
  static Future<bool?> show(
    BuildContext context, {
    required String trackId,
    required String trackTitle,
    String? serverUrl,
    String? token,
  }) {
    // Get the button's position
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Offset? offset = renderBox?.localToGlobal(Offset.zero);

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: offset?.dx ?? 0,
              bottom: MediaQuery.of(context).size.height - (offset?.dy ?? 0) + 8,
              child: Material(
                color: Colors.transparent,
                child: AddToPlaylistDialog(
                  trackId: trackId,
                  trackTitle: trackTitle,
                  serverUrl: serverUrl,
                  token: token,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
  }

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  final DatabaseService _db = DatabaseService();
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  final TextEditingController _searchController = TextEditingController();

  List<Playlist> _allPlaylists = [];
  List<Playlist> _filteredPlaylists = [];
  Map<String, bool> _membership = {};
  bool _isLoading = true;
  bool _hasChanges = false;
  String? _serverUrl;
  String? _token;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterPlaylists);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Use provided server info or fall back to resolver
    await _resolver.initialise();
    String? token = widget.token;
    String? serverUrl = widget.serverUrl;
    if (token == null || serverUrl == null) {
      final connection = await _resolver.getSelectedServerConnection();
      token ??= connection?.token;
      serverUrl ??= connection?.url;
    }

    final playlists = await _db.playlists.getAll();
    final membership = <String, bool>{};

    for (final playlist in playlists) {
      final isIn = await _db.playlists.isTrackInPlaylist(
        playlist.id,
        widget.trackId,
      );
      membership[playlist.id] = isIn;
    }

    if (mounted) {
      setState(() {
        _token = token;
        _serverUrl = serverUrl;
        _allPlaylists = playlists;
        _filteredPlaylists = playlists;
        _membership = membership;
        _isLoading = false;
      });
    }
  }

  void _filterPlaylists() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredPlaylists = _allPlaylists;
      } else {
        _filteredPlaylists = _allPlaylists
            .where((p) => p.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _toggleMembership(Playlist playlist) async {
    final currentlyIn = _membership[playlist.id] ?? false;

    try {
      if (currentlyIn) {
        await _db.playlists.removeTrack(playlist.id, widget.trackId);
      } else {
        await _db.playlists.addTrack(playlist.id, widget.trackId);
      }

      if (mounted) {
        setState(() {
          _membership[playlist.id] = !currentlyIn;
          _hasChanges = true;
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
    final count = await _db.playlists.getCount();
    final newId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final newPlaylist = Playlist(
      id: newId,
      title: 'New Playlist ${count + 1}',
      smart: false,
      serverId: '',
    );

    await _db.playlists.save(newPlaylist);
    // Add the track to the new playlist immediately
    await _db.playlists.addTrack(newId, widget.trackId);

    _hasChanges = true;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Split playlists into "saved in" and "others"
    final savedIn = <Playlist>[];
    final others = <Playlist>[];
    for (final playlist in _filteredPlaylists) {
      if (_membership[playlist.id] == true) {
        savedIn.add(playlist);
      } else {
        others.add(playlist);
      }
    }

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Add to playlist',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E3E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Find a playlist',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // New playlist button
          InkWell(
            onTap: _createNewPlaylist,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Playlist list
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // "Saved in" section
                  if (savedIn.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Saved in',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...savedIn.map((p) => _buildPlaylistTile(p, true)),
                  ],

                  // "Recently updated" / other playlists
                  if (others.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Recently updated',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...others.map((p) => _buildPlaylistTile(p, false)),
                  ],
                ],
              ),
            ),

          // Cancel button
          const Divider(color: Colors.white10, height: 1),
          InkWell(
            onTap: () => Navigator.of(context).pop(_hasChanges),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, bool isIn) {
    return InkWell(
      onTap: () => _toggleMembership(playlist),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Playlist artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: _buildPlaylistImage(playlist),
            ),
            const SizedBox(width: 12),
            // Playlist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.push_pin, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${playlist.leafCount} songs',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Check / uncheck indicator
            if (isIn)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistImage(Playlist playlist) {
    if (playlist.composite != null && _serverUrl != null && _token != null) {
      return Image.network(
        '$_serverUrl${playlist.composite}?X-Plex-Token=$_token',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF3E3E3E),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 24),
    );
  }
}
