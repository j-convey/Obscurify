part of '../database_service.dart';

/// Extension for album-related database operations.
/// Provides methods to query and manage album data.
extension AlbumsExtension on DatabaseService {
  
  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all albums with artist info and track counts
  Future<List<Map<String, dynamic>>> getAllAlbums() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        a.thumb as artist_thumb,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      GROUP BY alb.id
      ORDER BY alb.title ASC
    ''');

    return maps.map((map) => mapAlbumFromDb(map)).toList();
  }

  /// Get a single album by rating key with full details
  Future<Map<String, dynamic>?> getAlbum(String ratingKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        a.thumb as artist_thumb,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      WHERE alb.rating_key = ?
      GROUP BY alb.id
    ''', [ratingKey]);

    if (maps.isEmpty) return null;
    return mapAlbumFromDb(maps.first);
  }

  /// Get album by internal database ID
  Future<Map<String, dynamic>?> getAlbumById(int albumId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        a.thumb as artist_thumb,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      WHERE alb.id = ?
      GROUP BY alb.id
    ''', [albumId]);

    if (maps.isEmpty) return null;
    return mapAlbumFromDb(maps.first);
  }

  /// Get all tracks for an album, ordered by disc and track number
  Future<List<Map<String, dynamic>>> getTracksForAlbum(String albumRatingKey) async {
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
      JOIN albums alb ON t.album_id = alb.id
      LEFT JOIN artists a ON t.artist_id = a.id
      WHERE alb.rating_key = ?
      ORDER BY t.disc_number ASC, t.track_number ASC, t.title ASC
    ''', [albumRatingKey]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get tracks for album by internal album ID
  Future<List<Map<String, dynamic>>> getTracksForAlbumById(int albumId) async {
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
      JOIN albums alb ON t.album_id = alb.id
      LEFT JOIN artists a ON t.artist_id = a.id
      WHERE alb.id = ?
      ORDER BY t.disc_number ASC, t.track_number ASC, t.title ASC
    ''', [albumId]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get albums by year
  Future<List<Map<String, dynamic>>> getAlbumsByYear(int year) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      WHERE alb.year = ?
      GROUP BY alb.id
      ORDER BY alb.title ASC
    ''', [year]);

    return maps.map((map) => mapAlbumFromDb(map)).toList();
  }

  /// Get recently added albums
  Future<List<Map<String, dynamic>>> getRecentAlbums({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      GROUP BY alb.id
      ORDER BY alb.added_at DESC
      LIMIT ?
    ''', [limit]);

    return maps.map((map) => mapAlbumFromDb(map)).toList();
  }

  /// Search albums by title or artist name
  Future<List<Map<String, dynamic>>> searchAlbums(String query) async {
    if (query.trim().isEmpty) return [];
    
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_title,
        a.rating_key as artist_rating_key,
        COUNT(t.id) as track_count
      FROM albums alb
      LEFT JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      WHERE LOWER(alb.title) LIKE ? OR LOWER(a.title) LIKE ?
      GROUP BY alb.id
      ORDER BY alb.title ASC
      LIMIT 20
    ''', [searchQuery, searchQuery]);

    return maps.map((map) => mapAlbumFromDb(map)).toList();
  }

  /// Get album count
  Future<int> getAlbumCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM albums');
    return result.first['count'] as int;
  }

  /// Get total duration of an album in milliseconds
  Future<int> getAlbumDuration(String albumRatingKey) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(t.duration), 0) as total_duration
      FROM tracks t
      JOIN albums alb ON t.album_id = alb.id
      WHERE alb.rating_key = ?
    ''', [albumRatingKey]);
    
    return result.first['total_duration'] as int? ?? 0;
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save or update an album
  Future<int> saveAlbum(Map<String, dynamic> album, String serverId, {int? artistId}) async {
    final db = await database;
    
    final albumData = {
      'rating_key': album['ratingKey']?.toString() ?? album['parentRatingKey']?.toString(),
      'title': album['title'] ?? album['parentTitle'] ?? 'Unknown Album',
      'artist_id': artistId ?? album['artistId'],
      'artist_name': album['artistName'] ?? album['grandparentTitle'] ?? '',
      'thumb': album['thumb'] ?? album['parentThumb'] ?? '',
      'art': album['art'] ?? '',
      'year': album['year'] ?? 0,
      'genre': album['genre'] ?? '',
      'studio': album['studio'] ?? '',
      'summary': album['summary'] ?? '',
      'track_count': album['trackCount'] ?? album['leafCount'] ?? 0,
      'server_id': serverId,
      'added_at': album['addedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert(
      'albums',
      albumData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Return the album ID
    final result = await db.query(
      'albums',
      where: 'rating_key = ?',
      whereArgs: [albumData['rating_key']],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['id'] as int : -1;
  }

  /// Update album track count (useful after track sync)
  Future<void> updateAlbumTrackCount(String albumRatingKey) async {
    final db = await database;
    
    await db.rawUpdate('''
      UPDATE albums 
      SET track_count = (
        SELECT COUNT(*) FROM tracks t 
        JOIN albums alb ON t.album_id = alb.id 
        WHERE alb.rating_key = ?
      ),
      updated_at = ?
      WHERE rating_key = ?
    ''', [albumRatingKey, DateTime.now().millisecondsSinceEpoch, albumRatingKey]);
  }

  /// Delete an album and optionally its tracks
  Future<void> deleteAlbum(String ratingKey, {bool cascade = false}) async {
    final db = await database;
    
    if (cascade) {
      // Get album ID first
      final albumResult = await db.query(
        'albums',
        where: 'rating_key = ?',
        whereArgs: [ratingKey],
        limit: 1,
      );
      
      if (albumResult.isNotEmpty) {
        final albumId = albumResult.first['id'] as int;
        // Delete tracks for this album
        await db.delete('tracks', where: 'album_id = ?', whereArgs: [albumId]);
      }
    }
    
    await db.delete('albums', where: 'rating_key = ?', whereArgs: [ratingKey]);
  }

  /// Clear all albums (and optionally cascade)
  Future<void> clearAllAlbums({bool cascade = false}) async {
    final db = await database;
    
    if (cascade) {
      await db.delete('tracks');
    }
    
    await db.delete('albums');
    print('DATABASE: Cleared all albums');
  }
}
