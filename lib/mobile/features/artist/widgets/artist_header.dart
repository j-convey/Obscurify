import 'package:flutter/material.dart';

class ArtistHeader extends StatelessWidget {
  final String artistName;
  final String? imageUrl;

  const ArtistHeader({
    super.key,
    required this.artistName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                )
              : Container(color: Colors.grey[900]),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  const Color(0xFF121212),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Artist Name
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              artistName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
