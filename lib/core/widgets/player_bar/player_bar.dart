import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';
import 'track_info_section.dart';
import 'playback_controls.dart';
import 'volume_controls.dart';

class PlayerBar extends StatelessWidget {
  final AudioPlayerService playerService;
  final void Function(Widget)? onNavigate;

  const PlayerBar({
    super.key,
    required this.playerService,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, child) {
        final track = playerService.currentTrack;
        
        if (track == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 90,
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(color: Colors.black),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Left section: Track info (30%)
                Expanded(
                  flex: 3,
                  child: TrackInfoSection(
                    track: track,
                    playerService: playerService,
                    onNavigate: onNavigate,
                  ),
                ),
                
                // Center section: Playback controls (40%)
                Expanded(
                  flex: 4,
                  child: PlaybackControls(
                    playerService: playerService,
                  ),
                ),
                
                // Right section: Volume controls (30%)
                Expanded(
                  flex: 3,
                  child: VolumeControls(
                    playerService: playerService,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
