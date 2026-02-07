import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/track.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import 'base_repository.dart';

/// Repository for track-related database operations
class TrackRepository extends BaseRepository {
  TrackRepository(super.getDatabase);

  // ============================================================
  // READ OPERATIONS - Single Responsibility
  // ============================================================

  /// Get all tracks (uses view)
  Future<List<Track>> getAll() async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full ORDER BY title COLLATE NOCASE ASC
    ''');
    return maps.map(Track.fromDb).toList();
  }

  /// Get track by rating key
  Future<Track?> getByRatingKey(String ratingKey) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full WHERE rating_key = ?
    ''', [ratingKey]);
    if (maps.isEmpty) return null;
    return Track.fromDb(maps.first);
  }

  /// Get tracks for a specific library
  Future<List<Track>> getByLibrary(String serverId, String libraryKey) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE server_id = ? AND library_key = ?
      ORDER BY title COLLATE NOCASE ASC
    ''', [serverId, libraryKey]);
    return maps.map(Track.fromDb).toList();
  }

  /// Get tracks for an album
  Future<List<Track>> getByAlbum(String albumRatingKey) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE album_rating_key = ?
      ORDER BY disc_number ASC, track_number ASC, title COLLATE NOCASE ASC
    ''', [albumRatingKey]);
    return maps.map(Track.fromDb).toList();
  }

  /// Get tracks for an album by ID
  Future<List<Track>> getByAlbumId(int albumId) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE album_id = ?
      ORDER BY disc_number ASC, track_number ASC, title COLLATE NOCASE ASC
    ''', [albumId]);
    return maps.map(Track.fromDb).toList();
  }

  /// Get tracks for an artist
  Future<List<Track>> getByArtist(String artistRatingKey) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE artist_rating_key = ?
      ORDER BY album_name, disc_number, track_number
    ''', [artistRatingKey]);
    return maps.map(Track.fromDb).toList();
  }

  /// Get liked tracks (rating >= 10)
  Future<List<Track>> getLiked() async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE user_rating >= 10.0
      ORDER BY title COLLATE NOCASE ASC
    ''');
    return maps.map(Track.fromDb).toList();
  }

  /// Get recently added tracks
  Future<List<Track>> getRecent({int limit = 50}) async {
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      ORDER BY added_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Track.fromDb).toList();
  }

  /// Search tracks by title, artist, or album
  Future<List<Track>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final searchQuery = '%${query.toLowerCase()}%';
    final maps = await rawQuery('''
      SELECT * FROM v_tracks_full 
      WHERE title COLLATE NOCASE LIKE ? 
         OR artist_name COLLATE NOCASE LIKE ? 
         OR album_name COLLATE NOCASE LIKE ?
      ORDER BY title COLLATE NOCASE ASC
      LIMIT ?
    ''', [searchQuery, searchQuery, searchQuery, limit]);
    return maps.map(Track.fromDb).toList();
  }

  /// Get track count
  Future<int> getCount() async {
    return count('tracks');
  }

  /// Check if we have cached tracks
  Future<bool> hasCached() async {
    return (await getCount()) > 0;
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save tracks with automatic artist/album extraction (optimized for Mobile)
  /// Uses batch operations to minimize platform channel overhead.
  Future<void> saveAll(
    String serverId,
    String libraryKey,
    List<Track> tracks, {
    void Function(int current, int total)? onProgress,
  }) async {
    final db = await getDatabase();
    
    // Use a transaction for performance and integrity
    await db.transaction((txn) async {
      // 1. Delete existing tracks for this library to prevent duplicates
      await txn.delete(
        'tracks',
        where: 'server_id = ? AND library_key = ?',
        whereArgs: [serverId, libraryKey],
      );

      // 2. Identify and Insert Unique Artists
      // We process all artists first to ensure foreign keys can be resolved
      final uniqueArtists = <String, Artist>{};
      for (final track in tracks) {
        if (track.artistRatingKey != null && 
            track.artistName.isNotEmpty && 
            !uniqueArtists.containsKey(track.artistRatingKey)) {
          uniqueArtists[track.artistRatingKey!] = Artist(
            ratingKey: track.artistRatingKey!,
            name: track.artistName,
            thumb: track.artistThumb,
            serverId: serverId,
            addedAt: track.addedAt,
          );
        }
      }

      if (uniqueArtists.isNotEmpty) {
        final artistBatch = txn.batch();
        for (final artist in uniqueArtists.values) {
          artistBatch.insert(
            'artists', 
            artist.toDb(), 
            conflictAlgorithm: ConflictAlgorithm.ignore
          );
        }
        await artistBatch.commit(noResult: true);
      }

      // 3. Retrieve Artist IDs
      // We need the internal database IDs to link albums and tracks
      final artistIds = <String, int>{};
      if (uniqueArtists.isNotEmpty) {
        final List<Map<String, dynamic>> results = await txn.query(
          'artists',
          columns: ['rating_key', 'id'],
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
        
        for (final row in results) {
          final ratingKey = row['rating_key'] as String;
          final id = row['id'] as int;
          artistIds[ratingKey] = id;
        }
      }

      // 4. Identify and Insert Unique Albums
      final uniqueAlbums = <String, Album>{};
      for (final track in tracks) {
        if (track.albumRatingKey != null && 
            track.albumName.isNotEmpty && 
            !uniqueAlbums.containsKey(track.albumRatingKey)) {
          
          final artistId = track.artistRatingKey != null ? artistIds[track.artistRatingKey] : null;

          uniqueAlbums[track.albumRatingKey!] = Album(
            ratingKey: track.albumRatingKey!,
            title: track.albumName,
            artistId: artistId,
            artistName: track.artistName,
            thumb: track.albumThumb,
            year: track.year,
            serverId: serverId,
            addedAt: track.addedAt,
          );
        }
      }

      if (uniqueAlbums.isNotEmpty) {
        final albumBatch = txn.batch();
        for (final album in uniqueAlbums.values) {
          albumBatch.insert(
            'albums', 
            album.toDb(), 
            conflictAlgorithm: ConflictAlgorithm.ignore
          );
        }
        await albumBatch.commit(noResult: true);
      }

      // 5. Retrieve Album IDs
      final albumIds = <String, int>{};
      if (uniqueAlbums.isNotEmpty) {
        final List<Map<String, dynamic>> results = await txn.query(
          'albums',
          columns: ['rating_key', 'id'],
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
        
        for (final row in results) {
          final ratingKey = row['rating_key'] as String;
          final id = row['id'] as int;
          albumIds[ratingKey] = id;
        }
      }

      // 6. Insert Tracks in Batches
      // Batching here prevents UI freeze on mobile by allowing UI to render between batches
      const batchSize = 500; 
      for (int batchStart = 0; batchStart < tracks.length; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize).clamp(0, tracks.length);
        final batch = tracks.sublist(batchStart, batchEnd);
        
        final trackBatch = txn.batch();

        for (final track in batch) {
          int? artistId;
          int? albumId;

          if (track.artistRatingKey != null) {
            artistId = artistIds[track.artistRatingKey];
          }
          
          if (track.albumRatingKey != null) {
            albumId = albumIds[track.albumRatingKey];
          }

          final trackWithFks = track.copyWith(
            artistId: artistId,
            albumId: albumId,
          );
          trackBatch.insert('tracks', trackWithFks.toDb());
        }

        await trackBatch.commit(noResult: true);

        onProgress?.call(batchEnd, tracks.length);
      }

      // 7. Update Sync Metadata
      await txn.insert(
        'sync_metadata',
        {
          'server_id': serverId,
          'library_key': libraryKey,
          'last_sync': DateTime.now().millisecondsSinceEpoch,
          'track_count': tracks.length,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    debugPrint('DATABASE: Saved ${tracks.length} tracks for $serverId/$libraryKey');
  }

  /// Update track rating
  Future<void> updateRating(String ratingKey, double? rating) async {
    await update(
      'tracks',
      {'user_rating': rating},
      where: 'rating_key = ?',
      whereArgs: [ratingKey],
    );
  }

  /// Clear all tracks
  Future<void> clearAll() async {
    await delete('tracks');
    await delete('sync_metadata');
    debugPrint('DATABASE: Cleared all tracks');
  }

  /// Clear tracks for a specific server
  Future<void> clearByServer(String serverId) async {
    await delete('tracks', where: 'server_id = ?', whereArgs: [serverId]);
    await delete('sync_metadata', where: 'server_id = ?', whereArgs: [serverId]);
    debugPrint('DATABASE: Cleared tracks for server $serverId');
  }

  // ============================================================
  // SYNC METADATA
  // ============================================================

  /// Get sync metadata for a library
  Future<Map<String, dynamic>?> getSyncMetadata(String serverId, String libraryKey) async {
    final maps = await query(
      'sync_metadata',
      where: 'server_id = ? AND library_key = ?',
      whereArgs: [serverId, libraryKey],
    );
    return maps.isEmpty ? null : maps.first;
  }

  /// Get all sync metadata
  Future<List<Map<String, dynamic>>> getAllSyncMetadata() async {
    return query('sync_metadata');
  }
}
