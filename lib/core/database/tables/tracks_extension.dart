part of '../database_service.dart';

/// Extension for track-related database operations.
/// Provides methods to query and manage track data.
extension TracksExtension on DatabaseService {
  
  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save tracks to database with proper foreign keys to artists and albums
  Future<void> saveTracks(
    String serverId,
    String libraryKey,
    List<Map<String, dynamic>> tracks,
  ) async {
    final db = await database;

    // Delete existing tracks for this server/library
    await db.delete(
      'tracks',
      where: 'server_id = ? AND library_key = ?',
      whereArgs: [serverId, libraryKey],
    );

    // Insert tracks with proper artist and album associations
    for (var track in tracks) {
      int? artistId;
      int? albumId;

      // Insert or get artist
      if (track['grandparentRatingKey'] != null && track['grandparentTitle'] != null) {
        try {
          await db.insert(
            'artists',
            {
              'rating_key': track['grandparentRatingKey'].toString(),
              'title': track['grandparentTitle'] as String,
              'thumb': track['grandparentThumb'] as String? ?? '',
              'art': track['grandparentArt'] as String? ?? '',
              'server_id': serverId,
              'added_at': track['addedAt'] ?? DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (e) {
          debugPrint('Error inserting artist: $e');
        }

        // Get the artist ID
        final artistResult = await db.query(
          'artists',
          where: 'rating_key = ?',
          whereArgs: [track['grandparentRatingKey'].toString()],
          limit: 1,
        );
        if (artistResult.isNotEmpty) {
          artistId = artistResult.first['id'] as int?;
        }
      }

      // Insert or get album
      if (track['parentRatingKey'] != null && track['parentTitle'] != null) {
        try {
          await db.insert(
            'albums',
            {
              'rating_key': track['parentRatingKey'].toString(),
              'title': track['parentTitle'] as String,
              'artist_id': artistId,
              'artist_name': track['grandparentTitle'] as String? ?? '',
              'thumb': track['parentThumb'] as String? ?? '',
              'year': track['year'] as int? ?? 0,
              'server_id': serverId,
              'added_at': track['addedAt'] ?? DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (e) {
          debugPrint('Error inserting album: $e');
        }

        // Get the album ID
        final albumResult = await db.query(
          'albums',
          where: 'rating_key = ?',
          whereArgs: [track['parentRatingKey'].toString()],
          limit: 1,
        );
        if (albumResult.isNotEmpty) {
          albumId = albumResult.first['id'] as int?;
        }
      }

      // Insert track with foreign keys and new fields
      try {
        await db.insert(
          'tracks',
          {
            'server_id': serverId,
            'library_key': libraryKey,
            'track_key': track['key'] ?? '',
            'rating_key': track['ratingKey']?.toString(),
            'title': track['title'] ?? 'Unknown',
            'artist_id': artistId,
            'artist_name': track['grandparentTitle'] as String? ?? '',
            'album_id': albumId,
            'album_name': track['parentTitle'] as String? ?? '',
            'track_number': track['index'] as int? ?? track['trackNumber'] as int?,
            'disc_number': track['parentIndex'] as int? ?? track['discNumber'] as int? ?? 1,
            'duration': track['duration'] ?? 0,
            'thumb': track['thumb'] ?? '',
            'year': track['year'] ?? 0,
            'genre': track['genre'] as String?,
            'added_at': track['addedAt'],
            'media_data': jsonEncode(track['Media'] ?? []),
            'user_rating': track['userRating'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error inserting track: $e');
      }
    }

    // Update sync metadata
    await db.insert(
      'sync_metadata',
      {
        'server_id': serverId,
        'library_key': libraryKey,
        'last_sync': DateTime.now().millisecondsSinceEpoch,
        'track_count': tracks.length,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('DATABASE: Saved ${tracks.length} tracks with normalized schema for server $serverId, library $libraryKey');
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all tracks from database with joined artist and album data
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      ORDER BY t.title ASC
    ''');

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get tracks for specific server/library
  Future<List<Map<String, dynamic>>> getTracksForLibrary(
    String serverId,
    String libraryKey,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE t.server_id = ? AND t.library_key = ?
      ORDER BY t.title ASC
    ''', [serverId, libraryKey]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Search tracks by title, artist, or album
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];
    
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE LOWER(t.title) LIKE ? 
         OR LOWER(COALESCE(a.title, t.artist_name)) LIKE ? 
         OR LOWER(COALESCE(alb.title, t.album_name)) LIKE ?
      ORDER BY t.title ASC
      LIMIT 20
    ''', [searchQuery, searchQuery, searchQuery]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get liked tracks (user_rating >= 10.0)
  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE t.user_rating >= ?
      ORDER BY t.title ASC
    ''', [10.0]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get recently added tracks
  Future<List<Map<String, dynamic>>> getRecentTracks({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      ORDER BY t.added_at DESC
      LIMIT ?
    ''', [limit]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get a single track by rating key
  Future<Map<String, dynamic>?> getTrack(String ratingKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        t.artist_name as artist_name_stored,
        t.album_name as album_name_stored,
        a.title as artist_name,
        a.thumb as artist_thumb,
        a.rating_key as artist_rating_key,
        alb.title as album_name,
        alb.thumb as album_thumb,
        alb.rating_key as album_rating_key
      FROM tracks t
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE t.rating_key = ?
    ''', [ratingKey]);

    if (maps.isEmpty) return null;
    return mapTrackFromDb(maps.first);
  }

  // ============================================================
  // METADATA OPERATIONS
  // ============================================================

  /// Get sync metadata for a library
  Future<Map<String, dynamic>?> getSyncMetadata(String serverId, String libraryKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_metadata',
      where: 'server_id = ? AND library_key = ?',
      whereArgs: [serverId, libraryKey],
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get all sync info
  Future<List<Map<String, dynamic>>> getAllSyncMetadata() async {
    final db = await database;
    return await db.query('sync_metadata');
  }

  /// Check if we have cached data
  Future<bool> hasCachedTracks() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tracks');
    final count = result.first['count'] as int;
    return count > 0;
  }

  /// Get track count
  Future<int> getTrackCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tracks');
    return result.first['count'] as int;
  }

  // ============================================================
  // DELETE OPERATIONS
  // ============================================================

  /// Clear all tracks
  Future<void> clearAllTracks() async {
    final db = await database;
    await db.delete('tracks');
    await db.delete('sync_metadata');
    print('DATABASE: Cleared all tracks');
  }

  /// Clear tracks for specific server
  Future<void> clearServerTracks(String serverId) async {
    final db = await database;
    await db.delete('tracks', where: 'server_id = ?', whereArgs: [serverId]);
    await db.delete('sync_metadata', where: 'server_id = ?', whereArgs: [serverId]);
    print('DATABASE: Cleared tracks for server $serverId');
  }

  /// Update user rating for a track
  Future<void> updateTrackRating(String ratingKey, double? rating) async {
    final db = await database;
    await db.update(
      'tracks',
      {'user_rating': rating},
      where: 'rating_key = ?',
      whereArgs: [ratingKey],
    );
  }
}