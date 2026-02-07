import 'package:flutter/material.dart';
import 'package:apollo/core/models/artist.dart';

class ArtistListItem extends StatelessWidget {
  final Artist artist;
  final String? serverUrl;
  final String? token;
  final VoidCallback onTap;

  const ArtistListItem({
    super.key,
    required this.artist,
    this.serverUrl,
    this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipOval(
        child: SizedBox.fromSize(
          size: const Size.fromRadius(28), // Image radius
          child: _buildImage(),
        ),
      ),
      title: Text(
        artist.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Artist',
        style: TextStyle(color: Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }

  Widget _buildImage() {
    if (artist.thumb != null && serverUrl != null && token != null) {
      return Image.network(
        '$serverUrl${artist.thumb}?X-Plex-Token=$token',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
