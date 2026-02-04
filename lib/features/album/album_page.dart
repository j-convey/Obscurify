import 'package:flutter/material.dart';
import '../../core/services/audio_player_service.dart';
import '../collection/collection_page.dart';
import '../collection/widgets/collection_header.dart' show CollectionType;

/// Album page that displays an album of tracks.
/// Uses the reusable CollectionPage component.
class AlbumPage extends StatelessWidget {
  /// The title of the album
  final String title;

  /// Optional subtitle override. If null, defaults to "$title • $trackCount songs"
  final String? subtitle;

  /// The type of album being displayed
  final AlbumType albumType;

  /// The audio player service for playback
  final AudioPlayerService? audioPlayerService;

  /// The tracks to display
  final List<Map<String, dynamic>>? tracks;

  /// Optional custom cover image widget
  final Widget? coverImage;

  /// Optional cover image URL
  final String? imageUrl;

  /// Optional gradient colors for the header
  final List<Color>? gradientColors;

  /// Callback to load tracks if not provided directly
  final Future<List<Map<String, dynamic>>> Function()? onLoadTracks;

  /// Current Plex token
  final String? currentToken;

  /// Map of server IDs to URLs
  final Map<String, String>? serverUrls;

  /// Current server URL
  final String? currentServerUrl;

  /// Error message to show when no tracks are available
  final String? emptyMessage;

  const AlbumPage({
    super.key,
    required this.title,
    this.subtitle,
    this.albumType = AlbumType.album,
    this.audioPlayerService,
    this.tracks,
    this.coverImage,
    this.imageUrl,
    this.gradientColors,
    this.onLoadTracks,
    this.currentToken,
    this.serverUrls,
    this.currentServerUrl,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionPage(
      title: title,
      subtitle: subtitle,
      collectionType: _mapAlbumTypeToCollectionType(albumType),
      audioPlayerService: audioPlayerService,
      tracks: tracks,
      coverImage: coverImage,
      imageUrl: imageUrl,
      gradientColors: gradientColors,
      onLoadTracks: onLoadTracks,
      currentToken: currentToken,
      serverUrls: serverUrls,
      currentServerUrl: currentServerUrl,
      emptyMessage: emptyMessage,
    );
  }

  CollectionType _mapAlbumTypeToCollectionType(AlbumType type) {
    switch (type) {
      case AlbumType.library:
        return CollectionType.library;
      case AlbumType.playlist:
        return CollectionType.playlist;
      case AlbumType.album:
        return CollectionType.album;
      case AlbumType.artist:
        return CollectionType.artist;
    }
  }
}

/// Represents the type of album being displayed
enum AlbumType {
  library,
  playlist,
  album,
  artist,
}
