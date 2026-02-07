import 'package:flutter/material.dart';

class MobileArtistPage extends StatelessWidget {
  final String artistId;
  final String artistName;

  const MobileArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(artistName),
      ),
      body: Center(
        child: Text(
          'Page for $artistName',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
