import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'plex/plex_server_service.dart';

/// Holds the resolved URL and authentication token for a Plex server.
///
/// Use this whenever you need to make requests to a Plex server.
/// The [token] is the correct token for the server — either the
/// server-specific access token (for shared servers) or the user's
/// account token (for owned servers).
class PlexServerConnection {
  final String url;
  final String token;

  const PlexServerConnection({required this.url, required this.token});
}

/// Single source of truth for resolving Plex server URLs and tokens.
///
/// Instead of each page independently calling [StorageService] and
/// [PlexServerService] to build URLs and pick tokens, every page
/// should go through this resolver. It handles:
///
/// - Owned servers (use user token)
/// - Shared servers (use server-specific access token)
/// - Per-server URL resolution from the cached URL map
/// - Falling back to the legacy single-URL if nothing else is available
class PlexConnectionResolver {
  // ── Singleton ───────────────────────────────────────────────────
  static final PlexConnectionResolver _instance = PlexConnectionResolver._internal();
  factory PlexConnectionResolver() => _instance;
  PlexConnectionResolver._internal();

  final StorageService _storageService = StorageService();
  final PlexServerService _serverService = PlexServerService();

  // In-memory caches so we don't hit SharedPreferences on every call.
  Map<String, String>? _urlMap;
  Map<String, String>? _accessTokenMap;
  String? _userToken;

  // ── Initialisation ──────────────────────────────────────────────

  /// Load all cached data from storage into memory.
  /// Call this once during page init, then use the sync getters.
  Future<void> initialise() async {
    _userToken = await _storageService.getPlexToken();
    _urlMap = await _storageService.getServerUrlMap();
    _accessTokenMap = await _storageService.getServerAccessTokenMap();

    debugPrint(
      'PlexConnectionResolver: initialised — '
      '${_urlMap?.length ?? 0} server URLs, '
      '${_accessTokenMap?.length ?? 0} access tokens',
    );
  }

  /// Refresh from storage (e.g. after a settings change or sync).
  Future<void> refresh() async => initialise();

  // ── Live API resolution ─────────────────────────────────────────

  /// Fetch the server URL map from the Plex API and cache it.
  /// Also caches access tokens found on the server objects.
  /// Returns the URL map for convenience.
  Future<Map<String, String>> fetchAndCacheServerUrls() async {
    final token = _userToken ?? await _storageService.getPlexToken();
    if (token == null) return {};

    final servers = await _serverService.getServers(token);
    final urlMap = _serverService.buildServerUrlMap(servers);

    // Also capture access tokens from the live API data.
    final accessTokenMap = <String, String>{};
    for (final server in servers) {
      if (server.accessToken != null) {
        accessTokenMap[server.machineIdentifier] = server.accessToken!;
      }
    }

    // Persist and cache both.
    await _storageService.saveServerUrlMap(urlMap);
    await _storageService.saveServerAccessTokenMap(accessTokenMap);

    _urlMap = urlMap;
    _accessTokenMap = accessTokenMap;

    return urlMap;
  }

  // ── Getters ─────────────────────────────────────────────────────

  /// The user's Plex account token.
  String? get userToken => _userToken;

  /// Full URL map (machineIdentifier → URL). Never null after [initialise].
  Map<String, String> get serverUrls => _urlMap ?? {};

  // ── Resolution helpers ──────────────────────────────────────────

  /// Resolve the URL for a given server ID from the cached map.
  String? getUrlForServer(String? serverId) {
    if (serverId == null) return null;
    return _urlMap?[serverId];
  }

  /// Resolve the correct auth token for a given server ID.
  ///
  /// Returns the server-specific access token if one exists (shared
  /// server), otherwise returns the user's account token.
  String? getTokenForServer(String? serverId) {
    if (serverId != null) {
      final serverToken = _accessTokenMap?[serverId];
      if (serverToken != null) return serverToken;
    }
    return _userToken;
  }

  /// Convenience: resolve both URL and token at once.
  ///
  /// Returns `null` if the server ID is unknown or no URL is cached.
  PlexServerConnection? getConnection(String? serverId) {
    final url = getUrlForServer(serverId);
    final token = getTokenForServer(serverId);
    if (url == null || token == null) return null;
    return PlexServerConnection(url: url, token: token);
  }

  /// Get the connection for whichever server has selected libraries.
  /// Falls back to legacy single-URL storage if nothing matches.
  Future<PlexServerConnection?> getSelectedServerConnection() async {
    final selectedServers = await _storageService.getSelectedServers();
    final urlMap = _urlMap ?? await _storageService.getServerUrlMap();

    for (final entry in selectedServers.entries) {
      if (entry.value.isNotEmpty && urlMap.containsKey(entry.key)) {
        final url = urlMap[entry.key]!;
        final token = getTokenForServer(entry.key);
        if (token != null) {
          return PlexServerConnection(url: url, token: token);
        }
      }
    }

    // Legacy fallback
    final legacyUrl = await _storageService.getServerUrl();
    if (legacyUrl != null && _userToken != null) {
      return PlexServerConnection(url: legacyUrl, token: _userToken!);
    }

    return null;
  }

  /// Build an authenticated image URL for a thumb/art path.
  ///
  /// Usage:
  /// ```dart
  /// final imageUrl = resolver.buildImageUrl(track.thumb, track.serverId);
  /// ```
  String? buildImageUrl(String? path, String? serverId) {
    if (path == null || path.isEmpty) return null;

    final url = getUrlForServer(serverId);
    final token = getTokenForServer(serverId);
    if (url == null || token == null) return null;

    return '$url$path?X-Plex-Token=$token';
  }
}
