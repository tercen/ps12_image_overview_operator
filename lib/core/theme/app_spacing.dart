/// Spacing constants following 8px base grid
///
/// Reference: _local/tercen-style/claude-skills/foundation/design-tokens.md
class AppSpacing {
  // Spacing scale (8px base grid)
  static const double xs = 4.0;   // Tight contexts, grid gaps
  static const double sm = 8.0;   // Related elements
  static const double md = 16.0;  // Component padding
  static const double lg = 24.0;  // Section spacing
  static const double xl = 32.0;  // Page margins
  static const double xxl = 48.0; // Major sections

  // Component dimensions
  static const double controlHeightSmall = 28.0;
  static const double controlHeightDefault = 36.0;
  static const double controlHeightLarge = 44.0;

  // Panel dimensions
  static const double panelWidth = 280.0;
  static const double panelMinWidth = 280.0;
  static const double panelMaxWidth = 400.0;
  static const double panelCollapsedWidth = 48.0;

  // Header dimensions
  static const double headerHeight = 48.0;
  static const double topBarHeight = 48.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  // Grid cell sizing (PamGene specific)
  static const double gridCellAspectRatio = 270.0 / 200.0; // 1.35:1
  static const double gridGap = 4.0; // Equal horizontal and vertical
}
