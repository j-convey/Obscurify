import 'package:flutter/material.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/core/models/track.dart';
import 'package:obscurify/core/models/album.dart';
import 'package:obscurify/core/models/playlist.dart';
import 'package:obscurify/core/services/playlist_service.dart';
import 'package:obscurify/core/services/library_change_notifier.dart';

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
  /// Clears all previous user data before saving new credentials to prevent
  /// credentials/server data mismatch between different users.
  Future<void> saveCredentials(String token, String? username) async {
    // Wipe all previous user data to prevent cross-user contamination
    await _storageService.clearPlexCredentials();
    await _dbService.clearAllData();
    
    // Save new credentials
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

  /// Restore access tokens from storage into PlexServer objects.
  /// This is useful when reconstructing server objects without calling the API.
  Future<List<PlexServer>> restoreServerAccessTokens(
    List<PlexServer> servers,
  ) async {
    final accessTokenMap = await _storageService.getServerAccessTokenMap();
    
    return servers.map((server) {
      final storedToken = accessTokenMap[server.machineIdentifier];
      if (storedToken != null && server.accessToken == null) {
        return PlexServer(
          name: server.name,
          machineIdentifier: server.machineIdentifier,
          connections: server.connections,
          accessToken: storedToken,
        );
      }
      return server;
    }).toList();
  }

  /// Fetch music libraries for a single server.
  /// Fetch music libraries for a single server.
  Future<List<Map<String, dynamic>>> getLibrariesForServer(
    String token,
    PlexServer server,
  ) async {
    final serverUrl = _serverService.getBestConnectionUrlForServer(server);
    if (serverUrl == null) return [];

    try {
      // Use server-specific accessToken for shared servers, fall back to user token for owned servers
      final effectiveToken = server.accessToken ?? token;
      debugPrint('SERVER_SETTINGS: Fetching libraries for ${server.name} - using ${server.accessToken != null ? "server accessToken" : "user token"}');
      
      final libraries = await _libraryService.getLibraries(effectiveToken, serverUrl);
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

  /// Persist a mapping of serverId → best connection URL and access tokens.
  Future<void> saveServerUrlMap(List<PlexServer> servers) async {
    final Map<String, String> urlMap = {};
    final Map<String, String> accessTokenMap = {};
    
    for (var server in servers) {
      final serverUrl = _serverService.getBestConnectionUrlForServer(server);
      if (serverUrl != null) {
        urlMap[server.machineIdentifier] = serverUrl;
      }
      if (server.accessToken != null) {
        accessTokenMap[server.machineIdentifier] = server.accessToken!;
      }
    }
    
    await _storageService.saveServerUrlMap(urlMap);
    await _storageService.saveServerAccessTokenMap(accessTokenMap);
    
    debugPrint('Saved ${urlMap.length} server URLs to storage');
    debugPrint('Saved ${accessTokenMap.length} server access tokens to storage');
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

      // Use server-specific accessToken for shared servers, fall back to user token
      final effectiveToken = server.accessToken ?? token;
      debugPrint('SYNC: Using ${server.accessToken != null ? "server accessToken" : "user token"} for ${server.name}');

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
            await _libraryService.getTracks(effectiveToken, serverUrl, libraryKey);

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

      // --- Sync albums (fetch full album metadata) ---
      for (var libraryKey in libraryKeys) {
        final libraryInfo = serverLibraries[server.machineIdentifier]
            ?.firstWhere(
              (lib) => lib['key'] == libraryKey,
              orElse: () => {'title': 'Library $libraryKey'},
            );
        final libraryTitle =
            libraryInfo?['title'] as String? ?? 'Library $libraryKey';

        onStatusChange('$libraryTitle (fetching albums...)');
        debugPrint(
            'Fetching albums from library $libraryKey on ${server.machineIdentifier}...');

        final albums =
            await _libraryService.getAlbums(effectiveToken, serverUrl, libraryKey);

        if (albums.isNotEmpty) {
          onStatusChange('$libraryTitle (saving ${albums.length} albums...)');
          debugPrint('Saving ${albums.length} albums from library $libraryKey...');

          final albumObjects = albums
              .map((json) => Album.fromPlexJson(
                    json,
                    server.machineIdentifier,
                  ))
              .toList();

          await _dbService.albums.saveAll(
            server.machineIdentifier,
            albumObjects,
            onProgress: (current, total) {
              onStatusChange('$libraryTitle (saving album $current/$total)');
            },
          );

          debugPrint(
              'Completed ${albums.length} albums from library $libraryKey');
        } else {
          debugPrint('No albums found in library $libraryKey');
        }
      }

      // --- Sync playlists ---
      onStatusChange('Syncing Playlists...');
      try {
        // Fetch playlists without saving them first
        final playlists = await _playlistService.fetchPlaylists(
          serverUrl,
          effectiveToken,
          serverId: server.machineIdentifier,
        );

        debugPrint(
            'Found ${playlists.length} playlists from server. Filtering by synced libraries...');

        int savedCount = 0;
        final playlistsToSave = <Playlist>[];
        
        for (final playlist in playlists) {
          onStatusChange('Checking Playlist: ${playlist.title}');

          try {
            final tracksJson = await _playlistService.getPlaylistTracks(
              serverUrl,
              token,
              playlist.id,
              serverId: server.machineIdentifier,
            );

            final playlistTracks = tracksJson
                .map((json) => Track.fromPlexJson(
                      json,
                      serverId: server.machineIdentifier,
                      libraryKey: 'playlist_${playlist.id}',
                    ))
                .toList();

            // Check if any tracks from this playlist exist in synced libraries
            bool hasTracksInSyncedLibs = false;
            for (final track in playlistTracks) {
              final existsInDb = await _dbService.tracks.getByRatingKey(track.ratingKey);
              if (existsInDb != null) {
                hasTracksInSyncedLibs = true;
                break;
              }
            }

            if (hasTracksInSyncedLibs) {
              await _dbService.playlists.saveTracks(playlist.id, playlistTracks);
              playlistsToSave.add(playlist.copyWith(serverId: server.machineIdentifier));
              savedCount++;
              debugPrint(
                  'Saved playlist "${playlist.title}" (${playlistTracks.length} tracks)');
            } else {
              // Delete playlist if it was previously saved but no longer has tracks
              await _dbService.playlists.deleteById(playlist.id);
              debugPrint(
                  'Skipped playlist "${playlist.title}" - no tracks from synced libraries');
            }
          } catch (e) {
            debugPrint(
                'Error syncing items for playlist ${playlist.title}: $e');
          }
        }
        
        // Now save only the playlists that have tracks from synced libraries
        if (playlistsToSave.isNotEmpty) {
          await _dbService.playlists.saveAll(playlistsToSave);
        }
        
        debugPrint('Saved $savedCount/${playlists.length} playlists with tracks from synced libraries');
      } catch (e) {
        debugPrint('Error syncing playlists: $e');
        // Don't fail the whole sync if playlists fail
      }
    }

    LibraryChangeNotifier().notifyLibraryChanged();
    return totalTracks;
  }
}
