part of '../database_service.dart';

Future<void> _onCreate(Database db, int version) async {
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
      user_rating REAL,
      rating_key TEXT,
      grandparent_rating_key TEXT,
      grandparent_title TEXT,
      grandparent_thumb TEXT,
      grandparent_art TEXT,
      parent_title TEXT,
      parent_thumb TEXT,
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

  // Create playlists table
  await db.execute('''
    CREATE TABLE playlists(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      summary TEXT,
      type TEXT,
      smart INTEGER,
      composite TEXT,
      duration INTEGER,
      leaf_count INTEGER
    )
  ''');

  print('DATABASE: Tables created successfully');
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      CREATE TABLE playlists(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT,
        type TEXT,
        smart INTEGER,
        composite TEXT,
        duration INTEGER,
        leaf_count INTEGER
      )
    ''');
  }

  if (oldVersion < 3) {
    await db.execute('ALTER TABLE tracks ADD COLUMN user_rating REAL');
  }

  if (oldVersion < 4) {
    // Add artist-related columns for navigation
    await db.execute('ALTER TABLE tracks ADD COLUMN rating_key TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN grandparent_rating_key TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN grandparent_title TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN grandparent_thumb TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN grandparent_art TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN parent_title TEXT');
    await db.execute('ALTER TABLE tracks ADD COLUMN parent_thumb TEXT');
    print('DATABASE: Migrated to version 4 - added artist/album columns');
  }
}