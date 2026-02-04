part of '../database_service.dart';

/// Extension for artist-related database operations.
/// Provides methods to query and manage artist data.
extension ArtistsExtension on DatabaseService {
  
  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all artists with album and track counts
  Future<List<Map<String, dynamic>>> getAllArtists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*,
        COUNT(DISTINCT alb.id) as album_count,
        COUNT(DISTINCT t.id) as track_count
      FROM artists a
      LEFT JOIN albums alb ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.artist_id = a.id
      GROUP BY a.id
      ORDER BY a.title ASC
    ''');

    return maps.map((map) => mapArtistFromDb(map)).toList();
  }

  /// Get a single artist by rating key
  Future<Map<String, dynamic>?> getArtist(String ratingKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*,
        COUNT(DISTINCT alb.id) as album_count,
        COUNT(DISTINCT t.id) as track_count
      FROM artists a
      LEFT JOIN albums alb ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.artist_id = a.id
      WHERE a.rating_key = ?
      GROUP BY a.id
    ''', [ratingKey]);

    if (maps.isEmpty) return null;
    return mapArtistFromDb(maps.first);
  }

  /// Get artist by internal database ID
  Future<Map<String, dynamic>?> getArtistById(int artistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*,
        COUNT(DISTINCT alb.id) as album_count,
        COUNT(DISTINCT t.id) as track_count
      FROM artists a
      LEFT JOIN albums alb ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.artist_id = a.id
      WHERE a.id = ?
      GROUP BY a.id
    ''', [artistId]);

    if (maps.isEmpty) return null;
    return mapArtistFromDb(maps.first);
  }

  /// Get all albums by an artist (with track counts)
  Future<List<Map<String, dynamic>>> getAlbumsByArtist(String artistRatingKey) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        alb.*,
        a.title as artist_name,
        a.rating_key as artist_rating_key,
        COUNT(t.id) as track_count
      FROM albums alb
      JOIN artists a ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.album_id = alb.id
      WHERE a.rating_key = ?
      GROUP BY alb.id
      ORDER BY alb.year DESC, alb.title ASC
    ''', [artistRatingKey]);

    return maps.map((map) => mapAlbumFromDb(map)).toList();
  }

  /// Get all tracks by an artist
  Future<List<Map<String, dynamic>>> getTracksByArtist(String artistRatingKey) async {
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
      JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE a.rating_key = ?
      ORDER BY alb.year DESC, alb.title ASC, t.disc_number ASC, t.track_number ASC
    ''', [artistRatingKey]);

    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Search artists by name
  Future<List<Map<String, dynamic>>> searchArtists(String query) async {
    if (query.trim().isEmpty) return [];
    
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        a.*,
        COUNT(DISTINCT alb.id) as album_count,
        COUNT(DISTINCT t.id) as track_count
      FROM artists a
      LEFT JOIN albums alb ON alb.artist_id = a.id
      LEFT JOIN tracks t ON t.artist_id = a.id
      WHERE LOWER(a.title) LIKE ?
      GROUP BY a.id
      ORDER BY a.title ASC
      LIMIT 20
    ''', [searchQuery]);

    return maps.map((map) => mapArtistFromDb(map)).toList();
  }

  /// Get artist count
  Future<int> getArtistCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM artists');
    return result.first['count'] as int;
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save or update an artist
  Future<int> saveArtist(Map<String, dynamic> artist, String serverId) async {
    final db = await database;
    
    final artistData = {
      'rating_key': artist['ratingKey']?.toString() ?? artist['grandparentRatingKey']?.toString(),
      'title': artist['title'] ?? artist['grandparentTitle'] ?? 'Unknown Artist',
      'thumb': artist['thumb'] ?? artist['grandparentThumb'] ?? '',
      'art': artist['art'] ?? artist['grandparentArt'] ?? '',
      'summary': artist['summary'] ?? '',
      'genre': artist['genre'] ?? '',
      'country': artist['country'] ?? '',
      'server_id': serverId,
      'added_at': artist['addedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    // Insert or update
    await db.insert(
      'artists',
      artistData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Return the artist ID
    final result = await db.query(
      'artists',
      where: 'rating_key = ?',
      whereArgs: [artistData['rating_key']],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['id'] as int : -1;
  }

  /// Delete an artist and optionally their albums and tracks
  Future<void> deleteArtist(String ratingKey, {bool cascade = false}) async {
    final db = await database;
    
    if (cascade) {
      // Get artist ID first
      final artistResult = await db.query(
        'artists',
        where: 'rating_key = ?',
        whereArgs: [ratingKey],
        limit: 1,
      );
      
      if (artistResult.isNotEmpty) {
        final artistId = artistResult.first['id'] as int;
        
        // Delete tracks for this artist
        await db.delete('tracks', where: 'artist_id = ?', whereArgs: [artistId]);
        
        // Delete albums for this artist
        await db.delete('albums', where: 'artist_id = ?', whereArgs: [artistId]);
      }
    }
    
    // Delete the artist
    await db.delete('artists', where: 'rating_key = ?', whereArgs: [ratingKey]);
  }

  /// Clear all artists (and optionally cascade)
  Future<void> clearAllArtists({bool cascade = false}) async {
    final db = await database;
    
    if (cascade) {
      await db.delete('tracks');
      await db.delete('albums');
    }
    
    await db.delete('artists');
    print('DATABASE: Cleared all artists');
  }
}
