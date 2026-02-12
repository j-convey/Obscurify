/// Centralized sizing constants for the side panel.
///
/// Change these values once to affect the entire side panel behaviour.
class SidePanelConstants {
  SidePanelConstants._();

  /// Width of the collapsed (icon-only) state as a fraction of screen width.
  /// Approximately 90-105px on most screens.
  static const double collapsedWidthFraction = 0.0675;

  /// Smallest width the panel can be while still in expanded mode.
  /// Dragging below this snaps to [collapsedWidthFraction].
  /// Approximately 320px on most screens.
  static const double minExpandedWidthFraction = 0.22;

  /// Maximum width as a fraction of screen width (fully expanded).
  /// Approximately 450px on most screens.
  static const double maxExpandedWidthFraction = 0.30;

  /// Starting width as a fraction of screen width.
  /// Approximately 280px on most screens.
  static const double initialWidthFraction = 0.19;
}
