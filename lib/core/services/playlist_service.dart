import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import '../database/database_service.dart';

/// Service for managing playlists.
/// Single responsibility: Playlist synchronization and local storage.
class PlaylistService {
  final DatabaseService _dbService = DatabaseService();

  /// Fetches playlists from Plex API and syncs them to the local database.
  Future<List<Playlist>> syncPlaylists(String serverUrl, String token, String serverId) async {
    try {
      final playlists = await _fetchPlaylistsFromApi(serverUrl, token);
      // Set serverId on playlists so downstream code can resolve the correct token
      final playlistsWithServer = playlists.map((p) => p.copyWith(serverId: serverId)).toList();
      await _dbService.playlists.saveAll(playlistsWithServer);
      return playlistsWithServer;
    } catch (e) {
      debugPrint('PLAYLIST SERVICE: Error syncing playlists: $e');
      return await getLocalPlaylists();
    }
  }

  /// Fetches playlists from Plex API without saving to database.
  /// Use this when you want to filter playlists before saving.
  Future<List<Playlist>> fetchPlaylists(String serverUrl, String token, {String serverId = ''}) async {
    try {
      final playlists = await _fetchPlaylistsFromApi(serverUrl, token);
      if (serverId.isNotEmpty) {
        return playlists.map((p) => p.copyWith(serverId: serverId)).toList();
      }
      return playlists;
    } catch (e) {
      debugPrint('PLAYLIST SERVICE: Error fetching playlists: $e');
      return [];
    }
  }

  /// Fetches tracks for a specific playlist from the Plex API.
  Future<List<Map<String, dynamic>>> getPlaylistTracks(
    String serverUrl,
    String token,
    String playlistId, {
    String? serverId,
  }) async {
    try {
      final uri = Uri.parse('$serverUrl/playlists/$playlistId/items').replace(
        queryParameters: {
          'X-Plex-Token': token,
        },
      );

      debugPrint('PLAYLIST SERVICE: Fetching tracks for playlist $playlistId');
      debugPrint('PLAYLIST SERVICE: URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Plex-Token': token,
        },
      );

      if (response.statusCode != 200) {
        debugPrint('PLAYLIST SERVICE: Error response ${response.statusCode}: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        throw Exception('Failed to fetch playlist tracks: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final container = data['MediaContainer'];
      final List<dynamic> metadata = container?['Metadata'] ?? [];

      debugPrint('PLAYLIST SERVICE: Found ${metadata.length} tracks in playlist');

      // Convert Plex track format to our standard track format
      // IMPORTANT: Preserve the full Media structure for audio playback
      return metadata.map((trackJson) {
        return {
          'id': trackJson['ratingKey']?.toString() ?? '',
          'title': trackJson['title'] ?? 'Unknown',
          'artist': trackJson['grandparentTitle'] ?? trackJson['originalTitle'] ?? 'Unknown Artist',
          'album': trackJson['parentTitle'] ?? 'Unknown Album',
          'duration': trackJson['duration'] ?? 0,
          'thumb': trackJson['thumb'],
          'parentThumb': trackJson['parentThumb'],
          'grandparentThumb': trackJson['grandparentThumb'],
          'grandparentRatingKey': trackJson['grandparentRatingKey'],
          'parentRatingKey': trackJson['parentRatingKey'],
          'ratingKey': trackJson['ratingKey'],
          'key': trackJson['key'],
          'addedAt': trackJson['addedAt'],
          'Media': trackJson['Media'], // Preserve full Media structure for audio player
          'serverId': serverId, // Set by caller for correct server resolution
        };
      }).toList();
    } catch (e) {
      debugPrint('PLAYLIST SERVICE: Error fetching playlist tracks: $e');
      rethrow;
    }
  }

  /// Fetches playlists from the Plex API.
  Future<List<Playlist>> _fetchPlaylistsFromApi(String serverUrl, String token) async {
    final uri = Uri.parse('$serverUrl/playlists').replace(queryParameters: {
      'X-Plex-Token': token,
      'playlistType': 'audio',
    });

    debugPrint('PLAYLIST SERVICE: Fetching playlists from $serverUrl');
    
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Plex-Token': token,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch playlists: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final container = data['MediaContainer'];
    final List<dynamic> metadata = container?['Metadata'] ?? [];

    debugPrint('PLAYLIST SERVICE: Found ${metadata.length} playlists');

    final playlists = metadata
        .map((json) => Playlist.fromPlexJson(json))
        .where((playlist) => playlist.title != 'All Music')
        .toList();

    debugPrint('PLAYLIST SERVICE: After filtering, ${playlists.length} playlists (excluded "All Music")');

    return playlists;
  }

  /// Retrieves playlists from the local database.
  Future<List<Playlist>> getLocalPlaylists() async {
    return _dbService.playlists.getAll();
  }

  /// Saves playlists to the local database.
  Future<void> savePlaylistsToDb(List<Playlist> playlists) async {
    await _dbService.playlists.saveAll(playlists);
  }
}
