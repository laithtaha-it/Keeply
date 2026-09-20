import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand (Facebook Blue Palette)
  // ---------------------------------------------------------------------------

  static const Color cyberEmerald = Color(0xFF1877F2); // Primary Facebook Blue
  static const Color neonBlue = Color(0xFF4267B2); // Secondary Classic Blue

  // ---------------------------------------------------------------------------
  // Background
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF0F2F5); // Main FB Light Background
  static const Color backgroundSecondary =
      Color(0xFFE4E6EB); // Secondary Container/Input Fill

  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------

  static const Color surface =
      Color(0xFFFFFFFF); // White Surface (Cards / Post Box)
  static const Color surfaceLight = Color(0xFFF7F8FA); // Subtle Light Surface

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFF050505); // Dark Primary Text
  static const Color textSecondary = Color(0xFF65676B); // Medium Gray Text
  static const Color textMuted = Color(0xFF8A8D91); // Light Gray/Disabled Text

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF31A24C); // Active/Online Green Status
  static const Color warning = Color(0xFFF7B928); // Warning Yellow/Gold
  static const Color error = Color(0xFFFA383E); // FB Alert/Notification Red
  static const Color info = Color(0xFF1877F2); // Link/Info Blue

  // ---------------------------------------------------------------------------
  // Glass / Borders / Overlays
  // ---------------------------------------------------------------------------

  static const Color glass =
      Color(0xFFFFFFFF); // Pure White Background for Cards/Inputs
  static const Color glassStrong =
      Color(0xFFE4E6EB); // Subtle Divider / Hover Fill
  static const Color glassBorder = Color(0xFFCED0D4); // Light Border Color
}
