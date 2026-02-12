import 'package:flutter/material.dart';

/// A custom scroll behavior that applies consistent scrollbar styling across the app.
/// Use this in MaterialApp's scrollBehavior to apply globally.
class StyledScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.grey[600]),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(8),
        ),
      ),
      child: Scrollbar(
        controller: details.controller,
        thumbVisibility: true,
        child: child,
      ),
    );
  }
}

/// A reusable scrollbar widget with consistent styling across the app.
/// Provides a light grey scrollbar that's always visible on the right side.
/// Note: If using StyledScrollBehavior globally, this widget may not be needed.
class StyledScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;

  const StyledScrollbar({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.grey[600]),
          trackColor: WidgetStateProperty.all(Colors.transparent),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(8),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: child,
      ),
    );
  }
}
