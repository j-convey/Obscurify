import 'package:flutter/material.dart';

/// Header row displayed at the top of the [SidePanel].
///
/// Shows a library toggle button and a create ("+") button.
/// When [isCollapsed] is true (panel at minimum width), the library button
/// renders as a compact icon. When expanded it shows "Your Library" with a
/// collapse arrow.
class SidePanelHeader extends StatelessWidget {
  /// Whether the panel is at its minimum (collapsed) width.
  final bool isCollapsed;

  /// Called when the user taps the library / collapse button.
  final VoidCallback onLibraryToggle;

  /// Called when the user taps the "+" (create) button.
  final VoidCallback? onCreateTap;

  const SidePanelHeader({
    super.key,
    required this.isCollapsed,
    required this.onLibraryToggle,
    this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 0 : 12,
        vertical: 8,
      ),
      child: isCollapsed ? _buildCollapsedHeader() : _buildExpandedHeader(),
    );
  }

  // ── Collapsed (icon-only) ──────────────────────────────────────────────

  Widget _buildCollapsedHeader() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Library icon button - full width clickable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onLibraryToggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Tooltip(
                  message: 'Open Your Library',
                  child: Icon(
                    Icons.library_books_outlined,
                    size: 28,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Create button - full width clickable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCreateTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Tooltip(
                  message: 'Create a playlist, folder, or Jam',
                  child: Icon(
                    Icons.add,
                    size: 28,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Expanded (label + icons) ───────────────────────────────────────────

  Widget _buildExpandedHeader() {
    return Row(
      children: [
        // Library label with collapse arrow
        Expanded(
          child: Tooltip(
            message: 'Collapse Your Library',
            child: InkWell(
              onTap: onLibraryToggle,
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 22, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Your Library',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Create button
        Tooltip(
          message: 'Create a playlist, folder, or Jam',
          child: IconButton(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 22),
            color: Colors.grey[400],
            hoverColor: Colors.white10,
          ),
        ),
      ],
    );
  }
}
