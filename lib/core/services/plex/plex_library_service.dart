import 'package:flutter/foundation.dart';
import 'plex_api_client.dart';

/// Represents a Plex library (music, movies, etc.).
class PlexLibrary {
  final String key;
  final String title;
  final String type;

  PlexLibrary({
    required this.key,
    required this.title,
    required this.type,
  });

  factory PlexLibrary.fromJson(Map<String, dynamic> json) {
    return PlexLibrary(
      key: json['key'].toString(),
      title: json['title'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'type': type,
    };
  }

  bool get isMusicLibrary => type == 'artist';
}

/// Manages Plex library operations.
/// Single responsibility: Library discovery and content retrieval.
class PlexLibraryService {
  final PlexApiClient _apiClient = PlexApiClient();

  /// Fetches all libraries from a server.
  Future<List<PlexLibrary>> getLibraries(String token, String serverUrl) async {
    try {
      final url = '$serverUrl/library/sections?X-Plex-Token=$token';
      debugPrint('Fetching libraries from: $serverUrl/library/sections');
      debugPrint('Token (first 10 chars): ${token.substring(0, 10)}...');
      debugPrint('Full URL (token redacted): $serverUrl/library/sections?X-Plex-Token=***');
      
      final response = await _apiClient.get(
        url,
        token: token,
      );

      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = _apiClient.decodeJson(response);

        if (data['MediaContainer'] != null) {
          final directories =
              data['MediaContainer']['Directory'] as List<dynamic>?;

          if (directories != null) {
            return directories.map((dir) => PlexLibrary.fromJson(dir)).toList();
          }
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('Error fetching libraries: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetches only music libraries from a server.
  Future<List<PlexLibrary>> getMusicLibraries(
      String token, String serverUrl) async {
    final libraries = await getLibraries(token, serverUrl);
    return libraries.where((lib) => lib.isMusicLibrary).toList();
  }

  /// Fetches all tracks from a library.
  Future<List<Map<String, dynamic>>> getTracks(
    String token,
    String serverUrl,
    String libraryKey,
  ) async {
    try {
      debugPrint('--- LIBRARY SERVICE: getTracks called ---');
      debugPrint('Server URL: $serverUrl');
      debugPrint('Library Key: $libraryKey');

      // Request with includeDetails to get full metadata including artist/album info
      // Include all necessary fields for complete track data (especially album artwork)
      final url = '$serverUrl/library/sections/$libraryKey/all?type=10&includeExternalMedia=1&includeFields=thumb,parentThumb,grandparentThumb,grandparentArt,parentArt&X-Plex-Token=$token';

      final response = await _apiClient.getWithTimeout(
        url,
        token: token,
        timeout: const Duration(seconds: 30),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _apiClient.decodeJson(response);

        if (data['MediaContainer'] != null) {
          final metadata = data['MediaContainer']['Metadata'];

          if (metadata == null) {
            debugPrint('WARNING - Metadata is null!');
            return [];
          }

          final tracks = metadata as List<dynamic>;
          debugPrint('Found ${tracks.length} tracks');

          return _mapTracks(tracks);
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('EXCEPTION in getTracks: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Maps raw track data to a standardized format.
  List<Map<String, dynamic>> _mapTracks(List<dynamic> tracks) {
    return tracks
        .map((track) {
          final grandparentRatingKey = track['grandparentRatingKey'];
          final grandparentTitle = track['grandparentTitle'];
          final parentRatingKey = track['parentRatingKey'];
          
          if (grandparentRatingKey == null) {
            debugPrint('WARNING: Track has no grandparentRatingKey - ${track['title']}');
          }
          if (parentRatingKey == null) {
            debugPrint('WARNING: Track has no parentRatingKey - ${track['title']}');
          }
          
          return {
            'title': track['title'] as String? ?? 'Unknown',
            'artist': track['originalTitle'] as String? ??
                track['grandparentTitle'] as String? ??
                'Unknown Artist',
            'album': track['parentTitle'] as String? ?? 'Unknown Album',
            'duration': track['duration'] as int? ?? 0,
            'key': track['key'] as String? ?? '',
            'thumb': track['thumb'] as String? ?? '',
            'year': track['year'] as int? ?? 0,
            'addedAt': track['addedAt'] as int?,
            'Media': track['Media'] as List<dynamic>? ?? [],
            'grandparentRatingKey': grandparentRatingKey,
            'grandparentTitle': grandparentTitle,
            'grandparentThumb': track['grandparentThumb'],
            'grandparentArt': track['grandparentArt'],
            'parentRatingKey': parentRatingKey,
            'parentTitle': track['parentTitle'],
            'parentThumb': track['parentThumb'],
            'ratingKey': track['ratingKey'],
            'userRating': track['userRating'],
          };
        })
        .toList();
  }

  /// Fetches all albums from a library.
  Future<List<Map<String, dynamic>>> getAlbums(
    String token,
    String serverUrl,
    String libraryKey,
  ) async {
    try {
      debugPrint('--- LIBRARY SERVICE: getAlbums called ---');
      debugPrint('Server URL: $serverUrl');
      debugPrint('Library Key: $libraryKey');

      // Fetch albums (type=9) with all metadata fields
      final url = '$serverUrl/library/sections/$libraryKey/all?type=9&includeExternalMedia=1&X-Plex-Token=$token';

      final response = await _apiClient.getWithTimeout(
        url,
        token: token,
        timeout: const Duration(seconds: 30),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _apiClient.decodeJson(response);

        if (data['MediaContainer'] != null) {
          final metadata = data['MediaContainer']['Metadata'];

          if (metadata == null) {
            debugPrint('WARNING - Metadata is null!');
            return [];
          }

          final albums = metadata as List<dynamic>;
          debugPrint('Found ${albums.length} albums');

          return _mapAlbums(albums);
        }
      }
      return [];
    } catch (e, stackTrace) {
      debugPrint('EXCEPTION in getAlbums: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Maps raw album data to a standardized format.
  List<Map<String, dynamic>> _mapAlbums(List<dynamic> albums) {
    return albums.map((album) {
      final originallyAvailableAt = album['originallyAvailableAt'] as String?;
      final year = album['year'] as int?;
      
      if (originallyAvailableAt != null) {
        debugPrint('ALBUM_FETCH_DEBUG: Album "${album['title']}" has originallyAvailableAt=$originallyAvailableAt, year=$year');
      }
      
      return {
        'ratingKey': album['ratingKey']?.toString() ?? '',
        'title': album['title'] as String? ?? 'Unknown Album',
        'parentTitle': album['parentTitle'] as String?,
        'parentRatingKey': album['parentRatingKey']?.toString(),
        'thumb': album['thumb'] as String?,
        'art': album['art'] as String?,
        'year': year,
        'originallyAvailableAt': originallyAvailableAt,
        'genre': album['Genre'] != null && (album['Genre'] as List).isNotEmpty
            ? album['Genre'][0]['tag']
            : null,
        'studio': album['studio'] as String?,
        'summary': album['summary'] as String?,
        'leafCount': album['leafCount'] as int? ?? 0,
        'addedAt': album['addedAt'] as int?,
      };
    }).toList();
  }
}
