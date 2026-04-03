import 'package:flutter/material.dart';

/// BusNStay brand color palette — dark yellow / green transport theme
class AppColors {
  AppColors._();

  // ── Primary: Dark Yellow / Goldenrod ──
  static const Color primary = Color(0xFFDAA520);
  static const Color primaryDark = Color(0xFFB8860B);
  static const Color primaryLight = Color(0xFFFFD54F);

  // ── Secondary: Forest Green ──
  static const Color accent = Color(0xFF2E7D32);
  static const Color accentDark = Color(0xFF1B5E20);
  static const Color accentLight = Color(0xFF4CAF50);

  // ── Tertiary: Emerald ──
  static const Color emerald = Color(0xFF10B981);

  // ── Neutrals ──
  static const Color darkBg = Color(0xFF0D1A0D);
  static const Color darkSurface = Color(0xFF142014);
  static const Color darkCard = Color(0xFF1A2E1A);
  static const Color lightBg = Color(0xFFF5F7F0);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ── Utility ──
  static const Color gold = Color(0xFFFFD700);
  static const Color navy = Color(0xFF111827);
  static const Color teal = Color(0xFF14B8A6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D1A0D), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mapOverlayGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0xCC0D1A0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
