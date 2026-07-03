import 'package:flutter/material.dart';

class AppColors {
  // Midnight Space Backgrounds
  static const Color backgroundDark = Color(0xFF070A13);
  static const Color backgroundLightDark = Color(0xFF0F172A);
  
  // Card & Panel Surfaces (Glassmorphism Base)
  static const Color cardFill = Color(0x991E293B); // Slate with 60% opacity
  static const Color cardBorder = Color(0x3394A3B8); // Light slate with 20% opacity
  
  // Glowing Neon Sports Accents
  static const Color neonGreen = Color(0xFF00E676); // Match/Live Active
  static const Color neonCyan = Color(0xFF00F2FE); // Primary Cyan Glow
  static const Color neonBlue = Color(0xFF4FACFE); // Secondary Blue Glow
  static const Color favoritePink = Color(0xFFFF2E93); // Favorites Pink/Red
  
  // Neutral Text & Icons
  static const Color textPrimary = Color(0xFFF8FAFC); // Very light gray/white
  static const Color textSecondary = Color(0xFF94A3B8); // Cool gray
  static const Color textMuted = Color(0xFF64748B); // Darker cool gray
  
  // Action Colors
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Linear Gradients
  static const LinearGradient spaceGradient = LinearGradient(
    colors: [backgroundDark, backgroundLightDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonCyan, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient favoriteGradient = LinearGradient(
    colors: [favoritePink, Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
