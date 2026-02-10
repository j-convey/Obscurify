import 'package:flutter/material.dart';

/// A card widget displaying an album with its cover and title.
/// Used in the artist page album carousel.
class ArtistAlbumCard extends StatefulWidget {
  /// The album data map from Plex API
  final Map<String, dynamic> album;

  /// The base server URL for building image URLs
  final String serverUrl;

  /// The Plex authentication token
  final String token;

  /// Callback when the album is tapped
  final VoidCallback? onTap;

  /// The width of the card
  final double width;

  const ArtistAlbumCard({
    super.key,
    required this.album,
    required this.serverUrl,
    required this.token,
    this.onTap,
    this.width = 160,
  });

  @override
  State<ArtistAlbumCard> createState() => _ArtistAlbumCardState();
}

class _ArtistAlbumCardState extends State<ArtistAlbumCard> {
  bool _isHovered = false;

  String _buildImageUrl(String? imagePath) {
    if (imagePath == null) return '';
    return '${widget.serverUrl}$imagePath?X-Plex-Token=${widget.token}';
  }

  @override
  Widget build(BuildContext context) {
    final thumbPath = widget.album['thumb'];
    final title = widget.album['title'] ?? 'Unknown Album';
    final year = widget.album['year'];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF282828)
                : const Color(0xFF181818),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album cover
              Stack(
                children: [
                  Container(
                    width: widget.width - 24,
                    height: widget.width - 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: thumbPath != null
                          ? Image.network(
                              _buildImageUrl(thumbPath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  // Play button overlay on hover
                  if (_isHovered)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Album title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Year
              Text(
                year?.toString() ?? 'Album',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.album, color: Colors.grey, size: 48),
      ),
    );
  }
}
