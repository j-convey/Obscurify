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
  final String? artistName;
  final String? artistRatingKey;
  final String? artistThumb;
  final int? year;
  final String? serverUrl;
  final String? token;
  final VoidCallback? onArtistTap;

  const AlbumHeader({
    super.key,
    required this.title,
    required this.trackCount,
    this.subtitle,
    this.coverImage,
    this.imageUrl,
    this.gradientColors,
    this.artistName,
    this.artistRatingKey,
    this.artistThumb,
    this.year,
    this.serverUrl,
    this.token,
    this.onArtistTap,
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
            child: imageUrl != null && imageUrl!.isNotEmpty
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
                    // Artist avatar (clickable)
                    MouseRegion(
                      cursor: onArtistTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: onArtistTap,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          backgroundImage: artistThumb != null && serverUrl != null && token != null
                              ? NetworkImage('$serverUrl$artistThumb?X-Plex-Token=$token')
                              : null,
                          child: artistThumb == null ? const Icon(Icons.person, size: 28, color: Colors.white) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Artist name (clickable)
                    if (artistName != null)
                      MouseRegion(
                        cursor: onArtistTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: onArtistTap,
                          child: Text(
                            artistName!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (artistName != null && year != null)
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    // Year
                    if (year != null)
                      Text(
                        '$year',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    if ((artistName != null || year != null))
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    // Song count
                    Text(
                      '$trackCount songs',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
