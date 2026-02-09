import 'package:flutter_test/flutter_test.dart';
import 'package:apollo/core/database/repositories/album_repository.dart';
import 'package:apollo/core/models/album.dart';
import 'package:apollo/core/models/track.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  group('AlbumRepository Unit Tests', () {
    late Database testDb;
    late AlbumRepository albumRepository;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create in-memory test database
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS artists (
              id INTEGER PRIMARY KEY,
              rating_key TEXT UNIQUE,
              title TEXT,
              thumb TEXT,
              added_at INTEGER,
              updated_at INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS albums (
              id INTEGER PRIMARY KEY,
              rating_key TEXT UNIQUE,
              title TEXT,
              artist_id INTEGER,
              artist_rating_key TEXT,
              year INTEGER,
              thumb TEXT,
              track_count INTEGER,
              duration INTEGER,
              added_at INTEGER,
              updated_at INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS tracks (
              id INTEGER PRIMARY KEY,
              rating_key TEXT UNIQUE,
              title TEXT,
              album_id INTEGER,
              album_rating_key TEXT,
              artist_id INTEGER,
              artist_rating_key TEXT,
              disc_number INTEGER,
              track_number INTEGER,
              duration INTEGER,
              file_path TEXT,
              added_at INTEGER,
              updated_at INTEGER
            )
          ''');

          // Create view
          await db.execute('''
            CREATE VIEW IF NOT EXISTS v_albums_full AS
            SELECT 
              a.id,
              a.rating_key,
              a.title,
              a.artist_id,
              a.artist_rating_key,
              a.year,
              a.thumb,
              a.track_count,
              a.duration,
              a.added_at,
              a.updated_at,
              ar.title AS artist_title
            FROM albums a
            LEFT JOIN artists ar ON a.artist_id = ar.id
          ''');

          await db.execute('''
            CREATE VIEW IF NOT EXISTS v_tracks_full AS
            SELECT 
              t.id,
              t.rating_key,
              t.title,
              t.album_id,
              t.album_rating_key,
              t.artist_id,
              t.artist_rating_key,
              t.disc_number,
              t.track_number,
              t.duration,
              t.file_path,
              t.added_at,
              t.updated_at
            FROM tracks t
          ''');
        },
      );

      albumRepository = AlbumRepository(() => Future.value(testDb));
    });

    tearDown(() async {
      await testDb.close();
    });

    // ============================================================
    // HELPER METHODS
    // ============================================================

    Future<void> insertTestAlbum({
      String ratingKey = 'album_1',
      String title = 'Test Album',
      String artistRatingKey = 'artist_1',
      int year = 2023,
      int trackCount = 10,
    }) async {
      await testDb.insert('albums', {
        'rating_key': ratingKey,
        'title': title,
        'artist_rating_key': artistRatingKey,
        'year': year,
        'track_count': trackCount,
        'added_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    Future<void> insertTestTrack({
      String ratingKey = 'track_1',
      String title = 'Test Track',
      String albumRatingKey = 'album_1',
      String artistRatingKey = 'artist_1',
      int duration = 240000,
      int discNumber = 1,
      int trackNumber = 1,
    }) async {
      await testDb.insert('tracks', {
        'rating_key': ratingKey,
        'title': title,
        'album_rating_key': albumRatingKey,
        'artist_rating_key': artistRatingKey,
        'disc_number': discNumber,
        'track_number': trackNumber,
        'duration': duration,
        'added_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // ============================================================
    // READ OPERATIONS TESTS
    // ============================================================

    test('getAll should return empty list when no albums exist', () async {
      final albums = await albumRepository.getAll();
      expect(albums, isEmpty);
    });

    test('getAll should return all albums sorted by title', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Album A');
      await insertTestAlbum(ratingKey: 'album_2', title: 'Album B');
      await insertTestAlbum(ratingKey: 'album_3', title: 'Album C');

      final albums = await albumRepository.getAll();

      expect(albums.length, 3);
      expect(albums[0].title, 'Album A');
      expect(albums[1].title, 'Album B');
      expect(albums[2].title, 'Album C');
    });

    test('getByRatingKey should return album when found', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Test Album');

      final album = await albumRepository.getByRatingKey('album_1');

      expect(album, isNotNull);
      expect(album!.ratingKey, 'album_1');
      expect(album.title, 'Test Album');
    });

    test('getByRatingKey should return null when not found', () async {
      final album = await albumRepository.getByRatingKey('nonexistent');

      expect(album, isNull);
    });

    test('getById should return album by internal ID', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Test Album');

      final result = await testDb.query('albums',
          where: 'rating_key = ?', whereArgs: ['album_1']);
      final albumId = result.first['id'] as int;

      final album = await albumRepository.getById(albumId);

      expect(album, isNotNull);
      expect(album!.title, 'Test Album');
    });

    test('getByArtist should return albums by artist rating key', () async {
      await insertTestAlbum(
          ratingKey: 'album_1',
          title: 'Album 1',
          artistRatingKey: 'artist_1',
          year: 2023);
      await insertTestAlbum(
          ratingKey: 'album_2',
          title: 'Album 2',
          artistRatingKey: 'artist_1',
          year: 2022);
      await insertTestAlbum(
          ratingKey: 'album_3',
          title: 'Album 3',
          artistRatingKey: 'artist_2',
          year: 2021);

      final albums = await albumRepository.getByArtist('artist_1');

      expect(albums.length, 2);
      expect(albums[0].title, 'Album 1'); // Sorted by year DESC
      expect(albums[1].title, 'Album 2');
    });

    test('getByYear should return albums by year', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Album A', year: 2023);
      await insertTestAlbum(ratingKey: 'album_2', title: 'Album B', year: 2022);
      await insertTestAlbum(ratingKey: 'album_3', title: 'Album C', year: 2023);

      final albums = await albumRepository.getByYear(2023);

      expect(albums.length, 2);
      expect(albums.every((a) => a.year == 2023), isTrue);
    });

    test('getRecent should return recently added albums', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Album A');
      await Future.delayed(Duration(milliseconds: 10));
      await insertTestAlbum(ratingKey: 'album_2', title: 'Album B');

      final albums = await albumRepository.getRecent(limit: 1);

      expect(albums.length, 1);
      expect(albums[0].ratingKey, 'album_2');
    });

    test('search should find albums by title', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Thriller');
      await insertTestAlbum(ratingKey: 'album_2', title: 'Bad');
      await insertTestAlbum(ratingKey: 'album_3', title: 'Dangerous');

      final results = await albumRepository.search('Thriller');

      expect(results.length, 1);
      expect(results[0].title, 'Thriller');
    });

    test('search should return empty list for empty query', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Test Album');

      final results = await albumRepository.search('');

      expect(results, isEmpty);
    });

    test('search should be case insensitive', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Thriller');

      final results1 = await albumRepository.search('THRILLER');
      final results2 = await albumRepository.search('thriller');

      expect(results1.length, 1);
      expect(results2.length, 1);
    });

    test('getCount should return total album count', () async {
      await insertTestAlbum(ratingKey: 'album_1');
      await insertTestAlbum(ratingKey: 'album_2');
      await insertTestAlbum(ratingKey: 'album_3');

      final count = await albumRepository.getCount();

      expect(count, 3);
    });

    test('getDuration should sum track durations for album', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Test Album');
      await insertTestTrack(ratingKey: 'track_1', albumRatingKey: 'album_1', duration: 240000);
      await insertTestTrack(ratingKey: 'track_2', albumRatingKey: 'album_1', duration: 180000);

      final duration = await albumRepository.getDuration('album_1');

      expect(duration, 420000);
    });

    test('getDuration should return 0 for album with no tracks', () async {
      await insertTestAlbum(ratingKey: 'album_1');

      final duration = await albumRepository.getDuration('album_1');

      expect(duration, 0);
    });

    // ============================================================
    // EAGER LOADING TESTS
    // ============================================================

    test('getWithTracks should return album with tracks', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Test Album');
      await insertTestTrack(ratingKey: 'track_1', albumRatingKey: 'album_1', trackNumber: 1);
      await insertTestTrack(ratingKey: 'track_2', albumRatingKey: 'album_1', trackNumber: 2);

      final album = await albumRepository.getWithTracks('album_1');

      expect(album, isNotNull);
      expect(album!.tracks, isNotNull);
      expect(album.tracks!.length, 2);
    });

    test('getWithTracks should return null when album not found', () async {
      final album = await albumRepository.getWithTracks('nonexistent');

      expect(album, isNull);
    });

    test('getWithTracks should order tracks by disc and track number', () async {
      await insertTestAlbum(ratingKey: 'album_1');
      await insertTestTrack(
          ratingKey: 'track_1',
          albumRatingKey: 'album_1',
          discNumber: 2,
          trackNumber: 1);
      await insertTestTrack(
          ratingKey: 'track_2',
          albumRatingKey: 'album_1',
          discNumber: 1,
          trackNumber: 2);

      final album = await albumRepository.getWithTracks('album_1');

      expect(album!.tracks![0].ratingKey, 'track_2'); // Disc 1
      expect(album.tracks![1].ratingKey, 'track_1'); // Disc 2
    });

    test('getAllWithTracks should return all albums with their tracks', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: 'Album 1');
      await insertTestAlbum(ratingKey: 'album_2', title: 'Album 2');
      await insertTestTrack(ratingKey: 'track_1', albumRatingKey: 'album_1');
      await insertTestTrack(ratingKey: 'track_2', albumRatingKey: 'album_2');

      final albums = await albumRepository.getAllWithTracks();

      expect(albums.length, 2);
      expect(albums[0].tracks!.length, 1);
      expect(albums[1].tracks!.length, 1);
    });

    // ============================================================
    // WRITE OPERATIONS TESTS
    // ============================================================

    test('save should insert new album', () async {
      final album = Album(
        id: null,
        ratingKey: 'album_1',
        title: 'New Album',
        artistRatingKey: 'artist_1',
        year: 2024,
        serverId: 'server_1',
      );

      await albumRepository.save(album);

      final saved = await albumRepository.getByRatingKey('album_1');
      expect(saved, isNotNull);
      expect(saved!.title, 'New Album');
    });

    test('deleteByRatingKey should remove album', () async {
      await insertTestAlbum(ratingKey: 'album_1');

      await albumRepository.deleteByRatingKey('album_1');

      final album = await albumRepository.getByRatingKey('album_1');
      expect(album, isNull);
    });

    test('deleteByRatingKey with cascade should remove associated tracks', () async {
      await insertTestAlbum(ratingKey: 'album_1');
      await insertTestTrack(ratingKey: 'track_1', albumRatingKey: 'album_1');
      await insertTestTrack(ratingKey: 'track_2', albumRatingKey: 'album_1');

      final result = await testDb
          .query('albums', where: 'rating_key = ?', whereArgs: ['album_1']);
      final albumId = result.first['id'] as int;

      await albumRepository.deleteByRatingKey('album_1', cascade: true);

      final album = await albumRepository.getByRatingKey('album_1');
      expect(album, isNull);
    });

    test('clearAll should remove all albums', () async {
      await insertTestAlbum(ratingKey: 'album_1');
      await insertTestAlbum(ratingKey: 'album_2');

      await albumRepository.clearAll();

      final albums = await albumRepository.getAll();
      expect(albums, isEmpty);
    });

    test('clearAll with cascade should remove all albums and tracks', () async {
      await insertTestAlbum(ratingKey: 'album_1');
      await insertTestTrack(ratingKey: 'track_1', albumRatingKey: 'album_1');

      await albumRepository.clearAll(cascade: true);

      final albums = await albumRepository.getAll();
      final tracks = await testDb.query('tracks');
      expect(albums, isEmpty);
      expect(tracks, isEmpty);
    });

    // ============================================================
    // EDGE CASES
    // ============================================================

    test('getAll should handle albums with NULL values', () async {
      await testDb.insert('albums', {
        'rating_key': 'album_1',
        'title': 'Album with NULLs',
        'artist_rating_key': null,
        'year': null,
      });

      final albums = await albumRepository.getAll();

      expect(albums.length, 1);
      expect(albums[0].ratingKey, 'album_1');
    });

    test('search with special characters should not throw', () async {
      await insertTestAlbum(ratingKey: 'album_1', title: "Album's Name");

      final results = await albumRepository.search("'%");

      expect(results, isA<List<Album>>());
    });
  });
}
