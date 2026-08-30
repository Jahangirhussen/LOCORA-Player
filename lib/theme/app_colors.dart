import 'package:flutter/material.dart';

/// Black-core palette. Single source of truth for color values.
/// Change values here to re-theme the whole app.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceSecondary = Color(0xFF111111);
  static const Color card = Color(0xFF161616);
  static const Color cardElevated = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF707070);

  // Accent — single consistent accent color used across the whole app
  static const Color accent = Color(0xFF3D8BFD);
  static const Color accentMuted = Color(0x333D8BFD);

  // Semantic
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF2ECC71);
}
