import 'package:flutter/material.dart';

class PlexImage extends StatelessWidget {
  final String? serverUrl;
  final String? token;
  final String? thumbPath;
  final double? width;
  final double? height;
  final IconData placeholderIcon;
  final BoxFit fit;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const PlexImage({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.thumbPath,
    this.width,
    this.height,
    this.placeholderIcon = Icons.music_note,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Construct URL if all parts are present
    String? imageUrl;
    if (thumbPath != null && serverUrl != null && token != null) {
      imageUrl = '$serverUrl$thumbPath?X-Plex-Token=$token';
    }

    Widget content;
    
    if (imageUrl != null) {
      content = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      content = _buildPlaceholder();
    }

    if (shape == BoxShape.circle) {
      return ClipOval(child: content);
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    
    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF282828), // Consistent dark grey
      child: Icon(placeholderIcon, color: Colors.grey, size: (width ?? 40) * 0.5),
    );
  }
}
