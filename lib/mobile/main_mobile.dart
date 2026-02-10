import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'shell/mobile_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit for audio playback
  MediaKit.ensureInitialized();

  runApp(const ObscurifyMobileApp());
}

class ObscurifyMobileApp extends StatelessWidget {
  const ObscurifyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obscurify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const MobileShell(),
    );
  }
}
