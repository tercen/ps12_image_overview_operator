import 'package:flutter/material.dart';

/// Light theme color palette
///
/// Reference: _local/tercen-style/claude-skills/visual/visual-style-light.md
class AppColors {
  // Primary (Light Theme)
  static const Color primary = Color(0xFF1E40AF); // blue-800
  static const Color primaryDarker = Color(0xFF1E3A8A); // blue-900
  static const Color primaryLighter = Color(0xFF2563EB); // blue-600
  static const Color primarySurface = Color(0xFFDBEAFE); // blue-100
  static const Color primaryBg = Color(0xFFEFF6FF); // blue-50

  // Accent colors
  static const Color green = Color(0xFF047857);
  static const Color greenLight = Color(0xFFD1FAE5);
  static const Color teal = Color(0xFF0E7490);
  static const Color tealLight = Color(0xFFCFFAFE);
  static const Color amber = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color red = Color(0xFFB91C1C);
  static const Color redLight = Color(0xFFFEE2E2);

  // Neutrals
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

  // Semantic colors
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textTertiary = neutral600;
  static const Color textMuted = neutral500;
  static const Color textDisabled = neutral400;

  static const Color surface = white;
  static const Color surfaceElevated = neutral50;
  static const Color background = neutral100;
  static const Color border = neutral200; // subtle borders
  static const Color borderStrong = neutral300; // standard borders
}
