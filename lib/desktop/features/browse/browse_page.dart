import 'package:flutter/material.dart';
import 'package:obscurify/desktop/features/playlists/playlists_page.dart';
import 'package:obscurify/desktop/features/songs/songs_page.dart';

class BrowsePage extends StatelessWidget {
  final void Function(Widget)? onNavigate;

  const BrowsePage({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse all',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildBrowseTile(
                    'Library',
                    const Color(0xFFDC148C),
                    Icons.library_music,
                    () {
                      if (onNavigate != null) {
                        onNavigate!(SongsPage(onNavigate: onNavigate));
                      }
                    },
                  ),
                  _buildBrowseTile(
                    'Artists',
                    const Color(0xFF509B95),
                    Icons.person,
                    () {
                      // TODO: Navigate to Artists
                    },
                  ),
                  _buildBrowseTile(
                    'Playlists',
                    const Color(0xFF4D64A4),
                    Icons.playlist_play,
                    () {
                      if (onNavigate != null) {
                        onNavigate!(PlaylistsPage(onNavigate: onNavigate!));
                      }
                    },
                  ),
                  _buildBrowseTile(
                    'Albums',
                    const Color(0xFF8D4B9E),
                    Icons.album,
                    () {
                      // TODO: Navigate to Albums
                    },
                  ),
                  _buildBrowseTile(
                    'Album Genres',
                    const Color(0xFF477D95),
                    Icons.category,
                    () {
                      // TODO: Navigate to Album Genres
                    },
                  ),
                  _buildBrowseTile(
                    'New Releases',
                    const Color(0xFFB07936),
                    Icons.new_releases,
                    () {
                      // TODO: Navigate to New Releases
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseTile(
    String title,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return _BrowseTileWidget(
      title: title,
      color: color,
      icon: icon,
      onTap: onTap,
    );
  }
}

class _BrowseTileWidget extends StatefulWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _BrowseTileWidget({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_BrowseTileWidget> createState() => _BrowseTileWidgetState();
}

class _BrowseTileWidgetState extends State<_BrowseTileWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Icon(
                        widget.icon,
                        size: 80,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
