import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/desktop/features/artist/artists_list_page.dart';
import 'package:obscurify/desktop/features/playlists/playlists_page.dart';
import 'package:obscurify/desktop/features/library/library_page.dart';

class BrowsePage extends StatelessWidget {
  final void Function(Widget)? onNavigate;
  final AudioPlayerService? audioPlayerService;

  const BrowsePage({
    super.key,
    this.onNavigate,
    this.audioPlayerService,
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
                        onNavigate!(LibraryPage(onNavigate: onNavigate, audioPlayerService: audioPlayerService));
                      }
                    },
                  ),
                  _buildBrowseTile(
                    'Artists',
                    const Color(0xFF509B95),
                    Icons.person,
                    () {
                      if (onNavigate != null) {
                        onNavigate!(ArtistsListPage(onNavigate: onNavigate, audioPlayerService: audioPlayerService));
                      }
                    },
                  ),
                  _buildBrowseTile(
                    'Playlists',
                    const Color(0xFF4D64A4),
                    Icons.playlist_play,
                    () {
                      if (onNavigate != null) {
                        onNavigate!(PlaylistsPage(onNavigate: onNavigate!, audioPlayerService: audioPlayerService));
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
                  _buildBrowseTile(
                    'Pop',
                    const Color(0xFFE91E63),
                    Icons.star,
                    () {
                      // TODO: Navigate to Pop
                    },
                  ),
                  _buildBrowseTile(
                    'Rock',
                    const Color(0xFF8B4513),
                    Icons.music_note,
                    () {
                      // TODO: Navigate to Rock
                    },
                  ),
                  _buildBrowseTile(
                    'Country',
                    const Color(0xFFA0826D),
                    Icons.landscape,
                    () {
                      // TODO: Navigate to Country
                    },
                  ),
                  _buildBrowseTile(
                    'Hip-Hop',
                    const Color(0xFF6A1B9A),
                    Icons.mic,
                    () {
                      // TODO: Navigate to Hip-Hop
                    },
                  ),
                  _buildBrowseTile(
                    'Indie',
                    const Color(0xFF00897B),
                    Icons.headphones,
                    () {
                      // TODO: Navigate to Indie
                    },
                  ),
                  _buildBrowseTile(
                    'Love',
                    const Color(0xFFC2185B),
                    Icons.favorite,
                    () {
                      // TODO: Navigate to Love
                    },
                  ),
                  _buildBrowseTile(
                    'Party',
                    const Color(0xFFF57C00),
                    Icons.celebration,
                    () {
                      // TODO: Navigate to Party
                    },
                  ),
                  _buildBrowseTile(
                    'Workout',
                    const Color(0xFFD84315),
                    Icons.fitness_center,
                    () {
                      // TODO: Navigate to Workout
                    },
                  ),
                  _buildBrowseTile(
                    'Dance/Electronic',
                    const Color(0xFF7B1FA2),
                    Icons.graphic_eq,
                    () {
                      // TODO: Navigate to Dance/Electronic
                    },
                  ),
                  _buildBrowseTile(
                    'Jazz',
                    const Color(0xFF283593),
                    Icons.piano,
                    () {
                      // TODO: Navigate to Jazz
                    },
                  ),
                  _buildBrowseTile(
                    'Metal',
                    const Color(0xFF424242),
                    Icons.bolt,
                    () {
                      // TODO: Navigate to Metal
                    },
                  ),
                  _buildBrowseTile(
                    'Disney',
                    const Color(0xFF1565C0),
                    Icons.castle,
                    () {
                      // TODO: Navigate to Disney
                    },
                  ),
                  _buildBrowseTile(
                    'Christian & Gospel',
                    const Color(0xFFD4AF37),
                    Icons.church,
                    () {
                      // TODO: Navigate to Christian & Gospel
                    },
                  ),
                  _buildBrowseTile(
                    'Classical',
                    const Color(0xFF6D214F),
                    Icons.music_note,
                    () {
                      // TODO: Navigate to Classical
                    },
                  ),
                  _buildBrowseTile(
                    'TV & Movies',
                    const Color(0xFFD32F2F),
                    Icons.tv,
                    () {
                      // TODO: Navigate to TV & Movies
                    },
                  ),
                  _buildBrowseTile(
                    'K-pop',
                    const Color(0xFFAD1457),
                    Icons.stars,
                    () {
                      // TODO: Navigate to K-pop
                    },
                  ),
                  _buildBrowseTile(
                    'Gaming',
                    const Color(0xFF388E3C),
                    Icons.videogame_asset,
                    () {
                      // TODO: Navigate to Gaming
                    },
                  ),
                  _buildBrowseTile(
                    'Nature & Noise',
                    const Color(0xFF558B2F),
                    Icons.nature,
                    () {
                      // TODO: Navigate to Nature & Noise
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
                      color: Colors.black.withValues(alpha: 0.4),
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
                        color: Colors.black.withValues(alpha: 0.3),
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
