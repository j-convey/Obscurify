import 'package:flutter/material.dart';

class LibraryHeader extends StatelessWidget {
  final int trackCount;

  const LibraryHeader({
    super.key,
    required this.trackCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade800,
            Colors.purple.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Album Art / Icon
          Container(
            width: 232,
            height: 232,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade300,
                  Colors.purple.shade400,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          // Title and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Library • $trackCount songs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
