import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'shell/main_screen.dart';
import '../core/services/audio_player_service.dart';
import '../core/services/storage_service.dart';
import '../shared/widgets/styled_scrollbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit for audio playback
  MediaKit.ensureInitialized();
  
  // Configure window
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const ObscurifyDesktopApp());
}

class ObscurifyDesktopApp extends StatelessWidget {
  final AudioPlayerService? audioPlayerService;
  final StorageService? storageService;

  const ObscurifyDesktopApp({
    super.key,
    this.audioPlayerService,
    this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obscurify',
      debugShowCheckedModeBanner: false,
      scrollBehavior: StyledScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(
        audioPlayerService: audioPlayerService,
        storageService: storageService,
      ),
    );
  }
}
