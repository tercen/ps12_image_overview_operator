import 'package:flutter/material.dart';

/// Dark theme color palette
///
/// Reference: _local/tercen-style/claude-skills/visual/visual-style-dark.md
class AppColorsDark {
  // Primary (Dark Theme) - Teal accent
  static const Color primary = Color(0xFF14B8A6); // teal-500
  static const Color primaryDarker = Color(0xFF0D9488); // teal-600
  static const Color primaryLighter = Color(0xFF2DD4BF); // teal-400
  static const Color primarySurface = Color(0xFF153D47); // teal tinted surface
  static const Color primaryBg = Color(0xFF122E35); // teal tinted bg

  // Links (Dark Theme) - Blue for distinction from primary
  static const Color linkColor = Color(0xFF60A5FA); // blue-400

  // Accent colors (adjusted for dark theme)
  static const Color green = Color(0xFF10B981); // green-light for dark
  static const Color greenLight = Color(0x26047857); // rgba(4, 120, 87, 0.15)
  static const Color teal = Color(0xFF0E7490);
  static const Color tealLight = Color(0xFFCFFAFE);
  static const Color amber = Color(0xFFFBBF24); // amber-light for dark
  static const Color amberLight = Color(0x26B45309); // rgba(180, 83, 9, 0.15)
  static const Color red = Color(0xFFF87171); // red-light for dark
  static const Color redLight = Color(0x26B91C1C); // rgba(185, 28, 28, 0.15)
  static const Color blue = Color(0xFF60A5FA); // blue for dark
  static const Color blueLight = Color(0x2660A5FA); // rgba(96, 165, 250, 0.15)

  // Neutrals (standard values from design-tokens.md)
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic colors (dark theme)
  static const Color textPrimary = neutral50; // #F9FAFB
  static const Color textSecondary = neutral200; // #E5E7EB
  static const Color textTertiary = neutral400; // #9CA3AF
  static const Color textMuted = neutral500; // #6B7280
  static const Color textDisabled = neutral600; // #4B5563

  static const Color surface = neutral900; // #111827
  static const Color surfaceElevated = neutral800; // #1F2937
  static const Color background = Color(0xFF0A0A0A); // darker than neutral-900
  static const Color border = neutral800; // #1F2937 for panels, neutral-700 for subtle borders
  static const Color borderSubtle = neutral700; // #374151
}
