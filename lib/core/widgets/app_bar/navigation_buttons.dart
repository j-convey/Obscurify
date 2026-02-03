import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onForwardPressed;
  final bool canGoBack;
  final bool canGoForward;

  const NavigationButtons({
    super.key,
    this.onBackPressed,
    this.onForwardPressed,
    this.canGoBack = true,
    this.canGoForward = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            color: canGoBack ? Colors.white : Colors.grey[600],
            padding: EdgeInsets.zero,
            onPressed: canGoBack ? onBackPressed : null,
          ),
        ),
        const SizedBox(width: 8),
        // Forward button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            color: canGoForward ? Colors.white : Colors.grey[600],
            padding: EdgeInsets.zero,
            onPressed: canGoForward ? onForwardPressed : null,
          ),
        ),
      ],
    );
  }
}
