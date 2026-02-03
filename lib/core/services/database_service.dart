import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'apollo_music.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create tracks table
        await db.execute('''
          CREATE TABLE tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id TEXT NOT NULL,
            library_key TEXT NOT NULL,
            track_key TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            duration INTEGER,
            thumb TEXT,
            year INTEGER,
            added_at INTEGER,
            media_data TEXT,
            UNIQUE(server_id, track_key)
          )
        ''');

        // Create index for faster queries
        await db.execute('''
          CREATE INDEX idx_server_library ON tracks(server_id, library_key)
        ''');

        // Create sync metadata table
        await db.execute('''
          CREATE TABLE sync_metadata (
            server_id TEXT PRIMARY KEY,
            library_key TEXT NOT NULL,
            last_sync INTEGER NOT NULL,
            track_count INTEGER NOT NULL
          )
        ''');

        print('DATABASE: Tables created successfully');
      },
    );
  }

  // Save tracks to database
  Future<void> saveTracks(
    String serverId,
    String libraryKey,
    List<Map<String, dynamic>> tracks,
  ) async {
    final db = await database;
    final batch = db.batch();

    // Delete existing tracks for this server/library
    batch.delete(
      'tracks',
      where: 'server_id = ? AND library_key = ?',
      whereArgs: [serverId, libraryKey],
    );

    // Insert new tracks
    for (var track in tracks) {
      batch.insert(
        'tracks',
        {
          'server_id': serverId,
          'library_key': libraryKey,
          'track_key': track['key'] ?? '',
          'title': track['title'] ?? 'Unknown',
          'artist': track['artist'] ?? 'Unknown Artist',
          'album': track['album'] ?? 'Unknown Album',
          'duration': track['duration'] ?? 0,
          'thumb': track['thumb'] ?? '',
          'year': track['year'] ?? 0,
          'added_at': track['addedAt'],
          'media_data': jsonEncode(track['Media'] ?? []),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

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

    print('DATABASE: Saved ${tracks.length} tracks for server $serverId, library $libraryKey');
  }

  // Get all tracks from database
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tracks');

    return maps.map((map) => {
      'title': map['title'] as String,
      'artist': map['artist'] as String?,
      'album': map['album'] as String?,
      'duration': map['duration'] as int,
      'key': map['track_key'] as String,
      'thumb': map['thumb'] as String?,
      'year': map['year'] as int?,
      'addedAt': map['added_at'] as int?,
      'serverId': map['server_id'] as String,
      'libraryKey': map['library_key'] as String,
      'Media': _parseMediaData(map['media_data'] as String),
    }).toList();
  }

  // Get tracks for specific server/library
  Future<List<Map<String, dynamic>>> getTracksForLibrary(
    String serverId,
    String libraryKey,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tracks',
      where: 'server_id = ? AND library_key = ?',
      whereArgs: [serverId, libraryKey],
    );

    return maps.map((map) => {
      'title': map['title'] as String,
      'artist': map['artist'] as String?,
      'album': map['album'] as String?,
      'duration': map['duration'] as int,
      'key': map['track_key'] as String,
      'thumb': map['thumb'] as String?,
      'year': map['year'] as int?,
      'addedAt': map['added_at'] as int?,
      'serverId': map['server_id'] as String,
      'libraryKey': map['library_key'] as String,
      'Media': _parseMediaData(map['media_data'] as String),
    }).toList();
  }

  // Get sync metadata
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

  // Check if we have cached data
  Future<bool> hasCachedTracks() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tracks');
    final count = result.first['count'] as int;
    return count > 0;
  }

  // Clear all tracks
  Future<void> clearAllTracks() async {
    final db = await database;
    await db.delete('tracks');
    await db.delete('sync_metadata');
    print('DATABASE: Cleared all tracks');
  }

  // Clear tracks for specific server
  Future<void> clearServerTracks(String serverId) async {
    final db = await database;
    await db.delete('tracks', where: 'server_id = ?', whereArgs: [serverId]);
    await db.delete('sync_metadata', where: 'server_id = ?', whereArgs: [serverId]);
    print('DATABASE: Cleared tracks for server $serverId');
  }

  // Parse media data string back to list
  List<dynamic> _parseMediaData(String mediaData) {
    try {
      if (mediaData.isEmpty) return [];
      final decoded = jsonDecode(mediaData);
      return decoded is List ? decoded : [];
    } catch (e) {
      debugPrint('DATABASE: Error parsing media data: $e');
      return [];
    }
  }

  // Get track count
  Future<int> getTrackCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tracks');
    return result.first['count'] as int;
  }

  // Get all sync info
  Future<List<Map<String, dynamic>>> getAllSyncMetadata() async {
    final db = await database;
    return await db.query('sync_metadata');
  }

  // Search tracks by title, artist, or album
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];
    
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tracks',
      where: 'LOWER(title) LIKE ? OR LOWER(artist) LIKE ? OR LOWER(album) LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      limit: 20, // Limit results to top 20 matches
      orderBy: 'title ASC',
    );

    return maps.map((map) => {
      'title': map['title'] as String,
      'artist': map['artist'] as String?,
      'album': map['album'] as String?,
      'duration': map['duration'] as int,
      'key': map['track_key'] as String,
      'thumb': map['thumb'] as String?,
      'year': map['year'] as int?,
      'addedAt': map['added_at'] as int?,
      'serverId': map['server_id'] as String,
      'libraryKey': map['library_key'] as String,
      'Media': _parseMediaData(map['media_data'] as String),
    }).toList();
  }
}
