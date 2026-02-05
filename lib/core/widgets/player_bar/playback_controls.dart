import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';

class PlaybackControls extends StatelessWidget {
  final AudioPlayerService playerService;

  const PlaybackControls({
    super.key,
    required this.playerService,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle button
            IconButton(
              icon: const Icon(Icons.shuffle, size: 16),
              color: Colors.grey[400],
              onPressed: () {
                // TODO: Implement shuffle
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            // Previous button
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 28),
              color: Colors.white,
              onPressed: () {
                playerService.previous();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            // Play/Pause button
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  playerService.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 18,
                ),
                color: Colors.black,
                padding: EdgeInsets.zero,
                onPressed: () {
                  playerService.togglePlayPause();
                },
              ),
            ),
            const SizedBox(width: 16),
            // Next button
            IconButton(
              icon: const Icon(Icons.skip_next, size: 28),
              color: Colors.white,
              onPressed: () {
                playerService.next();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            // Repeat button
            IconButton(
              icon: const Icon(Icons.repeat, size: 16),
              color: Colors.grey[400],
              onPressed: () {
                // TODO: Implement repeat
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar with time stamps
        Row(
          children: [
            // Current time
            Text(
              _formatDuration(playerService.position),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  thumbColor: Colors.white,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.grey[700],
                ),
                child: Slider(
                  value: playerService.position.inSeconds.toDouble(),
                  max: playerService.duration.inSeconds.toDouble() > 0
                      ? playerService.duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    playerService.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Total duration
            Text(
              _formatDuration(playerService.duration),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
