import 'package:flutter/material.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/models/playlist.dart';
import '../../playlists/widgets/add_to_playlist_sheet.dart';

class MobileMiniPlayer extends StatelessWidget {
  final AudioPlayerService audioPlayerService;
  final VoidCallback? onTap;

  const MobileMiniPlayer({
    super.key,
    required this.audioPlayerService,
    this.onTap,
  });

  void _handlePlaylistTap(BuildContext context, String trackId, String trackTitle, bool isInPlaylist) async {
    final db = DatabaseService();
    
    if (isInPlaylist) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => AddToPlaylistSheet(
          trackId: trackId,
          trackTitle: trackTitle,
        ),
      );
      // Refresh status after sheet closes (user might have removed track)
      audioPlayerService.refreshPlaylistStatus();
    } else {
      try {
        Playlist? likedPlaylist = await db.playlists.getByTitle('Liked Songs');
        if (likedPlaylist == null) {
          final newId = 'local_liked_${DateTime.now().millisecondsSinceEpoch}';
          likedPlaylist = Playlist(
            id: newId,
            title: 'Liked Songs',
            smart: false,
            serverId: '',
          );
          await db.playlists.save(likedPlaylist);
        }

        await db.playlists.addTrack(likedPlaylist.id, trackId);
        
        // Refresh status immediately so icon turns green
        audioPlayerService.refreshPlaylistStatus();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added to Liked Songs'),
              action: SnackBarAction(
                label: 'Change',
                textColor: Colors.green,
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => AddToPlaylistSheet(
                      trackId: trackId,
                      trackTitle: trackTitle,
                    ),
                  );
                  // Refresh again after sheet closes
                  audioPlayerService.refreshPlaylistStatus();
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: audioPlayerService,
      builder: (context, _) {
        final track = audioPlayerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final isPlaying = audioPlayerService.isPlaying;
        final isInPlaylist = audioPlayerService.isInPlaylist;
        final token = audioPlayerService.currentToken;
        final serverUrl = audioPlayerService.currentServerUrl;

        // Extract image URL
        String? imageUrl;
        if (track['thumb'] != null && serverUrl != null && token != null) {
          imageUrl = '$serverUrl${track['thumb']}?X-Plex-Token=$token';
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3E1F1F), // Dark reddish-brown like the picture
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 12),
                
                // Title and Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              track['artist'] ?? 'Unknown Artist',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Lossless tag
                          const SizedBox(width: 4),
                          const Text(
                            '•',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Lossless', // Placeholder for format info
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.speaker_group_outlined, color: Colors.white), // Connect device icon
                      onPressed: () {
                        // TODO: Connect device
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                    ),
                    const SizedBox(width: 16),
                    
                    // Playlist Status Icon
                    GestureDetector(
                      onTap: () => _handlePlaylistTap(
                        context,
                        track['ratingKey']?.toString() ?? '',
                        track['title'] ?? '',
                        isInPlaylist,
                      ),
                      child: isInPlaylist
                          ? Container(
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.check, color: Colors.black, size: 16),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                    ),

                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => audioPlayerService.togglePlayPause(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 8),
                  ],
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
      width: 40,
      height: 40,
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 20),
    );
  }
}
