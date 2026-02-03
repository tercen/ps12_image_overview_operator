import 'package:flutter/material.dart';

/// Dark theme color palette
///
/// Reference: _local/tercen-style/claude-skills/visual/visual-style-dark.md
class AppColorsDark {
  // Primary (Dark Theme) - Violet accent
  static const Color primary = Color(0xFF6D28D9);
  static const Color primaryDarker = Color(0xFF5B21B6);
  static const Color primaryLighter = Color(0xFF7C3AED);
  static const Color primarySurface = Color(0x266D28D9); // 15% opacity
  static const Color primaryBg = Color(0x1A6D28D9); // 10% opacity

  // Links (Dark Theme) - Teal for distinction from buttons
  static const Color linkColor = Color(0xFF2DD4BF);

  // Accent colors (same as light theme)
  static const Color green = Color(0xFF047857);
  static const Color greenLight = Color(0xFFD1FAE5);
  static const Color teal = Color(0xFF0E7490);
  static const Color tealLight = Color(0xFFCFFAFE);
  static const Color amber = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color red = Color(0xFFB91C1C);
  static const Color redLight = Color(0xFFFEE2E2);

  // Dark neutrals (inverted hierarchy)
  static const Color neutral900 = Color(0xFF0F1419); // Darker than light neutral-900
  static const Color neutral800 = Color(0xFF1A1F26);
  static const Color neutral700 = Color(0xFF272E38);
  static const Color neutral600 = Color(0xFF3E4753);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic colors (dark theme)
  static const Color textPrimary = neutral100;
  static const Color textSecondary = neutral300;
  static const Color textTertiary = neutral400;
  static const Color textMuted = neutral500;
  static const Color textDisabled = neutral600;

  static const Color surface = neutral800;
  static const Color surfaceElevated = neutral700;
  static const Color background = neutral900;
  static const Color border = neutral700;
}
