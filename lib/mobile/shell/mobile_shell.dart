import 'package:flutter/material.dart';
import '../../core/services/audio_player_service.dart';
import '../features/home/mobile_home_page.dart';
import '../features/search/mobile_search_page.dart';
import '../features/library/mobile_library_page.dart';
import '../features/create/mobile_create_page.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MobileHomePage(
        audioPlayerService: _audioPlayerService,
        onNavigateToLibrary: () {
          setState(() => _currentIndex = 2);
        },
        onOpenDrawer: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      const MobileSearchPage(),
      MobileLibraryPage(
        audioPlayerService: _audioPlayerService,
      ),
      const MobileCreatePage(),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
