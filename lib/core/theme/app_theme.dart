import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyberEmerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.cyberEmerald,
      secondary: AppColors.neonBlue,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // =========================================================================
      // Font
      // =========================================================================

      fontFamily: 'Tajawal',

      // =========================================================================
      // Background
      // =========================================================================

      scaffoldBackgroundColor: AppColors.background,

      // =========================================================================
      // App Bar
      // =========================================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      // =========================================================================
      // Text Theme
      // =========================================================================

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textMuted,
        ),
      ),

      // =========================================================================
      // Cards
      // =========================================================================

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColors.glassBorder,
          ),
        ),
      ),

      // =========================================================================
      // Inputs
      // =========================================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.glassBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.glassBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.cyberEmerald,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppColors.textMuted,
        ),
      ),

      // =========================================================================
      // Elevated Buttons
      // =========================================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyberEmerald,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // =========================================================================
      // Text Buttons
      // =========================================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyberEmerald,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =========================================================================
      // Dividers
      // =========================================================================

      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
      ),
    );
  }
}
