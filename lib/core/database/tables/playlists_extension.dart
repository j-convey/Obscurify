part of '../database_service.dart';

/// Extension for playlist-related database operations.
/// Provides methods to query and manage playlist data.
extension PlaylistsExtension on DatabaseService {
  
  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save playlists to database
  Future<void> savePlaylists(List<Map<String, dynamic>> playlists, String serverId) async {
    final db = await database;
    final batch = db.batch();

    for (var playlist in playlists) {
      final playlistData = {
        'id': playlist['id'],
        'title': playlist['title'] ?? 'Unknown',
        'summary': playlist['summary'],
        'type': playlist['type'],
        'smart': playlist['smart'] == true ? 1 : 0,
        'composite': playlist['composite'],
        'duration': playlist['duration'],
        'leaf_count': playlist['leafCount'] ?? 0,
        'server_id': serverId,
      };
      batch.insert(
        'playlists',
        playlistData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('DATABASE: Saved ${playlists.length} playlists for server $serverId');
  }

  /// Save playlist tracks association
  Future<void> savePlaylistTracks(
    String playlistId,
    List<Map<String, dynamic>> tracks,
  ) async {
    final db = await database;
    
    // Delete existing tracks for this playlist
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    // Insert new playlist-track associations
    int position = 0;
    for (var track in tracks) {
      // Get the track ID from the database
      final trackResults = await db.query(
        'tracks',
        where: 'track_key = ?',
        whereArgs: [track['key'] ?? ''],
        limit: 1,
      );

      if (trackResults.isNotEmpty) {
        final trackId = trackResults.first['id'];
        try {
          await db.insert(
            'playlist_tracks',
            {
              'playlist_id': playlistId,
              'track_id': trackId,
              'position': position,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          position++;
        } catch (e) {
          debugPrint('Error inserting playlist track: $e');
        }
      }
    }

    print('DATABASE: Saved ${tracks.length} tracks for playlist $playlistId');
  }

  /// Delete a playlist and its track associations
  Future<void> deletePlaylist(String playlistId) async {
    final db = await database;
    await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    print('DATABASE: Deleted playlist $playlistId');
  }

  /// Clear all playlists
  Future<void> clearAllPlaylists() async {
    final db = await database;
    await db.delete('playlist_tracks');
    await db.delete('playlists');
    print('DATABASE: Cleared all playlists');
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all playlists from database
  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    final db = await database;
    return await db.query('playlists', orderBy: 'title ASC');
  }

  /// Get playlist metadata
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    final db = await database;
    final results = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  /// Get playlists for a specific server
  Future<List<Map<String, dynamic>>> getPlaylistsForServer(String serverId) async {
    final db = await database;
    return await db.query(
      'playlists',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'title ASC',
    );
  }

  /// Get tracks for a specific playlist with full details
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
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
        alb.rating_key as album_rating_key,
        pt.position
      FROM playlist_tracks pt
      JOIN tracks t ON pt.track_id = t.id
      LEFT JOIN artists a ON t.artist_id = a.id
      LEFT JOIN albums alb ON t.album_id = alb.id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', [playlistId]);

    // Use the shared mapTrackFromDb method
    return maps.map((map) => mapTrackFromDb(map)).toList();
  }

  /// Get playlist count
  Future<int> getPlaylistCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM playlists');
    return result.first['count'] as int;
  }

  /// Search playlists by title
  Future<List<Map<String, dynamic>>> searchPlaylists(String query) async {
    if (query.trim().isEmpty) return [];
    
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    
    return await db.query(
      'playlists',
      where: 'LOWER(title) LIKE ?',
      whereArgs: [searchQuery],
      orderBy: 'title ASC',
      limit: 20,
    );
  }
}