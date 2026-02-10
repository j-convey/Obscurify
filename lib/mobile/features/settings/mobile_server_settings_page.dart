import 'package:flutter/material.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/database/database_service.dart';
import 'package:obscurify/core/models/track.dart';

class MobileServerSettingsPage extends StatefulWidget {
  const MobileServerSettingsPage({super.key});

  @override
  State<MobileServerSettingsPage> createState() => _MobileServerSettingsPageState();
}

class _MobileServerSettingsPageState extends State<MobileServerSettingsPage> {
  final PlexAuthService _authService = PlexAuthService();
  final PlexServerService _serverService = PlexServerService();
  final PlexLibraryService _libraryService = PlexLibraryService();
  final StorageService _storageService = StorageService();
  final DatabaseService _dbService = DatabaseService();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isLoadingServers = false;
  bool _isSyncing = false;
  String? _username;
  List<PlexServer> _servers = [];
  Map<String, List<Map<String, dynamic>>> _serverLibraries = {};
  // Single selection: only one server and one library can be selected
  String? _selectedServerId;
  String? _selectedLibraryKey;
  Map<String, dynamic>? _syncStatus;
  double _syncProgress = 0.0;
  String? _currentSyncingLibrary;
  int _totalTracksSynced = 0;
  int _estimatedTotalTracks = 0;
  bool _isSavingToDatabase = false;
  int _tracksSavedToDb = 0;
  int _totalTracksToSave = 0;

  static const Color _backgroundColor = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final token = await _storageService.getPlexToken();
    if (token != null) {
      final isValid = await _authService.validateToken(token);
      if (isValid) {
        final user = await _storageService.getUsername();
        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _username = user;
        });
        await _loadServersAndLibraries();
      } else {
        await _storageService.clearPlexCredentials();
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

    // Load sync status
=======
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
    await _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final syncMetadata = await _dbService.tracks.getAllSyncMetadata();
      final trackCount = await _dbService.tracks.getCount();
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

=======
      
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
      if (syncMetadata.isNotEmpty) {
        final lastSync = syncMetadata.first['last_sync'] as int;
        final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);

        if (mounted) {
          setState(() {
            _syncStatus = {'trackCount': trackCount, 'lastSync': lastSyncDate};
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
  }

  Future<void> _syncLibrary() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);

    try {
      final token = await _storageService.getPlexToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
      final selectedServer = await _storageService.getSelectedServer();
      final selectedLibrary = await _storageService.getSelectedLibrary();
      if (selectedServer == null || selectedLibrary == null) {
        throw Exception('No server or library selected');
      }

      // First pass: estimate total tracks by fetching counts
      int estimatedTracks = 0;
      final serverUrl = await _storageService.getSelectedServerUrl();
      if (serverUrl != null) {
        try {
          final tracks = await _libraryService.getTracks(
            token,
            serverUrl,
            selectedLibrary,
          );
          estimatedTracks += tracks.length;
        } catch (e) {
          // Continue if error
        }
      }

=======
      final selectedServers = await _storageService.getSelectedServers();
      if (selectedServers.isEmpty) {
        throw Exception('No libraries selected');
      }

      int totalLibraries = 0;
      for (var server in _servers) {
        final libraryKeys = selectedServers[server.machineIdentifier];
        if (libraryKeys != null && libraryKeys.isNotEmpty) {
          totalLibraries += libraryKeys.length;
        }
      }

>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
      if (!mounted) return;
      setState(() {
        _syncProgress = 0.0;
        _totalTracksSynced = 0;
        _estimatedTotalTracks = 1;
      });

      int totalTracks = 0;
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

      // Sync tracks from the selected library
      if (serverUrl != null) {
        if (!mounted) return;

        // Update progress tracking
        final libraryInfo = _serverLibraries[selectedServer]?.firstWhere(
          (lib) => lib['key'] == selectedLibrary,
          orElse: () => {'title': 'Library $selectedLibrary'},
        );
        final libraryTitle =
            libraryInfo?['title'] as String? ?? 'Library $selectedLibrary';

        setState(() {
          _currentSyncingLibrary = libraryTitle;
        });

        // Allow UI to render progress update
        await Future.delayed(const Duration(milliseconds: 50));

        print(
          'Syncing library $selectedLibrary from server $selectedServer...',
        );

        final tracks = await _libraryService.getTracks(
          token,
          serverUrl,
          selectedLibrary,
        );

        // Update progress for each track after fetching
        for (int i = 0; i < tracks.length; i++) {
          if (!mounted) return;

          final track = tracks[i];
          track['serverId'] = selectedServer;

          // Update progress after each track
          setState(() {
            _totalTracksSynced++;
            _syncProgress = _estimatedTotalTracks > 0
                ? _totalTracksSynced / _estimatedTotalTracks
                : 0.0;
          });

          // Render update every 5 tracks or on last track
          if (i % 5 == 0 || i == tracks.length - 1) {
            await Future.delayed(const Duration(milliseconds: 16));
=======
      int librariesCompleted = 0;
      
      for (var server in _servers) {
        final libraryKeys = selectedServers[server.machineIdentifier];
        
        if (libraryKeys != null && libraryKeys.isNotEmpty) {
          final serverUrl = _serverService.getBestConnectionUrlForServer(server);
          
          if (serverUrl != null) {
            for (var libraryKey in libraryKeys) {
              if (!mounted) return;
              
              final libraryInfo = _serverLibraries[server.machineIdentifier]
                  ?.firstWhere(
                    (lib) => lib['key'] == libraryKey,
                    orElse: () => {'title': 'Library $libraryKey'},
                  );
              final libraryTitle = libraryInfo?['title'] as String? ?? 'Library $libraryKey';
              
              setState(() {
                _currentSyncingLibrary = '$libraryTitle (fetching...)';
              });

              debugPrint('Fetching library $libraryKey from server ${server.machineIdentifier}...');
              
              final tracksJson = await _libraryService.getTracks(token, serverUrl, libraryKey);
              
              final tracks = tracksJson.map((json) {
                return Track.fromPlexJson(
                  json,
                  serverId: server.machineIdentifier,
                  libraryKey: libraryKey,
                );
              }).toList();
              
              if (!mounted) return;
              setState(() {
                _currentSyncingLibrary = '$libraryTitle (saving...)';
                _estimatedTotalTracks = totalTracks + tracks.length;
              });
              
              debugPrint('Saving ${tracks.length} tracks from library $libraryKey...');
              
              await _dbService.tracks.saveAll(
                server.machineIdentifier,
                libraryKey,
                tracks,
                onProgress: (current, total) {
                  if (mounted) {
                    setState(() {
                      _currentSyncingLibrary = '$libraryTitle (saving $current/$total)';
                    });
                  }
                },
              );
              
              totalTracks += tracks.length;
              librariesCompleted++;
              
              if (!mounted) return;
              setState(() {
                _totalTracksSynced = totalTracks;
                _syncProgress = librariesCompleted / totalLibraries;
              });
              
              debugPrint('Completed ${tracks.length} tracks from library $libraryKey');
            }
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
          }
        }

        // Add serverId to all tracks
        final tracksWithServerId = tracks.map((track) {
          track['serverId'] = selectedServer;
          return track;
        }).toList();

        // Update UI to show database save in progress
        if (!mounted) return;
        setState(() {
          _isSavingToDatabase = true;
          _tracksSavedToDb = 0;
          _totalTracksToSave = tracksWithServerId.length;
          _currentSyncingLibrary = 'Saving to database...';
        });

        await _dbService.saveTracks(
          selectedServer,
          selectedLibrary,
          tracksWithServerId,
          onProgress: (current, total) {
            if (mounted) {
              setState(() {
                _tracksSavedToDb = current;
                _totalTracksToSave = total;
              });
            }
          },
        );
        totalTracks += tracks.length;

        if (!mounted) return;

        print('Synced ${tracks.length} tracks from library $selectedLibrary');
      }

      if (mounted) {
        // Show success message with longer duration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Successfully synced $totalTracks songs to local database',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadSyncStatus();
        
        // Keep the progress bar at 100% visible for a moment before clearing
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error syncing library: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgress = 0.0;
          _totalTracksSynced = 0;
          _estimatedTotalTracks = 0;
          _currentSyncingLibrary = null;
          _isSavingToDatabase = false;
          _tracksSavedToDb = 0;
          _totalTracksToSave = 0;
        });
      }
    }
  }

  Future<void> _loadServersAndLibraries() async {
    if (!mounted) return;
    setState(() => _isLoadingServers = true);

    final token = await _storageService.getPlexToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoadingServers = false);
      return;
    }

    try {
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
      // Get servers
      debugPrint('SERVER_SETTINGS: Fetching servers...');
      _servers = await _serverService.getServers(token);
      debugPrint('SERVER_SETTINGS: Found ${_servers.length} servers');

      if (_servers.isEmpty) {
        debugPrint('SERVER_SETTINGS: No servers returned from API');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No Plex servers found. Make sure your server is online and accessible.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }

      // Load saved single selection
      _selectedServerId = await _storageService.getSelectedServer();
      _selectedLibraryKey = await _storageService.getSelectedLibrary();
=======
      _servers = await _serverService.getServers(token);
      
      final savedSelections = await _storageService.getSelectedServers();
      _selectedLibraries = savedSelections.map(
        (key, value) => MapEntry(key, value.toSet())
      );
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart

      final libraryFutures = _servers.map((server) async {
        if (!mounted) return MapEntry('', <Map<String, dynamic>>[]);

        debugPrint(
          'SERVER_SETTINGS: Processing server "${server.name}" (${server.machineIdentifier})',
        );
        debugPrint(
          'SERVER_SETTINGS: Server has ${server.connections.length} connections',
        );

        final serverUrl = _serverService.getBestConnectionUrlForServer(server);
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

        if (serverUrl == null) {
          debugPrint(
            'SERVER_SETTINGS: ⚠️ No valid connection URL for server "${server.name}"',
          );
          return MapEntry(server.machineIdentifier, <Map<String, dynamic>>[]);
        }

        debugPrint('SERVER_SETTINGS: Using URL: $serverUrl');

        try {
          final libraries = await _libraryService.getMusicLibraries(
            token,
            serverUrl,
          );
          debugPrint(
            'SERVER_SETTINGS: Found ${libraries.length} music libraries for "${server.name}"',
          );
          return MapEntry(
            server.machineIdentifier,
            libraries.map((l) => l.toJson()).toList(),
          );
        } catch (e) {
          debugPrint(
            'SERVER_SETTINGS: ❌ Error fetching libraries for "${server.name}": $e',
          );
          // Error fetching libraries - return empty list
          return MapEntry(server.machineIdentifier, <Map<String, dynamic>>[]);
=======
        
        if (serverUrl != null) {
          try {
            final libraries = await _libraryService.getLibraries(token, serverUrl);
            final musicLibraries = libraries.where((l) => l.isMusicLibrary).toList();
            return MapEntry(server.machineIdentifier, musicLibraries.map((l) => l.toJson()).toList());
          } catch (e) {
            return MapEntry(server.machineIdentifier, <Map<String, dynamic>>[]);
          }
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
        }
      }).toList();

      final libraryResults = await Future.wait(libraryFutures);

      if (!mounted) return;
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

      // Update state with results
      int totalLibraries = 0;
      for (var entry in libraryResults) {
        if (entry.key.isEmpty)
          continue; // Skip empty entries from early returns
        _serverLibraries[entry.key] = entry.value;
        totalLibraries += entry.value.length;
=======
      
      for (var entry in libraryResults) {
        if (entry.key.isEmpty) continue;
        _serverLibraries[entry.key] = entry.value;
        
        if (!_selectedLibraries.containsKey(entry.key)) {
          _selectedLibraries[entry.key] = {};
        }
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
      }

      debugPrint('SERVER_SETTINGS: Total libraries loaded: $totalLibraries');

      // Show warning if servers were found but no libraries
      if (_servers.isNotEmpty && totalLibraries == 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Servers found but no libraries could be loaded. Check server connectivity.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('SERVER_SETTINGS: ❌ Fatal error loading servers: $e');
      debugPrint('SERVER_SETTINGS: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading servers: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoadingServers = false);
  }

  Future<void> _saveSelections() async {
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
    // Validate that both server and library are selected
    if (_selectedServerId == null || _selectedLibraryKey == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a server and a library'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Save single selection
    await _storageService.saveSelectedServer(_selectedServerId!);
    await _storageService.saveSelectedLibrary(_selectedLibraryKey!);

    // Only now determine and save the best connection URL for the selected server
    await _saveSelectedServerUrl();

=======
    final selections = _selectedLibraries.map(
      (key, value) => MapEntry(key, value.toList())
    );
    await _storageService.saveSelectedServers(selections);
    await _saveServerUrlMap();
    
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server selection saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
  /// Saves the best connection URL for the selected server only.
  /// This is only called when user explicitly saves their selection.
  Future<void> _saveSelectedServerUrl() async {
    if (_selectedServerId == null) return;

    final server = _servers.firstWhere(
      (s) => s.machineIdentifier == _selectedServerId,
      orElse: () => throw Exception('Selected server not found'),
    );

    // Get the best remote direct connection for the selected server
    final serverUrl = _serverService.getBestConnectionUrlForServer(server);
    if (serverUrl != null) {
      await _storageService.saveSelectedServerUrl(serverUrl);
      debugPrint('Saved selected server URL: $_selectedServerId -> $serverUrl');
=======
  Future<void> _saveServerUrlMap() async {
    final Map<String, String> urlMap = {};
    
    for (var server in _servers) {
      final serverUrl = _serverService.getBestConnectionUrlForServer(server);
      if (serverUrl != null) {
        urlMap[server.machineIdentifier] = serverUrl;
        debugPrint('Saving server URL: ${server.machineIdentifier} -> $serverUrl');
      }
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
    }
  }

  Future<void> _signIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signIn();

      if (result['success'] == true) {
        await _storageService.savePlexToken(result['token']);
        if (result['username'] != null) {
          await _storageService.saveUsername(result['username']);
        }

        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _username = result['username'];
        });
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

        // Load servers and libraries after successful sign-in
=======
        
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
        await _loadServersAndLibraries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to Plex!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign in: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSyncDate(DateTime date) {
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to disconnect from Plex?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearPlexCredentials();
      await _dbService.clearAllData();
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _username = null;
        _servers = [];
        _serverLibraries = {};
        _selectedServerId = null;
        _selectedLibraryKey = null;
        _syncStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from Plex and cleared local data'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Server Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Plex Connection Card
                  Card(
                    color: const Color(0xFF282828),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAuthenticated ? Icons.check_circle : Icons.cloud_off,
                                color: _isAuthenticated ? Colors.green : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                                      _isAuthenticated
                                          ? 'Connected'
                                          : 'Not Connected',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
=======
                                      _isAuthenticated ? 'Connected' : 'Not Connected',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                                    ),
                                    if (_username != null)
                                      Text(
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                                        'Logged in as $_username',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
=======
                                        _username!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF404040)),
                          const SizedBox(height: 16),
                          const Text(
                            'Plex Server',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isAuthenticated
                                ? 'Your Plex account is connected. Select libraries below to sync.'
                                : 'Connect to your Plex account to access your media libraries.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isAuthenticated) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSyncing ? null : _syncLibrary,
                                    icon: _isSyncing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.sync),
                                    label: Text(
                                      _isSyncing
                                          ? 'Syncing...'
                                          : 'Sync Library',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _signOut,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF404040),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                            if (_isSyncing && _estimatedTotalTracks > 0) ...[
                              const SizedBox(height: 16),
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.sync,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _isSavingToDatabase
                                                ? 'Saving to database...'
                                                : 'Syncing $_currentSyncingLibrary',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _isSavingToDatabase
                                            ? (_totalTracksToSave > 0
                                                ? _tracksSavedToDb / _totalTracksToSave
                                                : 0.0)
                                            : _syncProgress,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.blue[600]!,
                                            ),
=======
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _currentSyncingLibrary ?? 'Syncing...',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                                      ),
                                      Text(
                                        '${(_syncProgress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _syncProgress,
                                      backgroundColor: const Color(0xFF404040),
                                      color: Colors.purple,
                                      minHeight: 8,
                                    ),
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                                    const SizedBox(height: 8),
                                    Text(
                                      _isSavingToDatabase
                                          ? 'Saving $_tracksSavedToDb of $_totalTracksToSave songs to database'
                                          : '${(_syncProgress * 100).toStringAsFixed(0)}% • $_totalTracksSynced of $_estimatedTotalTracks songs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
=======
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_totalTracksSynced tracks synced',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_syncStatus != null && !_isSyncing) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a1a1a),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Last Sync',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatSyncDate(_syncStatus!['lastSync']),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Tracks',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${_syncStatus!['trackCount']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else
                            ElevatedButton.icon(
                              onPressed: _signIn,
                              icon: const Icon(Icons.login),
                              label: const Text('Sign In with Plex'),
                              style: ElevatedButton.styleFrom(
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
=======
                                backgroundColor: Colors.purple,
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Server and Library Selection
                  if (_isAuthenticated) ...[
                    const SizedBox(height: 16),
                    if (_isLoadingServers)
                      const Card(
                        color: Color(0xFF282828),
                        child: Padding(
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
=======
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.purple),
                          ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                        ),
                      )
                    else if (_servers.isEmpty)
                      Card(
                        color: const Color(0xFF282828),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                              const Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.orange,
                              ),
=======
                              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                              const SizedBox(height: 16),
                              const Text(
                                'No servers found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Make sure your Plex Media Server is running and accessible.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                              Text(
                                'Select Server & Library',
                                style: Theme.of(context).textTheme.titleLarge,
=======
                              const Text(
                                'Select Libraries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                              ),
                              TextButton(
                                onPressed: _saveSelections,
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                          Text(
                            'Choose one server and one music library to use in Apollo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
=======
                          const Text(
                            'Choose which music libraries you want to use in Obscurify',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                          ),
                          const SizedBox(height: 16),
                          ..._servers.map((server) {
                            final serverId = server.machineIdentifier;
                            final serverName = server.name;
                            final libraries = _serverLibraries[serverId] ?? [];
                            final isServerSelected =
                                _selectedServerId == serverId;

                            return Card(
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  // Server selection (radio button style)
                                  RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        const Icon(Icons.dns),
                                        const SizedBox(width: 12),
                                        Text(serverName),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${libraries.length} music ${libraries.length == 1 ? 'library' : 'libraries'}',
                                    ),
                                    value: serverId,
                                    groupValue: _selectedServerId,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedServerId = value;
                                        // Clear library selection when switching servers
                                        _selectedLibraryKey = null;
                                      });
                                    },
                                  ),
                                  // Only show libraries if this server is selected
                                  if (isServerSelected) ...[
                                    const Divider(height: 1),
                                    if (libraries.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'No music libraries found on this server',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    else
                                      ...libraries.map((library) {
                                        final libraryKey =
                                            library['key'] as String;
                                        final libraryTitle =
                                            library['title'] as String;

                                        return RadioListTile<String>(
                                          title: Text(libraryTitle),
                                          subtitle: Text(
                                            'Library ID: $libraryKey',
                                          ),
                                          value: libraryKey,
                                          groupValue: _selectedLibraryKey,
                                          onChanged: (String? value) {
                                            setState(() {
                                              _selectedLibraryKey = value;
                                            });
                                          },
                                          contentPadding: const EdgeInsets.only(
                                            left: 48,
                                            right: 16,
                                          ),
                                        );
                                      }),
                                  ],
                                ],
=======
                              color: const Color(0xFF282828),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.dns, color: Colors.purple, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            serverName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (libraries.isEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No music libraries found',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 12),
                                      ...libraries.map((library) {
                                        final libraryKey = library['key'] as String;
                                        final libraryTitle = library['title'] as String;
                                        final isSelected = _selectedLibraries[serverId]?.contains(libraryKey) ?? false;
                                        
                                        return CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            libraryTitle,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          value: isSelected,
                                          activeColor: Colors.purple,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedLibraries[serverId] ??= {};
                                                _selectedLibraries[serverId]!.add(libraryKey);
                                              } else {
                                                _selectedLibraries[serverId]?.remove(libraryKey);
                                              }
                                            });
                                          },
                                        );
                                      }),
                                    ],
                                  ],
                                ),
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
<<<<<<< HEAD:lib/features/settings/server/server_settings_page.dart

=======
                  
                  // How Authentication Works
>>>>>>> file-structure-refactor:lib/mobile/features/settings/mobile_server_settings_page.dart
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFF282828),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How Authentication Works',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Click "Sign In with Plex"\n'
                            '2. Your browser will open to Plex login page\n'
                            '3. Sign in with your Plex credentials\n'
                            '4. Once authenticated, return to this app\n'
                            '5. Your credentials will be securely stored',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
