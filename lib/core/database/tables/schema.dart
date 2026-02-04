part of '../database_service.dart';

Future<void> _onCreate(Database db, int version) async {
  // Create artists table with full metadata
  await db.execute('''
    CREATE TABLE artists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rating_key TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      thumb TEXT,
      art TEXT,
      summary TEXT,
      genre TEXT,
      country TEXT,
      server_id TEXT NOT NULL,
      added_at INTEGER,
      updated_at INTEGER
    )
  ''');

  // Create albums table with full metadata
  await db.execute('''
    CREATE TABLE albums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rating_key TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      artist_id INTEGER,
      artist_name TEXT,
      thumb TEXT,
      art TEXT,
      year INTEGER,
      genre TEXT,
      studio TEXT,
      summary TEXT,
      track_count INTEGER DEFAULT 0,
      server_id TEXT NOT NULL,
      added_at INTEGER,
      updated_at INTEGER,
      FOREIGN KEY (artist_id) REFERENCES artists(id)
    )
  ''');

  // Create tracks table with track/disc numbers
  await db.execute('''
    CREATE TABLE tracks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id TEXT NOT NULL,
      library_key TEXT NOT NULL,
      track_key TEXT NOT NULL,
      rating_key TEXT,
      title TEXT NOT NULL,
      artist_id INTEGER,
      artist_name TEXT,
      album_id INTEGER,
      album_name TEXT,
      track_number INTEGER,
      disc_number INTEGER DEFAULT 1,
      duration INTEGER,
      thumb TEXT,
      year INTEGER,
      genre TEXT,
      added_at INTEGER,
      media_data TEXT,
      user_rating REAL,
      UNIQUE(server_id, track_key),
      FOREIGN KEY (artist_id) REFERENCES artists(id),
      FOREIGN KEY (album_id) REFERENCES albums(id)
    )
  ''');

  // Create index for faster queries
  await db.execute('CREATE INDEX idx_server_library ON tracks(server_id, library_key)');
  await db.execute('CREATE INDEX idx_artist_id ON tracks(artist_id)');
  await db.execute('CREATE INDEX idx_album_id ON tracks(album_id)');
  await db.execute('CREATE INDEX idx_track_album ON tracks(album_id, track_number)');
  await db.execute('CREATE INDEX idx_albums_artist ON albums(artist_id)');
  await db.execute('CREATE INDEX idx_artists_title ON artists(title)');

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
      leaf_count INTEGER,
      server_id TEXT NOT NULL
    )
  ''');

  // Create playlist_tracks junction table for many-to-many relationship
  await db.execute('''
    CREATE TABLE playlist_tracks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playlist_id TEXT NOT NULL,
      track_id INTEGER NOT NULL,
      position INTEGER,
      UNIQUE(playlist_id, track_id),
      FOREIGN KEY (playlist_id) REFERENCES playlists(id),
      FOREIGN KEY (track_id) REFERENCES tracks(id)
    )
  ''');
  
  // Create index for faster lookups
  await db.execute('CREATE INDEX idx_playlist_id ON playlist_tracks(playlist_id)');
  await db.execute('CREATE INDEX idx_track_id ON playlist_tracks(track_id)');

  print('DATABASE: Tables created successfully with version $version');
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

  if (oldVersion < 5) {
    // Add parent_rating_key for album navigation
    await db.execute('ALTER TABLE tracks ADD COLUMN parent_rating_key TEXT');
    print('DATABASE: Migrated to version 5 - added parent_rating_key for albums');
  }

  if (oldVersion < 6) {
    // Migrate to normalized schema with separate artists and albums tables
    print('DATABASE: Migrating to version 6 - normalizing schema with artists and albums tables');
    
    // Create artists table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS artists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rating_key TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        thumb TEXT,
        art TEXT,
        server_id TEXT NOT NULL
      )
    ''');

    // Create albums table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rating_key TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist_id INTEGER,
        thumb TEXT,
        year INTEGER,
        server_id TEXT NOT NULL,
        FOREIGN KEY (artist_id) REFERENCES artists(id)
      )
    ''');

    // Add foreign key columns to tracks
    await db.execute('ALTER TABLE tracks ADD COLUMN artist_id INTEGER');
    await db.execute('ALTER TABLE tracks ADD COLUMN album_id INTEGER');

    // Create playlist_tracks junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id TEXT NOT NULL,
        track_id INTEGER NOT NULL,
        position INTEGER,
        UNIQUE(playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id),
        FOREIGN KEY (track_id) REFERENCES tracks(id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_artist_id ON tracks(artist_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_album_id ON tracks(album_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_id ON playlist_tracks(playlist_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_pt_track_id ON playlist_tracks(track_id)');

    // Add server_id to playlists if it doesn't exist
    try {
      await db.execute('ALTER TABLE playlists ADD COLUMN server_id TEXT');
    } catch (e) {
      // Column might already exist
    }

    print('DATABASE: Migrated to version 6 - schema normalized successfully');
  }

  if (oldVersion < 7) {
    // Add enhanced metadata fields to artists
    print('DATABASE: Migrating to version 7 - adding enhanced metadata fields');
    
    try { await db.execute('ALTER TABLE artists ADD COLUMN summary TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE artists ADD COLUMN genre TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE artists ADD COLUMN country TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE artists ADD COLUMN added_at INTEGER'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE artists ADD COLUMN updated_at INTEGER'); } catch (e) { /* ignore */ }

    // Add enhanced metadata fields to albums
    try { await db.execute('ALTER TABLE albums ADD COLUMN artist_name TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN art TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN genre TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN studio TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN summary TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN track_count INTEGER DEFAULT 0'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN added_at INTEGER'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE albums ADD COLUMN updated_at INTEGER'); } catch (e) { /* ignore */ }

    // Add track/disc number and enhanced fields to tracks
    try { await db.execute('ALTER TABLE tracks ADD COLUMN track_number INTEGER'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE tracks ADD COLUMN disc_number INTEGER DEFAULT 1'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE tracks ADD COLUMN artist_name TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE tracks ADD COLUMN album_name TEXT'); } catch (e) { /* ignore */ }
    try { await db.execute('ALTER TABLE tracks ADD COLUMN genre TEXT'); } catch (e) { /* ignore */ }

    // Create new indexes
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_track_album ON tracks(album_id, track_number)'); } catch (e) { /* ignore */ }
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_albums_artist ON albums(artist_id)'); } catch (e) { /* ignore */ }
    try { await db.execute('CREATE INDEX IF NOT EXISTS idx_artists_title ON artists(title)'); } catch (e) { /* ignore */ }

    print('DATABASE: Migrated to version 7 - enhanced metadata fields added');
  }
}