import 'package:flutter/material.dart';

/// Header widget for album pages
/// Displays the album cover image, title, subtitle, and track count
class AlbumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int trackCount;
  final Widget? coverImage;
  final String? imageUrl;
  final List<Color>? gradientColors;

  const AlbumHeader({
    super.key,
    required this.title,
    required this.trackCount,
    this.subtitle,
    this.coverImage,
    this.imageUrl,
    this.gradientColors,
  });

  List<Color> get _defaultGradientColors {
    return [
      Colors.teal.shade700,
      Colors.teal.shade900,
      Colors.black,
    ];
  }

  Widget get _defaultCoverImage {
    return Container(
      width: 232,
      height: 232,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.album,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? _defaultGradientColors;
    final displaySubtitle = subtitle ?? '$title • Album';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Album cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 232,
                    height: 232,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _defaultCoverImage;
                    },
                  )
                : (coverImage ?? _defaultCoverImage),
          ),
          const SizedBox(width: 32),
          // Album info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'ALBUM',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.album, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displaySubtitle,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$trackCount songs',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
