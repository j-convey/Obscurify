import 'package:flutter/material.dart';
import '../../services/audio_player_service.dart';

class VolumeControls extends StatefulWidget {
  final AudioPlayerService playerService;

  const VolumeControls({
    super.key,
    required this.playerService,
  });

  @override
  State<VolumeControls> createState() => _VolumeControlsState();
}

class _VolumeControlsState extends State<VolumeControls> {
  late double _currentVolume;

  @override
  void initState() {
    super.initState();
    _currentVolume = 0.7;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.queue_music, size: 20),
          color: Colors.grey[400],
          onPressed: () {
            // TODO: Implement queue
          },
        ),
        IconButton(
          icon: const Icon(Icons.devices, size: 20),
          color: Colors.grey[400],
          onPressed: () {
            // TODO: Implement connect to device
          },
        ),
        // Volume control
        Icon(
          _currentVolume == 0 
            ? Icons.volume_mute 
            : _currentVolume < 0.5 
              ? Icons.volume_down 
              : Icons.volume_up,
          size: 20,
          color: _currentVolume == 0 ? Colors.red : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
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
              value: _currentVolume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  _currentVolume = value;
                });
                widget.playerService.setVolume(value);
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.fullscreen, size: 20),
          color: Colors.grey[400],
          onPressed: () {
            // TODO: Implement fullscreen/miniplayer
          },
        ),
      ],
    );
  }
}
