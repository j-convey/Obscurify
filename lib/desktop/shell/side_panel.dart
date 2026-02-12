import 'package:flutter/material.dart';
import 'package:obscurify/core/services/audio_player_service.dart';
import 'side_panel_constants.dart';
import 'side_panel_header.dart';
import 'side_panel_playlist_list.dart';

/// A resizable left-hand side panel (similar to Spotify's sidebar).
///
/// The panel can be dragged to resize between the min and max widths
/// defined in [SidePanelConstants]. A thin drag handle on the right edge
/// allows the user to adjust the width.
class SidePanel extends StatefulWidget {
  final void Function(Widget)? onNavigate;
  final AudioPlayerService? audioPlayerService;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const SidePanel({
    super.key,
    this.onNavigate,
    this.audioPlayerService,
    this.onHomeTap,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  late double _currentWidth;
  bool _isHandleHovered = false;
  bool _isDragging = false;

  /// Accumulates drag distance when dragging out from collapsed state.
  double _dragAccumulator = 0;

  @override
  void initState() {
    super.initState();
    // _currentWidth is resolved in didChangeDependencies on the first layout.
    _currentWidth = -1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentWidth < 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      _currentWidth = screenWidth * SidePanelConstants.initialWidthFraction;
    }
  }

  /// Whether the panel is in its collapsed (icon-only) state.
  bool _isCollapsed(double collapsedWidth) {
    return _currentWidth <= collapsedWidth + 2;
  }

  /// Toggle between collapsed and the minimum expanded width.
  void _toggleCollapse(
      double collapsedWidth, double minExpanded, double maxExpanded) {
    setState(() {
      if (_isCollapsed(collapsedWidth)) {
        _currentWidth = minExpanded;
      } else {
        _currentWidth = collapsedWidth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final collapsedWidth =
        screenWidth * SidePanelConstants.collapsedWidthFraction;
    final minExpanded =
        screenWidth * SidePanelConstants.minExpandedWidthFraction;
    final maxExpanded =
        screenWidth * SidePanelConstants.maxExpandedWidthFraction;

    // Ensure width is either collapsed or within the expanded range.
    if (!_isCollapsed(collapsedWidth)) {
      _currentWidth = _currentWidth.clamp(minExpanded, maxExpanded);
    } else {
      _currentWidth = collapsedWidth;
    }

    final collapsed = _isCollapsed(collapsedWidth);

    return SizedBox(
      width: _currentWidth,
      child: Stack(
        children: [
          // Panel body
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SidePanelHeader(
                  isCollapsed: collapsed,
                  onLibraryToggle: () =>
                      _toggleCollapse(collapsedWidth, minExpanded, maxExpanded),
                  onCreateTap: () {
                    // TODO: Create playlist / folder / Jam
                  },
                ),
                // Playlist artwork list
                Expanded(
                  child: SidePanelPlaylistList(
                    isCollapsed: collapsed,
                    onNavigate: widget.onNavigate,
                    audioPlayerService: widget.audioPlayerService,
                    onHomeTap: widget.onHomeTap,
                    onSettingsTap: widget.onSettingsTap,
                    onProfileTap: widget.onProfileTap,
                  ),
                ),
              ],
            ),
          ),

          // Drag handle on the right edge
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _isHandleHovered = true),
              onExit: (_) {
                if (!_isDragging) {
                  setState(() => _isHandleHovered = false);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) {
                  setState(() {
                    _isDragging = true;
                    _dragAccumulator = 0;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    if (_isCollapsed(collapsedWidth)) {
                      // Accumulate rightward drag; once past threshold snap open
                      _dragAccumulator += details.delta.dx;
                      if (_dragAccumulator >
                          (minExpanded - collapsedWidth) * 0.35) {
                        _currentWidth = minExpanded;
                        _dragAccumulator = 0;
                      }
                      // Otherwise stay collapsed
                    } else {
                      final raw = _currentWidth + details.delta.dx;
                      if (raw < minExpanded) {
                        _currentWidth = collapsedWidth;
                      } else {
                        _currentWidth =
                            raw.clamp(minExpanded, maxExpanded);
                      }
                    }
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() {
                    _isDragging = false;
                    _isHandleHovered = false;
                  });
                },
                // Invisible hit-target wider than the visual border for easy grabbing
                child: const SizedBox(width: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
