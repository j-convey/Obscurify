import 'package:flutter/material.dart';
import 'album_card.dart';

class TopAlbumsSection extends StatelessWidget {
  const TopAlbumsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data
    final topAlbums = [
      {'artist': 'Tame Impala', 'album': 'Currents', 'imagePath': 'assets/images/currents.jpg'},
      {'artist': 'Kendrick Lamar', 'album': 'To Pimp a Butterfly', 'imagePath': 'assets/images/tpab.jpg'},
      {'artist': 'Arctic Monkeys', 'album': 'AM', 'imagePath': 'assets/images/am.jpg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Albums',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topAlbums.length,
            itemBuilder: (context, index) {
              final album = topAlbums[index];
              return Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: AlbumCard(
                  albumName: album['album']!,
                  artistName: album['artist']!,
                  imagePath: album['imagePath']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
