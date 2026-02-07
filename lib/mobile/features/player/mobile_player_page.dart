import 'package:flutter/material.dart';
import '../../../../core/services/audio_player_service.dart';

class MobilePlayerPage extends StatefulWidget {
  final AudioPlayerService audioPlayerService;
  final void Function(String artistId, String artistName)? onArtistTap;

  const MobilePlayerPage({
    super.key,
    required this.audioPlayerService,
    this.onArtistTap,
  });

  @override
  State<MobilePlayerPage> createState() => _MobilePlayerPageState();
}

class _MobilePlayerPageState extends State<MobilePlayerPage> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    final minutes = duration.inMinutes;
    return '$minutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.audioPlayerService,
      builder: (context, _) {
        final track = widget.audioPlayerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final isPlaying = widget.audioPlayerService.isPlaying;
        final duration = widget.audioPlayerService.duration;
        final position = widget.audioPlayerService.position;
        final token = widget.audioPlayerService.currentToken;
        final serverUrl = widget.audioPlayerService.currentServerUrl;

        // Use drag value if dragging, otherwise current position
        final sliderValue = _isDragging
            ? _dragValue
            : position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble());

        final maxDuration = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;

        // Extract image URL
        String? imageUrl;
        if (track['thumb'] != null && serverUrl != null && token != null) {
          imageUrl = '$serverUrl${track['thumb']}?X-Plex-Token=$token';
        }

        return Scaffold(
          backgroundColor: const Color(0xFF4A2525), // Dark reddish-brown background
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 60, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PLAYING FROM YOUR LIBRARY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track['album'] ?? 'Liked Songs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          // TODO: Show options
                        },
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Album Art
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Track Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track['title'] ?? 'Unknown Title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                if (widget.onArtistTap != null) {
                                  // Prefer grandparentRatingKey (Artist ID), fallback to empty string if not found
                                  final artistId = track['grandparentRatingKey']?.toString() ?? '';
                                  final artistName = track['artist'] ?? track['grandparentTitle'] ?? 'Unknown Artist';
                                  if (artistId.isNotEmpty) {
                                    widget.onArtistTap!(artistId, artistName);
                                  }
                                }
                              },
                              child: Text(
                                track['artist'] ?? 'Unknown Artist',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.check, color: Colors.black, size: 20),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: sliderValue.clamp(0.0, maxDuration),
                          max: maxDuration,
                          onChangeStart: (value) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = value;
                            });
                          },
                          onChanged: (value) {
                            setState(() {
                              _dragValue = value;
                            });
                          },
                          onChangeEnd: (value) {
                            widget.audioPlayerService.seek(Duration(seconds: value.toInt()));
                            setState(() {
                              _isDragging = false;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_isDragging ? Duration(seconds: _dragValue.toInt()) : position),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.white, size: 28),
                        onPressed: () {
                          // TODO: Shuffle
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 42),
                        onPressed: () => widget.audioPlayerService.previous(),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 40,
                          ),
                          onPressed: () => widget.audioPlayerService.togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 42),
                        onPressed: () => widget.audioPlayerService.next(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: Colors.white, size: 28),
                        onPressed: () {
                          // TODO: Repeat
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speaker_group_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Lossless',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.share_outlined, color: Colors.white, size: 24),
                          const SizedBox(width: 32),
                          const Icon(Icons.queue_music, color: Colors.white, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF282828),
      child: const Center(
        child: Icon(Icons.music_note, color: Colors.grey, size: 64),
      ),
    );
  }
}
