import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Material Design 3 theme configuration for light and dark modes
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.teal,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.red),
        ),
      ),

      // Text theme with Fira Sans
      textTheme: GoogleFonts.firaSansTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.firaSans(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.firaSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodyMedium: GoogleFonts.firaSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.firaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelMedium: GoogleFonts.firaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.neutral600,
        size: 20,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.white,
        secondary: AppColorsDark.teal,
        onSecondary: AppColorsDark.white,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        error: AppColorsDark.red,
        onError: AppColorsDark.white,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.white,
        elevation: 0,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColorsDark.border),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: BorderSide(color: AppColorsDark.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.linkColor, // Teal for links
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColorsDark.red),
        ),
      ),

      // Text theme with Fira Sans
      textTheme: GoogleFonts.firaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.firaSans(fontSize: 32, fontWeight: FontWeight.w700, color: AppColorsDark.textPrimary),
        displayMedium: GoogleFonts.firaSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColorsDark.textPrimary),
        titleLarge: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
        titleMedium: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
        bodyLarge: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.w400, color: AppColorsDark.textSecondary),
        bodyMedium: GoogleFonts.firaSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColorsDark.textSecondary),
        labelLarge: GoogleFonts.firaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColorsDark.textSecondary),
        labelMedium: GoogleFonts.firaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColorsDark.textMuted),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColorsDark.neutral400,
        size: 20,
      ),
    );
  }
}
