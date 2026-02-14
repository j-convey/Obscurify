import 'package:flutter/material.dart';
import 'obscurify_app_bar.dart';
import 'player_bar.dart';
import 'side_panel.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'package:obscurify/core/services/storage_service.dart';
import 'package:obscurify/core/services/plex/plex_services.dart';
import 'package:obscurify/core/services/plex_connection_resolver.dart';
import 'package:obscurify/core/services/authentication_check_service.dart';
import 'package:obscurify/desktop/features/authentication/presentation/authentication_modal.dart';
import 'package:obscurify/desktop/features/home/home_page.dart';
import 'package:obscurify/desktop/features/settings/settings_page.dart';
import 'package:obscurify/desktop/features/profile/profile_page.dart';

class MainScreen extends StatefulWidget {
  final AudioPlayerService? audioPlayerService;
  final StorageService? storageService;

  const MainScreen({
    super.key,
    this.audioPlayerService,
    this.storageService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Widget _currentPage;
  late final AudioPlayerService _audioPlayerService;
  late final StorageService _storageService;
  late final AuthenticationCheckService _authCheckService;
  final PlexConnectionResolver _resolver = PlexConnectionResolver();
  final List<Widget> _navigationHistory = [];
  int _currentHistoryIndex = -1;
  String? _currentToken;
  String? _currentServerUrl;
  String? _profileImagePath;
  String? _plexProfilePictureUrl;
  Key _sidePanelKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _audioPlayerService = widget.audioPlayerService ?? AudioPlayerService();
    _storageService = widget.storageService ?? StorageService();
    _authCheckService = AuthenticationCheckService(_storageService);
    _loadCredentials();
    _currentPage = HomePage(
      onNavigate: _navigateToPage,
      audioPlayerService: _audioPlayerService,
      storageService: _storageService,
      token: _currentToken,
      serverUrl: _currentServerUrl,
      onHomeTap: _onHomeTap,
      onSettingsTap: _onSettingsTap,
      onProfileTap: _onProfileTap,
    );
    _navigationHistory.add(_currentPage);
    _currentHistoryIndex = 0;
  }

  void _onHomeTap() {
    _navigateToPage(HomePage(
      onNavigate: _navigateToPage,
      audioPlayerService: _audioPlayerService,
      storageService: _storageService,
      token: _currentToken,
      serverUrl: _currentServerUrl,
      onHomeTap: _onHomeTap,
      onSettingsTap: _onSettingsTap,
      onProfileTap: _onProfileTap,
    ));
  }

  void _onSettingsTap() {
    _navigateToPage(SettingsPage(
      onNavigate: _navigateToPage,
      audioPlayerService: _audioPlayerService,
    ));
  }

  void _onProfileTap() {
    _navigateToPage(ProfilePage(storageService: _storageService));
  }

  Future<void> _loadCredentials() async {
    await _resolver.initialise();
    _currentToken = _resolver.userToken;
    
    // Get the selected server connection (handles both owned and shared servers)
    final connection = await _resolver.getSelectedServerConnection();
    _currentServerUrl = connection?.url;
    
    // Load profile picture data
    _profileImagePath = await _storageService.getProfileImagePath();
    _plexProfilePictureUrl = await _storageService.getPlexProfilePictureUrl();
    
    // Update audio player with server URLs and access tokens
    _audioPlayerService.setServerUrls(_resolver.serverUrls);
    _audioPlayerService.setServerAccessTokens(
      await _storageService.getServerAccessTokenMap(),
    );
    
    if (mounted) {
      setState(() {
        _sidePanelKey = UniqueKey(); // Force SidePanel to rebuild
        _currentPage = HomePage(
          onNavigate: _navigateToPage,
          audioPlayerService: _audioPlayerService,
          storageService: _storageService,
          token: _currentToken,
          serverUrl: _currentServerUrl,
          onHomeTap: _onHomeTap,
          onSettingsTap: _onSettingsTap,
          onProfileTap: _onProfileTap,
        );
        _navigationHistory[_currentHistoryIndex] = _currentPage;
      });
    }
  }

  /// Callback when authentication succeeds via modal.
  /// Reloads credentials and updates the UI.
  Future<void> _onAuthenticationSuccess() async {
    await _loadCredentials();
  }

  @override
  void dispose() {
    if (widget.audioPlayerService == null) {
      _audioPlayerService.dispose();
    }
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    setState(() {
      if (_currentHistoryIndex < _navigationHistory.length - 1) {
        _navigationHistory.removeRange(_currentHistoryIndex + 1, _navigationHistory.length);
      }
      _navigationHistory.add(page);
      _currentHistoryIndex = _navigationHistory.length - 1;
      _currentPage = page;
    });
  }

  void _goBack() {
    if (_currentHistoryIndex > 0) {
      setState(() {
        _currentHistoryIndex--;
        _currentPage = _navigationHistory[_currentHistoryIndex];
      });
    }
  }

  void _goForward() {
    if (_currentHistoryIndex < _navigationHistory.length - 1) {
      setState(() {
        _currentHistoryIndex++;
        _currentPage = _navigationHistory[_currentHistoryIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticationModal(
      authCheckService: _authCheckService,
      authService: PlexAuthService(),
      onAuthenticationSuccess: _onAuthenticationSuccess,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            ObscurifyAppBar(
              audioPlayerService: _audioPlayerService,
              currentToken: _currentToken,
              currentServerUrl: _currentServerUrl,
              onNavigate: _navigateToPage,
              onBackPressed: _goBack,
              onForwardPressed: _goForward,
              canGoBack: _currentHistoryIndex > 0,
              canGoForward: _currentHistoryIndex < _navigationHistory.length - 1,
              onHomeTap: _onHomeTap,
              onSettingsTap: _onSettingsTap,
              onProfileTap: _onProfileTap,
              profileImagePath: _profileImagePath,
              plexProfilePictureUrl: _plexProfilePictureUrl,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                child: Row(
                  children: [
                    SidePanel(
                    key: _sidePanelKey,
                    onNavigate: _navigateToPage,
                    audioPlayerService: _audioPlayerService,
                    onHomeTap: _onHomeTap,
                    onSettingsTap: _onSettingsTap,
                    onProfileTap: _onProfileTap,
                  ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: const Color(0xFF121212),
                          child: _currentPage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PlayerBar(
              playerService: _audioPlayerService,
              onNavigate: _navigateToPage,
            ),
          ],
        ),
      ),
    );
  }
}