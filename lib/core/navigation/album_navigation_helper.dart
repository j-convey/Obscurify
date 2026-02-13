import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../database/database_service.dart';
import '../services/plex/plex_artist_service.dart';
import '../../desktop/features/album/album_page.dart';

/// Helper class for navigating to album pages across the app.
/// Consolidates album navigation logic to ensure consistency.
class AlbumNavigationHelper {
  /// Navigates to an album page with the given parameters.
  /// 
  /// Handles database lookup, image URL construction, and navigation.
  /// Uses [onNavigate] callback if provided, otherwise falls back to Navigator.push.
  static Future<void> navigateToAlbum({
    required BuildContext context,
    required String albumRatingKey,
    required String albumTitle,
    String? albumThumb,
    required String serverUrl,
    required String token,
    AudioPlayerService? audioPlayerService,
    void Function(Widget)? onNavigate,
    DatabaseService? dbService,
    PlexArtistService? artistService,
  }) async {
    // Build image URL if thumb exists
    final imageUrl = albumThumb != null
        ? '$serverUrl$albumThumb?X-Plex-Token=$token'
        : null;

    debugPrint('ALBUM_NAV_HELPER: Navigating to album page for: $albumTitle');

    final albumPage = AlbumPage(
      title: albumTitle,
      subtitle: '$albumTitle • Album',
      audioPlayerService: audioPlayerService,
      imageUrl: imageUrl,
      currentToken: token,
      currentServerUrl: serverUrl,
      onNavigate: onNavigate,
      onLoadTracks: () => loadAlbumTracks(
        albumRatingKey: albumRatingKey,
        serverUrl: serverUrl,
        token: token,
        dbService: dbService,
        artistService: artistService,
      ),
    );

    // Navigate using callback or Navigator
    if (onNavigate != null) {
      onNavigate(albumPage);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => albumPage),
      );
    }
  }

  /// Loads album tracks with smart fallback logic.
  /// 
  /// Tries database first if [dbService] is provided, then falls back to API
  /// if [artistService] is provided. Normalizes track data to ensure
  /// consistent 'artist' field across all sources.
  static Future<List<Map<String, dynamic>>> loadAlbumTracks({
    required String albumRatingKey,
    required String serverUrl,
    required String token,
    DatabaseService? dbService,
    PlexArtistService? artistService,
  }) async {
    List<Map<String, dynamic>> tracks = [];
    
    debugPrint('ALBUM_NAV_HELPER: Loading tracks for album: $albumRatingKey');
    
    // Try database first if available
    if (dbService != null) {
      try {
        final dbTracks = await dbService.tracks.getByAlbum(albumRatingKey);
        tracks = dbTracks.map((track) => track.toJson()).toList();
        debugPrint('ALBUM_NAV_HELPER: Loaded ${tracks.length} tracks from database');
      } catch (e) {
        debugPrint('ALBUM_NAV_HELPER: Error loading from database: $e');
      }
    }
    
    // Fallback to API if no tracks in database
    if (tracks.isEmpty && artistService != null) {
      try {
        tracks = await artistService.getAlbumTracks(
          albumId: albumRatingKey,
          serverUrl: serverUrl,
          token: token,
        );
        debugPrint('ALBUM_NAV_HELPER: Loaded ${tracks.length} tracks from API');
      } catch (e) {
        debugPrint('ALBUM_NAV_HELPER: Error loading from API: $e');
      }
    }
    
    // Normalize all tracks to ensure consistent 'artist' field
    return _normalizeTrackData(tracks);
  }

  /// Normalizes track data to ensure consistent field names.
  /// 
  /// Specifically ensures 'artist' field exists by copying from
  /// 'grandparentTitle' if needed (Plex API structure).
  static List<Map<String, dynamic>> _normalizeTrackData(
    List<Map<String, dynamic>> tracks,
  ) {
    return tracks.map((track) {
      if (track['artist'] == null && track['grandparentTitle'] != null) {
        track['artist'] = track['grandparentTitle'];
      }
      return track;
    }).toList();
  }
}
