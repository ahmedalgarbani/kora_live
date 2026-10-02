import 'package:flutter/material.dart';

/// Single source of truth for the app palette. Screens and widgets must use
/// these tokens (or `Theme.of(context)`) rather than raw `Colors.*` values so
/// the design stays consistent.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color background = Color(0xFF070A13);
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceHigh = Color(0xFF1E293B);
  static const Color cardFill = Color(0x991E293B); // Slate @ 60%
  static const Color cardBorder = Color(0x3394A3B8); // Light slate @ 20%

  // Brand
  static const Color primary = Color(0xFFFF3B5C); // "Live" red
  static const Color primaryDark = Color(0xFFD61F45);
  static const Color accent = Color(0xFF38BDF8); // Info / channels

  // Semantic
  static const Color live = primary;
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color favorite = Color(0xFFFBBF24);

  // Text & icons
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF3B0A1E)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient scrimGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}
