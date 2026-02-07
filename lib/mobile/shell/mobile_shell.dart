import 'package:flutter/material.dart';
import '../../core/services/audio_player_service.dart';
import '../features/home/mobile_home_page.dart';
import '../features/search/mobile_search_page.dart';
import '../features/library/mobile_library_page.dart';
import '../features/create/mobile_create_page.dart';
import '../features/artist/mobile_artists_list_page.dart';
import '../features/artist/mobile_artist_page.dart';
import '../features/playlists/mobile_playlists_page.dart';
import 'widgets/profile_drawer.dart';
import '../features/player/widgets/mobile_mini_player.dart';
import '../features/player/mobile_player_page.dart';

/// The main shell for the mobile app.
/// Provides a bottom navigation bar with four tabs.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  // Navigator keys for each tab to enable nested navigation
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _searchNavigatorKey = GlobalKey<NavigatorState>();
  final _libraryNavigatorKey = GlobalKey<NavigatorState>();
  final _createNavigatorKey = GlobalKey<NavigatorState>();

  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _navigatorKeys = [
      _homeNavigatorKey,
      _searchNavigatorKey,
      _libraryNavigatorKey,
      _createNavigatorKey,
    ];

    _pages = [
      // Home Tab with Nested Navigator
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => MobileHomePage(
            audioPlayerService: _audioPlayerService,
            onNavigateToLibrary: () => setState(() => _currentIndex = 2),
            onNavigateToPlaylists: () {
              // Ensure we are on the Home tab
              if (_currentIndex != 0) setState(() => _currentIndex = 0);
              // Push Playlists page onto the Home nested navigator
              _homeNavigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => MobilePlaylistsPage(
                    audioPlayerService: _audioPlayerService,
                  ),
                ),
              );
            },
            onNavigateToArtists: () {
              // Ensure we are on the Home tab
              if (_currentIndex != 0) setState(() => _currentIndex = 0);
              // Push Artist List page onto the Home nested navigator
              _homeNavigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => MobileArtistsListPage(
                    audioPlayerService: _audioPlayerService,
                  ),
                ),
              );
            },
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
      ),
      // Search Tab
      Navigator(
        key: _searchNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const MobileSearchPage(),
        ),
      ),
      // Library Tab
      Navigator(
        key: _libraryNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => MobileLibraryPage(
            audioPlayerService: _audioPlayerService,
          ),
        ),
      ),
      // Create Tab
      Navigator(
        key: _createNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const MobileCreatePage(),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }

  void _showFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MobilePlayerPage(
        audioPlayerService: _audioPlayerService,
        onArtistTap: (artistId, artistName) {
          Navigator.pop(context); // Close the player
          // Navigate to the artist page within the Home tab
          if (_currentIndex != 0) setState(() => _currentIndex = 0);
          _homeNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => MobileArtistPage(
                artistId: artistId,
                artistName: artistName,
                audioPlayerService: _audioPlayerService,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if the current navigator can pop. If it can, pop it and don't exit the app.
        final canPop = await _navigatorKeys[_currentIndex].currentState?.maybePop() ?? false;
        return !canPop;
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        drawer: const ProfileDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini Player
            ListenableBuilder(
              listenable: _audioPlayerService,
              builder: (context, _) {
                if (_audioPlayerService.currentTrack == null) {
                  return const SizedBox.shrink();
                }
                return MobileMiniPlayer(
                  audioPlayerService: _audioPlayerService,
                  onTap: _showFullPlayer,
                );
              },
            ),
            // Navigation Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF282828),
                    width: 0.5,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: const Color(0xFF121212).withOpacity(0.90),
                indicatorColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  // If tapping the same tab, pop to the first route
                  if (_currentIndex == index) {
                    _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
                  }
                  setState(() => _currentIndex = index);
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.home, color: Colors.white),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.search, color: Colors.white),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined, color: Colors.grey),
                    selectedIcon: Icon(Icons.library_music, color: Colors.white),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add_circle_outline, color: Colors.grey),
                    selectedIcon: Icon(Icons.add_circle, color: Colors.white),
                    label: 'Create',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
