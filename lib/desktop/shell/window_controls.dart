import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          color: Colors.white,
          onPressed: () async {
            await windowManager.minimize();
          },
          tooltip: 'Minimize',
        ),
        IconButton(
          icon: const Icon(Icons.crop_square, size: 14),
          color: Colors.white,
          onPressed: () async {
            bool isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip: 'Maximize',
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          color: Colors.white,
          onPressed: () async {
            await windowManager.close();
          },
          tooltip: 'Close',
        ),
      ],
    );
  }
}
