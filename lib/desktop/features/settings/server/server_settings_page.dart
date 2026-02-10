import 'package:flutter/material.dart';
import 'package:apollo/core/services/plex/plex_services.dart';
import 'package:apollo/core/services/server_settings_service.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _service = ServerSettingsService();

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

    final username = await _service.checkAuthStatus();
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
    final syncStatus = await _service.loadSyncStatus();
    if (!mounted) return;
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
      final totalTracks = await _service.syncLibrary(
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

    final token = await _service.getPlexToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _isLoadingServers = false);
      return;
    }

    try {
      _servers = await _service.getServers(token);

      final savedSelections = await _service.getSelectedServers();
      _selectedLibraries =
          savedSelections.map((key, value) => MapEntry(key, value.toSet()));

      final libraryFutures = _servers.map((server) async {
        final libraries = await _service.getLibrariesForServer(token, server);
        return MapEntry(server.machineIdentifier, libraries);
      }).toList();

      final libraryResults = await Future.wait(libraryFutures);

      if (!mounted) return;

      for (var entry in libraryResults) {
        _serverLibraries[entry.key] = entry.value;
        if (!_selectedLibraries.containsKey(entry.key)) {
          _selectedLibraries[entry.key] = {};
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading servers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoadingServers = false);
  }

  Future<void> _saveSelections() async {
    await _service.saveSelections(_selectedLibraries, _servers);

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
      final result = await _service.signIn();

      if (result['success'] == true) {
        await _service.saveCredentials(result['token'], result['username']);

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
      await _service.signOut();
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAuthenticated
                                    ? Icons.check_circle
                                    : Icons.cloud_off,
                                color: _isAuthenticated
                                    ? Colors.green
                                    : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAuthenticated
                                          ? 'Connected'
                                          : 'Not Connected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    if (_isAuthenticated && _username != null)
                                      Text(
                                        'Logged in as $_username',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Plex Server',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isAuthenticated
                                ? 'Your Plex account is connected. You can access your media libraries and content.'
                                : 'Connect to your Plex account to access your media libraries.',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Library'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _signOut,
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Sign Out'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (_isSyncing && _estimatedTotalTracks > 0) ...[
                              const SizedBox(height: 16),
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
                                        const Icon(Icons.sync, size: 20, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Syncing $_currentSyncingLibrary',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _syncProgress,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_syncProgress * 100).toStringAsFixed(0)}% • $_totalTracksSynced of $_estimatedTotalTracks songs',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_syncStatus != null && !_isSyncing) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_syncStatus!['trackCount']} songs synced • Last sync: ${_service.formatSyncDate(_syncStatus!['lastSync'])}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ]
                          else
                            ElevatedButton.icon(
                              onPressed: _signIn,
                              icon: const Icon(Icons.login),
                              label: const Text('Sign In with Plex'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
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
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    else if (_servers.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                              const SizedBox(height: 16),
                              Text(
                                'No servers found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Make sure you have a Plex Media Server set up and it\'s accessible.',
                                textAlign: TextAlign.center,
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
                              Text(
                                'Select Libraries',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              FilledButton.icon(
                                onPressed: _saveSelections,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose which music libraries you want to use in Apollo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._servers.map((server) {
                            final serverId = server.machineIdentifier;
                            final serverName = server.name;
                            final libraries = _serverLibraries[serverId] ?? [];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                leading: const Icon(Icons.dns),
                                title: Text(serverName),
                                subtitle: Text('${libraries.length} music ${libraries.length == 1 ? 'library' : 'libraries'}'),
                                children: [
                                  if (libraries.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No music libraries found on this server',
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    )
                                  else
                                    ...libraries.map((library) {
                                      final libraryKey = library['key'] as String;
                                      final libraryTitle = library['title'] as String;
                                      final isSelected = _selectedLibraries[serverId]?.contains(libraryKey) ?? false;
                                      
                                      return CheckboxListTile(
                                        title: Text(libraryTitle),
                                        subtitle: Text('Library ID: $libraryKey'),
                                        value: isSelected,
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
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                  
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How Authentication Works',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Click "Sign In with Plex"\n'
                            '2. Your browser will open to Plex login page\n'
                            '3. Sign in with your Plex credentials\n'
                            '4. Once authenticated, return to this app\n'
                            '5. Your credentials will be securely stored',
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
