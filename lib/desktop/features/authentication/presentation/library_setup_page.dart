import 'package:flutter/material.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/desktop/features/settings/server/server_settings_logic.dart';
import 'package:obscurify/desktop/features/settings/server/widgets/server_library_selector.dart';
import 'package:obscurify/desktop/features/settings/server/widgets/sync_progress_card.dart';

/// Onboarding page for first-time library setup after authentication.
class LibrarySetupPage extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const LibrarySetupPage({
    super.key,
    required this.onSetupComplete,
  });

  @override
  State<LibrarySetupPage> createState() => _LibrarySetupPageState();
}

class _LibrarySetupPageState extends State<LibrarySetupPage> {
  final _logic = ServerSettingsLogic();

  bool _isLoading = true;
  bool _isLoadingServers = false;
  bool _isSyncing = false;
  List<PlexServer> _servers = [];
  Map<String, List<Map<String, dynamic>>> _serverLibraries = {};
  Map<String, Set<String>> _selectedLibraries = {};
  double _syncProgress = 0.0;
  String? _currentSyncingLibrary;
  int _totalTracksSynced = 0;
  int _estimatedTotalTracks = 0;
  bool _hasCompletedSetup = false;

  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _primaryColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadServersAndLibraries();
  }

  Future<void> _loadServersAndLibraries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingServers = true;
    });

    await _logic.loadServersAndLibraries(
      (servers) {
        if (mounted) {
          setState(() => _servers = servers);
        }
      },
      (libraries) {
        if (mounted) {
          setState(() {
            _serverLibraries = libraries;
            for (var key in libraries.keys) {
              if (!_selectedLibraries.containsKey(key)) {
                _selectedLibraries[key] = {};
              }
            }
          });
        }
      },
      (selections) {
        if (mounted) {
          setState(() => _selectedLibraries = selections);
        }
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
    setState(() {
      _isLoading = false;
      _isLoadingServers = false;
    });
  }

  Future<void> _saveSelections() async {
    await _logic.saveSelections(_selectedLibraries, _servers);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Library selections saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
        setState(() => _hasCompletedSetup = true);
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

  bool _hasSelectedLibraries() {
    return _selectedLibraries.values.any((libraries) => libraries.isNotEmpty);
  }

  Future<void> _handleComplete() async {
    if (!_hasSelectedLibraries()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one library before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasCompletedSetup) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Skip Sync?'),
          content: const Text(
            'You haven\'t synced your library yet. You can sync later from settings, but your library will be empty until you do.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'Welcome to Obscurify!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let\'s set up your music library',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Steps indicator
                        _buildStepsIndicator(),
                        const SizedBox(height: 32),

                        // Step 1: Select Libraries
                        _buildStepCard(
                          stepNumber: 1,
                          title: 'Select Your Music Libraries',
                          description:
                              'Choose which libraries from your Plex servers you want to sync',
                          child: ServerLibrarySelector(
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
                        ),

                        const SizedBox(height: 24),

                        // Step 2: Sync
                        _buildStepCard(
                          stepNumber: 2,
                          title: 'Sync Your Music',
                          description:
                              'Download your library metadata to start enjoying your music',
                          child: Column(
                            children: [
                              if (_isSyncing) ...[
                                SyncProgressCard(
                                  isSyncing: _isSyncing,
                                  syncProgress: _syncProgress,
                                  totalTracksSynced: _totalTracksSynced,
                                  estimatedTotalTracks: _estimatedTotalTracks,
                                  currentSyncingLibrary: _currentSyncingLibrary,
                                  syncStatus: null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_hasCompletedSetup) ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Sync Complete!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Your music library is ready. Click "Get Started" to begin enjoying your music!',
                                              style: TextStyle(
                                                color: Colors.grey[300],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (!_hasCompletedSetup)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSyncing || !_hasSelectedLibraries()
                                        ? null
                                        : _syncLibrary,
                                    icon: _isSyncing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.sync),
                                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Library'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      disabledBackgroundColor: Colors.grey[800],
                                      disabledForegroundColor: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (!_hasCompletedSetup && !_hasSelectedLibraries())
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Please select at least one library first',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_hasCompletedSetup)
                        TextButton(
                          onPressed: _isSyncing ? null : _handleComplete,
                          child: const Text('Skip for Now'),
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _handleComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasCompletedSetup ? Colors.green : _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text(_hasCompletedSetup ? 'Get Started →' : 'Get Started'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepsIndicator() {
    return Row(
      children: [
        _buildStepIndicatorItem(
          number: 1,
          label: 'Select Libraries',
          isActive: true,
          isCompleted: _hasSelectedLibraries(),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[800],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepIndicatorItem(
          number: 2,
          label: 'Sync',
          isActive: _hasSelectedLibraries(),
          isCompleted: _hasCompletedSetup,
        ),
      ],
    );
  }

  Widget _buildStepIndicatorItem({
    required int number,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green
                : isActive
                    ? _primaryColor
                    : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
