import 'package:flutter/material.dart';
import '../../../core/services/audio_player_service.dart';

class LibraryActionButtons extends StatelessWidget {
  final List<Map<String, dynamic>> tracks;
  final AudioPlayerService? audioPlayerService;
  final String? currentToken;
  final Map<String, String> serverUrls;
  final String? currentServerUrl;

  const LibraryActionButtons({
    super.key,
    required this.tracks,
    required this.audioPlayerService,
    required this.currentToken,
    required this.serverUrls,
    required this.currentServerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black,
          ],
        ),
      ),
      child: Row(
        children: [
          // Play Button
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow, size: 28),
              color: Colors.black,
              onPressed: () {
                if (tracks.isNotEmpty &&
                    audioPlayerService != null &&
                    currentToken != null) {
                  final track = tracks[0];
                  final serverId = track['serverId'] as String?;
                  final serverUrl = serverId != null ? serverUrls[serverId] : currentServerUrl;
                  
                  if (serverUrl != null) {
                    audioPlayerService!.playTrack(
                      track,
                      currentToken!,
                      serverUrl,
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // Shuffle Button
          IconButton(
            icon: const Icon(Icons.shuffle, size: 32),
            color: Colors.grey[400],
            onPressed: () {
              // TODO: Implement shuffle
            },
          ),
          const SizedBox(width: 16),
          // Download Button
          IconButton(
            icon: const Icon(Icons.download, size: 32),
            color: Colors.grey[400],
            onPressed: () {
              // TODO: Implement download
            },
          ),
        ],
      ),
    );
  }
}
