import 'package:flutter/material.dart';
import 'package:apollo/core/services/plex/plex_services.dart';
import 'package:apollo/core/services/storage_service.dart';
import 'package:apollo/core/database/database_service.dart';
import 'package:apollo/core/models/track.dart';
import 'package:apollo/core/services/playlist_service.dart';
import 'package:apollo/core/services/library_change_notifier.dart';

/// Shared business logic for server settings on both mobile and desktop.
///
/// Both platform pages delegate all non-UI work to this service.
/// Callbacks are used to push progress updates back to the UI layer.
class ServerSettingsService {
  final PlexAuthService _authService = PlexAuthService();
  final PlexServerService _serverService = PlexServerService();
  final PlexLibraryService _libraryService = PlexLibraryService();
  final StorageService _storageService = StorageService();
  final DatabaseService _dbService = DatabaseService();
  final PlaylistService _playlistService = PlaylistService();

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  /// Validate that a stored token is still valid with the Plex API.
  Future<bool> validateToken(String token) async {
    return await _authService.validateToken(token);
  }

  /// Launch the Plex OAuth sign-in flow.
  /// Returns a map with 'success', 'token', 'username', and optionally 'error'.
  Future<Map<String, dynamic>> signIn() async {
    return await _authService.signIn();
  }

  /// Persist token and optional username after a successful sign-in.
  Future<void> saveCredentials(String token, String? username) async {
    await _storageService.savePlexToken(token);
    if (username != null) {
      await _storageService.saveUsername(username);
    }
  }

  /// Clear all stored credentials AND wipe the local database.
  Future<void> signOut() async {
    await _storageService.clearPlexCredentials();
    await _dbService.clearAllData();
    LibraryChangeNotifier().notifyLibraryChanged();
  }

  /// Read the stored Plex auth token.
  Future<String?> getPlexToken() async {
    return await _storageService.getPlexToken();
  }

  /// Read the stored username.
  Future<String?> getUsername() async {
    return await _storageService.getUsername();
  }

  /// Check auth status: returns username if valid, null otherwise.
  /// Clears credentials if the token is expired/invalid.
  Future<String?> checkAuthStatus() async {
    final token = await _storageService.getPlexToken();
    if (token == null) return null;

    final isValid = await _authService.validateToken(token);
    if (!isValid) {
      await _storageService.clearPlexCredentials();
      return null;
    }

    return await _storageService.getUsername();
  }

  // ============================================================
  // SERVERS & LIBRARIES
  // ============================================================

  /// Fetch servers from Plex API.
  Future<List<PlexServer>> getServers(String token) async {
    return await _serverService.getServers(token);
  }

  /// Fetch music libraries for a single server.
  Future<List<Map<String, dynamic>>> getLibrariesForServer(
    String token,
    PlexServer server,
  ) async {
    final serverUrl = _serverService.getBestConnectionUrlForServer(server);
    if (serverUrl == null) return [];

    try {
      final libraries = await _libraryService.getLibraries(token, serverUrl);
      final musicLibraries = libraries.where((l) => l.isMusicLibrary).toList();
      return musicLibraries.map((l) => l.toJson()).toList();
    } catch (e) {
      debugPrint('Error fetching libraries for ${server.name}: $e');
      return [];
    }
  }

  /// Load the previously saved library selections.
  Future<Map<String, List<String>>> getSelectedServers() async {
    return await _storageService.getSelectedServers();
  }

  /// Persist library selections and the server URL map.
  Future<void> saveSelections(
    Map<String, Set<String>> selectedLibraries,
    List<PlexServer> servers,
  ) async {
    final selections = selectedLibraries.map(
      (key, value) => MapEntry(key, value.toList()),
    );
    await _storageService.saveSelectedServers(selections);
    await saveServerUrlMap(servers);
  }

  /// Persist a mapping of serverId → best connection URL.
  Future<void> saveServerUrlMap(List<PlexServer> servers) async {
    final Map<String, String> urlMap = {};
    for (var server in servers) {
      final serverUrl = _serverService.getBestConnectionUrlForServer(server);
      if (serverUrl != null) {
        urlMap[server.machineIdentifier] = serverUrl;
      }
    }
    await _storageService.saveServerUrlMap(urlMap);
    debugPrint('Saved ${urlMap.length} server URLs to storage');
  }

  // ============================================================
  // SYNC STATUS
  // ============================================================

  /// Load the last sync status from the database.
  /// Returns null if never synced.
  Future<Map<String, dynamic>?> loadSyncStatus() async {
    try {
      final syncMetadata = await _dbService.tracks.getAllSyncMetadata();
      final trackCount = await _dbService.tracks.getCount();

      if (syncMetadata.isNotEmpty) {
        final lastSync = syncMetadata.first['last_sync'] as int;
        return {
          'trackCount': trackCount,
          'lastSync': DateTime.fromMillisecondsSinceEpoch(lastSync),
        };
      }
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
    return null;
  }

  /// Format a sync date into a human-readable relative string.
  String formatSyncDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // ============================================================
  // LIBRARY SYNC
  // ============================================================

  /// Sync tracks and playlists from all selected libraries.
  ///
  /// Progress is reported via callbacks so the calling UI can
  /// update its own state without the service knowing about widgets.
  ///
  /// Throws on fatal errors (no token, no libraries selected).
  Future<int> syncLibrary(
    List<PlexServer> servers,
    Map<String, List<Map<String, dynamic>>> serverLibraries, {
    required void Function(String status) onStatusChange,
    required void Function(double progress) onProgressChange,
    required void Function(int tracksSynced) onTracksSyncedChange,
  }) async {
    final token = await _storageService.getPlexToken();
    if (token == null) throw Exception('Not authenticated');

    final selectedServers = await _storageService.getSelectedServers();
    if (selectedServers.isEmpty) throw Exception('No libraries selected');

    // Count total libraries
    int totalLibraries = 0;
    for (var server in servers) {
      final libraryKeys = selectedServers[server.machineIdentifier];
      if (libraryKeys != null && libraryKeys.isNotEmpty) {
        totalLibraries += libraryKeys.length;
      }
    }

    int totalTracks = 0;
    int librariesCompleted = 0;

    for (var server in servers) {
      final libraryKeys = selectedServers[server.machineIdentifier];
      if (libraryKeys == null || libraryKeys.isEmpty) continue;

      final serverUrl = _serverService.getBestConnectionUrlForServer(server);
      if (serverUrl == null) continue;

      // --- Sync tracks ---
      for (var libraryKey in libraryKeys) {
        final libraryInfo = serverLibraries[server.machineIdentifier]
            ?.firstWhere(
              (lib) => lib['key'] == libraryKey,
              orElse: () => {'title': 'Library $libraryKey'},
            );
        final libraryTitle =
            libraryInfo?['title'] as String? ?? 'Library $libraryKey';

        onStatusChange('$libraryTitle (fetching...)');
        debugPrint(
            'Fetching library $libraryKey from ${server.machineIdentifier}...');

        final tracks =
            await _libraryService.getTracks(token, serverUrl, libraryKey);

        onStatusChange('$libraryTitle (saving...)');
        debugPrint('Saving ${tracks.length} tracks from library $libraryKey...');

        final trackObjects = tracks
            .map((json) => Track.fromPlexJson(
                  json,
                  serverId: server.machineIdentifier,
                  libraryKey: libraryKey,
                ))
            .toList();

        await _dbService.tracks.saveAll(
          server.machineIdentifier,
          libraryKey,
          trackObjects,
          onProgress: (current, total) {
            onStatusChange('$libraryTitle (saving $current/$total)');
          },
        );

        totalTracks += tracks.length;
        librariesCompleted++;

        onProgressChange(librariesCompleted / totalLibraries);
        onTracksSyncedChange(totalTracks);

        debugPrint(
            'Completed ${tracks.length} tracks from library $libraryKey');
      }

      // --- Sync playlists ---
      onStatusChange('Syncing Playlists...');
      try {
        final playlists = await _playlistService.syncPlaylists(
          serverUrl,
          token,
          server.machineIdentifier,
        );

        debugPrint(
            'Found ${playlists.length} playlists. Fetching items...');

        for (final playlist in playlists) {
          onStatusChange('Syncing Playlist: ${playlist.title}');

          try {
            final tracksJson = await _playlistService.getPlaylistTracks(
              serverUrl,
              token,
              playlist.id,
            );

            final playlistTracks = tracksJson
                .map((json) => Track.fromPlexJson(
                      json,
                      serverId: server.machineIdentifier,
                      libraryKey: 'playlist_${playlist.id}',
                    ))
                .toList();

            await _dbService.playlists.saveTracks(playlist.id, playlistTracks);
            debugPrint(
                'Saved ${playlistTracks.length} tracks for playlist ${playlist.title}');
          } catch (e) {
            debugPrint(
                'Error syncing items for playlist ${playlist.title}: $e');
          }
        }
      } catch (e) {
        debugPrint('Error syncing playlists: $e');
        // Don't fail the whole sync if playlists fail
      }
    }

    LibraryChangeNotifier().notifyLibraryChanged();
    return totalTracks;
  }
}
