import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;
import '../../models/playlist.dart';
import '../../models/track.dart';
import 'base_repository.dart';

/// Repository for playlist-related database operations
class PlaylistRepository extends BaseRepository {
  PlaylistRepository(super.getDatabase);

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get all playlists
  Future<List<Playlist>> getAll() async {
    final maps = await query('playlists', orderBy: 'title COLLATE NOCASE ASC');
    return maps.map(Playlist.fromDb).toList();
  }

  /// Get playlist by ID
  Future<Playlist?> getById(String id) async {
    final maps = await query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Playlist.fromDb(maps.first);
  }

  /// Get playlist by Title
  Future<Playlist?> getByTitle(String title) async {
    final maps = await query(
      'playlists',
      where: 'title = ?',
      whereArgs: [title],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Playlist.fromDb(maps.first);
  }

  /// Get playlists for a server
  Future<List<Playlist>> getByServer(String serverId) async {
    final maps = await query(
      'playlists',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return maps.map(Playlist.fromDb).toList();
  }

  /// Search playlists by title
  Future<List<Playlist>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final searchQuery = '%${query.toLowerCase()}%';
    final maps = await rawQuery('''
      SELECT * FROM playlists 
      WHERE title COLLATE NOCASE LIKE ?
      ORDER BY title COLLATE NOCASE ASC
      LIMIT ?
    ''', [searchQuery, limit]);
    return maps.map(Playlist.fromDb).toList();
  }

  /// Get playlist count
  Future<int> getCount() async {
    return count('playlists');
  }

  /// Check if a track is in any playlist
  Future<bool> isTrackInAnyPlaylist(String trackKey) async {
    final maps = await rawQuery('''
      SELECT 1 FROM playlist_tracks pt
      JOIN tracks t ON pt.track_id = t.id
      WHERE t.rating_key = ?
      LIMIT 1
    ''', [trackKey]);
    return maps.isNotEmpty;
  }

  /// Check if a track is in a specific playlist
  Future<bool> isTrackInPlaylist(String playlistId, String trackKey) async {
    final maps = await rawQuery('''
      SELECT 1 FROM playlist_tracks pt
      JOIN tracks t ON pt.track_id = t.id
      WHERE pt.playlist_id = ? AND t.rating_key = ?
      LIMIT 1
    ''', [playlistId, trackKey]);
    return maps.isNotEmpty;
  }

  // ============================================================
  // EAGER LOADING
  // ============================================================

  /// Get playlist with its tracks
  Future<Playlist?> getWithTracks(String playlistId) async {
    final playlist = await getById(playlistId);
    if (playlist == null) return null;

    final trackMaps = await rawQuery('''
      SELECT * FROM v_playlist_tracks_full 
      WHERE playlist_id = ?
      ORDER BY position ASC
    ''', [playlistId]);

    return playlist.copyWith(
      tracks: trackMaps.map(Track.fromDb).toList(),
    );
  }

  /// Get tracks for a playlist
  Future<List<Track>> getTracks(String playlistId) async {
    final trackMaps = await rawQuery('''
      SELECT * FROM v_playlist_tracks_full 
      WHERE playlist_id = ?
      ORDER BY position ASC
    ''', [playlistId]);
    return trackMaps.map(Track.fromDb).toList();
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Create or Update a playlist
  Future<void> save(Playlist playlist) async {
    await insert(
      'playlists',
      playlist.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple playlists
  Future<void> saveAll(List<Playlist> playlists) async {
    final db = await getDatabase();
    final batch = db.batch();

    for (final playlist in playlists) {
      batch.insert(
        'playlists',
        playlist.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('DATABASE: Saved ${playlists.length} playlists');
  }

  /// Add a track to a playlist
  Future<void> addTrack(String playlistId, String trackKey) async {
    // 1. Get the internal track ID
    final trackResults = await query(
      'tracks',
      where: 'rating_key = ?', // Using rating_key which maps to trackKey in DB usually
      whereArgs: [trackKey],
      limit: 1,
    );

    if (trackResults.isEmpty) {
      debugPrint('DATABASE: Track $trackKey not found, cannot add to playlist');
      return;
    }
    final trackId = trackResults.first['id'];

    // 2. Get the current max position
    final positionResult = await rawQuery('''
      SELECT MAX(position) as max_pos FROM playlist_tracks WHERE playlist_id = ?
    ''', [playlistId]);
    final maxPos = (positionResult.first['max_pos'] as int?) ?? -1;

    // 3. Insert
    await insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
        'position': maxPos + 1,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    
    // 4. Update playlist count
    await rawQuery('''
      UPDATE playlists 
      SET leaf_count = (SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?)
      WHERE id = ?
    ''', [playlistId, playlistId]);
  }

  /// Remove a track from a playlist
  Future<void> removeTrack(String playlistId, String trackKey) async {
    // 1. Get the internal track ID
    final trackResults = await query(
      'tracks',
      where: 'rating_key = ?',
      whereArgs: [trackKey],
      limit: 1,
    );

    if (trackResults.isEmpty) return;
    final trackId = trackResults.first['id'];

    // 2. Delete
    await delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );

    // 3. Update playlist count
    await rawQuery('''
      UPDATE playlists 
      SET leaf_count = (SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?)
      WHERE id = ?
    ''', [playlistId, playlistId]);
  }

  /// Save playlist tracks (bulk)
  Future<void> saveTracks(String playlistId, List<Track> tracks) async {
    // Delete existing associations
    await delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);

    // Insert new associations
    int position = 0;
    for (final track in tracks) {
      final trackResults = await query(
        'tracks',
        where: 'track_key = ?',
        whereArgs: [track.trackKey],
        limit: 1,
      );

      if (trackResults.isNotEmpty) {
        await insert('playlist_tracks', {
          'playlist_id': playlistId,
          'track_id': trackResults.first['id'],
          'position': position++,
        });
      }
    }

    debugPrint('DATABASE: Saved ${tracks.length} tracks for playlist $playlistId');
  }

  /// Delete a playlist
  Future<void> deleteById(String playlistId) async {
    await delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    debugPrint('DATABASE: Deleted playlist $playlistId');
  }

  /// Clear all playlists
  Future<void> clearAll() async {
    await delete('playlist_tracks');
    await delete('playlists');
    debugPrint('DATABASE: Cleared all playlists');
  }
}
