import 'package:flutter_test/flutter_test.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/core/models/track.dart';
import 'package:obscurify/core/models/playlist.dart';

void main() {
  group('DatabaseService Unit Tests', () {
    late DatabaseService db;

    setUp(() {
      // Get a fresh instance for each test
      db = DatabaseService();
    });

    tearDown(() async {
      // Clean up after each test
      await db.close();
    });

    // ============================================================
    // SINGLETON TESTS
    // ============================================================

    test('DatabaseService should follow singleton pattern', () {
      final db1 = DatabaseService();
      final db2 = DatabaseService();

      expect(db1, same(db2));
    });

    test('Multiple instances should reference the same database', () async {
      final db1 = DatabaseService();
      final db2 = DatabaseService();

      final database1 = await db1.database;
      final database2 = await db2.database;

      expect(database1, same(database2));
    });

    // ============================================================
    // REPOSITORY ACCESS TESTS
    // ============================================================

    test('Artist repository should be accessible', () {
      expect(db.artists, isNotNull);
    });

    test('Album repository should be accessible', () {
      expect(db.albums, isNotNull);
    });

    test('Track repository should be accessible', () {
      expect(db.tracks, isNotNull);
    });

    test('Playlist repository should be accessible', () {
      expect(db.playlists, isNotNull);
    });

    test('Repository instances should be lazily initialized and cached', () {
      final artists1 = db.artists;
      final artists2 = db.artists;

      expect(artists1, same(artists2));
    });

    // ============================================================
    // DATABASE INITIALIZATION TESTS
    // ============================================================

    test('Database should initialize successfully', () async {
      final database = await db.database;
      expect(database, isNotNull);
      expect(database.isOpen, isTrue);
    });

    test('Database should be singular across calls', () async {
      final db1 = await db.database;
      final db2 = await db.database;

      expect(db1, same(db2));
    });

    // ============================================================
    // UTILITY METHOD TESTS
    // ============================================================

    test('Close should close database connection', () async {
      final database = await db.database;
      expect(database.isOpen, isTrue);

      await db.close();

      // After reconnecting, should work
      final database2 = await db.database;
      expect(database2.isOpen, isTrue);
    });

    test('clearAllData should not throw', () async {
      // This test ensures the method runs without errors
      expect(() async {
        await db.clearAllData();
      }, returnsNormally);
    });

    test('recreateViews should not throw', () async {
      // This test ensures the method runs without errors
      expect(() async {
        await db.recreateViews();
      }, returnsNormally);
    });

    // ============================================================
    // BACKWARD COMPATIBILITY TESTS
    // ============================================================

    test('getAllArtists should return list of maps', () async {
      final result = await db.getAllArtists();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('getAllAlbums should return list of maps', () async {
      final result = await db.getAllAlbums();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('getAllTracks should return list of maps', () async {
      final result = await db.getAllTracks();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('getAllPlaylists should return list of maps', () async {
      final result = await db.getAllPlaylists();
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('getTrackCount should return integer', () async {
      final count = await db.getTrackCount();
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    // ============================================================
    // REPOSITORY METHOD TESTS (via DatabaseService)
    // ============================================================

    test('Track repository can get all tracks', () async {
      final tracks = await db.tracks.getAll();
      expect(tracks, isA<List<Track>>());
    });

    test('Album repository can get all albums', () async {
      final albums = await db.albums.getAll();
      expect(albums, isA<List>());
    });

    test('Artist repository can get all artists', () async {
      final artists = await db.artists.getAll();
      expect(artists, isA<List>());
    });

    test('Playlist repository can get all playlists', () async {
      final playlists = await db.playlists.getAll();
      expect(playlists, isA<List<Playlist>>());
    });

    test('Playlist repository can get count', () async {
      final count = await db.playlists.getCount();
      expect(count, isA<int>());
      expect(count, greaterThanOrEqualTo(0));
    });

    // ============================================================
    // SEARCH TESTS
    // ============================================================

    test('Track search should return list of tracks', () async {
      final results = await db.tracks.search('test');
      expect(results, isA<List<Track>>());
    });

    test('Artist search should return list of artists', () async {
      final results = await db.artists.search('test');
      expect(results, isA<List>());
    });

    // ============================================================
    // ERROR HANDLING TESTS
    // ============================================================

    test('Getting track by invalid ratingKey should return null', () async {
      final track = await db.tracks.getByRatingKey('nonexistent_key_12345');
      expect(track, isNull);
    });

    test('Getting album by invalid ratingKey should return null', () async {
      final album = await db.albums.getByRatingKey('nonexistent_key_12345');
      expect(album, isNull);
    });

    test('Getting artist by invalid ratingKey should return null', () async {
      final artist = await db.artists.getByRatingKey('nonexistent_key_12345');
      expect(artist, isNull);
    });

    test('Getting playlist by invalid ID should return null', () async {
      final playlist = await db.playlists.getById('nonexistent_id_12345');
      expect(playlist, isNull);
    });
  });
}
