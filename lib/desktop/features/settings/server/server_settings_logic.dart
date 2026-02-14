import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/core/services/server_settings_service.dart';

class ServerSettingsLogic {
  final _service = ServerSettingsService();

  Future<String?> checkAuthStatus() async {
    return await _service.checkAuthStatus();
  }

  Future<Map<String, dynamic>?> loadSyncStatus() async {
    return await _service.loadSyncStatus();
  }

  Future<int> syncLibrary(
    List<PlexServer> servers,
    Map<String, List<Map<String, dynamic>>> serverLibraries, {
    required Function(String) onStatusChange,
    required Function(double) onProgressChange,
    required Function(int) onTracksSyncedChange,
  }) async {
    return await _service.syncLibrary(
      servers,
      serverLibraries,
      onStatusChange: onStatusChange,
      onProgressChange: onProgressChange,
      onTracksSyncedChange: onTracksSyncedChange,
    );
  }

  Future<void> loadServersAndLibraries(
    Function(List<PlexServer>) onServersLoaded,
    Function(Map<String, List<Map<String, dynamic>>>) onLibrariesLoaded,
    Function(Map<String, Set<String>>) onSelectionsLoaded,
    Function(String) onError,
  ) async {
    final token = await _service.getPlexToken();
    if (token == null) {
      return;
    }

    try {
      final servers = await _service.getServers(token);
      onServersLoaded(servers);

      final savedSelections = await _service.getSelectedServers();
      final selectedLibraries =
          savedSelections.map((key, value) => MapEntry(key, value.toSet()));
      onSelectionsLoaded(selectedLibraries);

      final libraryFutures = servers.map((server) async {
        final libraries = await _service.getLibrariesForServer(token, server);
        return MapEntry(server.machineIdentifier, libraries);
      }).toList();

      final libraryResults = await Future.wait(libraryFutures);
      
      final librariesMap = <String, List<Map<String, dynamic>>>{};
      for (var entry in libraryResults) {
        librariesMap[entry.key] = entry.value;
      }
      onLibrariesLoaded(librariesMap);
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> saveSelections(
    Map<String, Set<String>> selectedLibraries,
    List<PlexServer> servers,
  ) async {
    await _service.saveSelections(selectedLibraries, servers);
  }

  Future<Map<String, dynamic>> signIn() async {
    return await _service.signIn();
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  Future<void> saveCredentials(String token, String username, {String? profilePictureUrl}) async {
    await _service.saveCredentials(token, username, profilePictureUrl: profilePictureUrl);
  }

  Future<String?> getPlexToken() async {
    return await _service.getPlexToken();
  }

  String formatSyncDate(DateTime date) {
    return _service.formatSyncDate(date);
  }
}
