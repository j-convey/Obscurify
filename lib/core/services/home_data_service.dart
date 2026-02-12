import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../../shared/widgets/content_carousel.dart';

/// Service that provides data for the home page carousels.
///
/// Lives in core so it can be shared between desktop and mobile.
/// Pulls from the local database (recently played, new releases, etc.).
class HomeDataService {
  final DatabaseService _db = DatabaseService();

  // ---------------------------------------------------------------
  // Recently Played
  // ---------------------------------------------------------------

  /// Returns a mixed list of recently played tracks, albums and artists
  /// represented as [CarouselItem]s ready for the carousel widget.
  ///
  /// [serverUrl] and [token] are used to build fully-qualified image URLs.
  Future<List<CarouselItem>> getRecentlyPlayed({
    required String serverUrl,
    required String token,
    int limit = 20,
  }) async {
    try {
      // Fetch recent tracks – these give us songs + album + artist info
      final recentTracks = await _db.tracks.getRecent(limit: limit);

      final List<CarouselItem> items = [];
      final Set<String> seenKeys = {};

      for (final track in recentTracks) {
        // Skip duplicate tracks (same ratingKey)
        if (seenKeys.contains(track.ratingKey)) continue;
        seenKeys.add(track.ratingKey);

        // Use the track's own thumb — this is the field that works
        // everywhere else in the app (collection page, player bar, etc.).
        items.add(CarouselItem(
          id: track.ratingKey,
          title: track.title,
          subtitle: '${track.artistName} · ${track.albumName}',
          imageUrl: _buildImageUrl(
            track.thumb,
            serverUrl: serverUrl,
            token: token,
          ),
          type: CarouselItemType.track,
          data: track.toJson(),
        ));
      }

      return items.take(limit).toList();
    } catch (e) {
      debugPrint('HOME_DATA_SERVICE: Error getting recently played: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------
  // New Releases (recently added albums)
  // ---------------------------------------------------------------

  /// Returns albums sorted by release year (newest releases first) as [CarouselItem]s.
  Future<List<CarouselItem>> getNewReleases({
    required String serverUrl,
    required String token,
    int limit = 20,
  }) async {
    try {
      final albums = await _db.albums.getByReleaseYear(limit: limit);
      debugPrint('HOME_DATA_SERVICE: getNewReleases found ${albums.length} albums');
      debugPrint('HOME_DATA_SERVICE: First 5 albums in order:');
      for (int i = 0; i < albums.length && i < 5; i++) {
        debugPrint('  [$i] "${albums[i].title}" by ${albums[i].artistName} - Released: ${albums[i].originallyAvailableAt ?? "unknown"} (Year: ${albums[i].year})');
      }

      // For each album, find a track that belongs to it and use that
      // track's thumb.  This is the exact pattern the collection page
      // and player bar use — and it works reliably everywhere.
      final albumRatingKeys = albums.map((a) => a.ratingKey).toList();
      final trackByAlbum = <String, Track>{};

      for (final rk in albumRatingKeys) {
        if (!trackByAlbum.containsKey(rk)) {
          final tracks = await _db.tracks.getByAlbum(rk);
          if (tracks.isNotEmpty) {
            trackByAlbum[rk] = tracks.first;
          }
        }
      }

      debugPrint('HOME_DATA_SERVICE: matched tracks for ${trackByAlbum.length}/${albums.length} albums');

      final items = albums.map((album) {
        // Prefer the track's albumThumb (from the joined albums table),
        // then fall back to the track's own thumb, then the album's thumb.
        final matchedTrack = trackByAlbum[album.ratingKey];
        final thumbToUse = matchedTrack?.albumThumb ??
            matchedTrack?.thumb ??
            album.thumb;

        final imageUrl = _buildImageUrl(
          thumbToUse,
          serverUrl: serverUrl,
          token: token,
        );

        debugPrint('HOME_DATA_SERVICE: Album "${album.title}" '
            'albumThumb=${album.thumb}, '
            'trackThumb=${matchedTrack?.thumb}, '
            'trackAlbumThumb=${matchedTrack?.albumThumb}, '
            'thumbToUse=$thumbToUse, '
            'imageUrl=$imageUrl');

        return CarouselItem(
          id: album.ratingKey,
          title: album.title,
          subtitle: _albumSubtitle(album),
          imageUrl: imageUrl,
          type: CarouselItemType.album,
          data: {
            'ratingKey': album.ratingKey,
            'title': album.title,
            'artistName': album.artistName,
            'artistRatingKey': album.artistRatingKey,
            'thumb': album.thumb,
            'year': album.year,
            'originallyAvailableAt': album.originallyAvailableAt,
            'serverId': album.serverId,
          },
        );
      }).toList();

      // Debug: Check if album rating keys match what tracks have
      debugPrint('HOME_DATA_SERVICE: Verifying album-track relationships:');
      for (int i = 0; i < albums.length && i < 3; i++) {
        final album = albums[i];
        final trackCount = await _db.tracks.getByAlbum(album.ratingKey);
        debugPrint('  Album "${album.title}" (${album.ratingKey}): ${trackCount.length} tracks');
      }
      
      debugPrint('HOME_DATA_SERVICE: returning ${items.length} carousel items, '
          '${items.where((i) => i.imageUrl != null && i.imageUrl!.isNotEmpty).length} have images');

      return items;
    } catch (e) {
      debugPrint('HOME_DATA_SERVICE: Error getting new releases: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  /// Build a fully-qualified Plex image URL from a relative thumb path.
  /// Uses the exact same `$serverUrl$thumbPath?X-Plex-Token=` pattern
  /// as the working collection track list item.
  String? _buildImageUrl(
    String? thumbPath, {
    required String serverUrl,
    required String token,
  }) {
    if (thumbPath == null || thumbPath.isEmpty) return null;
    final cleanUrl = serverUrl.replaceAll(RegExp(r'/$'), '');
    return '$cleanUrl$thumbPath?X-Plex-Token=$token';
  }

  /// Compose a nice subtitle for an album card.
  String _albumSubtitle(Album album) {
    final parts = <String>[];
    if (album.year != null && album.year! > 0) {
      parts.add('${album.year}');
    }
    parts.add(album.artistName);
    return parts.join(' · ');
  }
}
