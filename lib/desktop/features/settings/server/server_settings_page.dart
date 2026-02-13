import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'server_settings_logic.dart';
import 'widgets/plex_auth_card.dart';
import 'widgets/server_library_selector.dart';
import 'widgets/sync_progress_card.dart';
import 'widgets/authentication_info_card.dart';

class ServerSettingsPage extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;

  const ServerSettingsPage({
    super.key,
    this.audioPlayerService,
  });

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _logic = ServerSettingsLogic();
  AudioPlayerService? get _audioPlayerService => widget.audioPlayerService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isLoadingServers = false;
  bool _isSyncing = false;
  String? _username;
  List<PlexServer> _servers = [];
  Map<String, List<Map<String, dynamic>>> _serverLibraries = {};
  Map<String, Set<String>> _selectedLibraries = {};
  Map<String, dynamic>? _syncStatus;
  double _syncProgress = 0.0;
  String? _currentSyncingLibrary;
  int _totalTracksSynced = 0;
  int _estimatedTotalTracks = 0;

  static const Color _backgroundColor = Color(0xFF303030);

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final username = await _logic.checkAuthStatus();
    if (username != null) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = true;
        _username = username;
      });
      await _loadServersAndLibraries();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    await _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final syncStatus = await _logic.loadSyncStatus();
    if (!mounted) return;
    if (syncStatus != null && syncStatus['lastSync'] != null) {
      syncStatus['lastSync'] = _logic.formatSyncDate(syncStatus['lastSync']);
    }
    setState(() => _syncStatus = syncStatus);
  }

  Future<void> _syncLibrary() async {
    if (!mounted) return;
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _totalTracksSynced = 0;
      _estimatedTotalTracks = 1;
    });

    try {
      final totalTracks = await _logic.syncLibrary(
        _servers,
        _serverLibraries,
        onStatusChange: (status) {
          if (mounted) setState(() => _currentSyncingLibrary = status);
        },
        onProgressChange: (progress) {
          if (mounted) setState(() => _syncProgress = progress);
        },
        onTracksSyncedChange: (tracks) {
          if (mounted) {
            setState(() {
              _totalTracksSynced = tracks;
              _estimatedTotalTracks = tracks;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced $totalTracks songs to local database'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSyncStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing library: $e'),
            backgroundColor: Colors.red,
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
        });
      }
    }
  }

  Future<void> _loadServersAndLibraries() async {
    if (!mounted) return;
    setState(() => _isLoadingServers = true);

    await _logic.loadServersAndLibraries(
      (servers) {
        if (mounted) _servers = servers;
      },
      (libraries) {
        if (mounted) {
          _serverLibraries = libraries;
          for (var key in libraries.keys) {
            if (!_selectedLibraries.containsKey(key)) {
              _selectedLibraries[key] = {};
            }
          }
        }
      },
      (selections) {
        if (mounted) _selectedLibraries = selections;
      },
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading servers: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    if (!mounted) return;
    setState(() => _isLoadingServers = false);
  }

  Future<void> _saveSelections() async {
    await _logic.saveSelections(_selectedLibraries, _servers);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server selections saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _signIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await _logic.signIn();

      if (result['success'] == true) {
        await _logic.saveCredentials(result['token'], result['username']);

        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _username = result['username'];
        });

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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _hasSelectedLibraries() {
    return _selectedLibraries.values.any((libraries) => libraries.isNotEmpty);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to disconnect from Plex?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Stop and clear the player bar
      await _audioPlayerService?.stop();
      
      await _logic.signOut();
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _username = null;
        _servers = [];
        _serverLibraries = {};
        _selectedLibraries = {};
        _syncStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from Plex')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Authentication Card
                  PlexAuthCard(
                    isAuthenticated: _isAuthenticated,
                    username: _username,
                    isLoading: _isLoading,
                    isSyncing: _isSyncing,
                    canSync: _hasSelectedLibraries(),
                    onSignIn: _signIn,
                    onSignOut: _signOut,
                    onSync: _syncLibrary,
                  ),

                  // Sync Progress Card
                  if (_isAuthenticated) ...[
                    const SizedBox(height: 16),
                    SyncProgressCard(
                      isSyncing: _isSyncing,
                      syncProgress: _syncProgress,
                      totalTracksSynced: _totalTracksSynced,
                      estimatedTotalTracks: _estimatedTotalTracks,
                      currentSyncingLibrary: _currentSyncingLibrary,
                      syncStatus: _syncStatus,
                    ),
                  ],

                  // Server and Library Selection
                  if (_isAuthenticated) ...[
                    const SizedBox(height: 16),
                    ServerLibrarySelector(
                      servers: _servers,
                      serverLibraries: _serverLibraries,
                      selectedLibraries: _selectedLibraries,
                      isLoading: _isLoadingServers,
                      onSave: _saveSelections,
                      onSelectionChanged: (serverId, libraryKey, isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedLibraries[serverId] ??= {};
                            _selectedLibraries[serverId]!.add(libraryKey);
                          } else {
                            _selectedLibraries[serverId]?.remove(libraryKey);
                          }
                        });
                      },
                    ),
                  ],

                  // Authentication Info Card
                  const SizedBox(height: 16),
                  const AuthenticationInfoCard(),
                ],
              ),
            ),
    );
  }
}
