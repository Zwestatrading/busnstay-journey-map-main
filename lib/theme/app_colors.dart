import 'package:flutter/material.dart';

/// BusNStay brand color palette — dark / solid yellow transport theme
class AppColors {
  AppColors._();

  // ── Primary: Dark Solid Yellow ──
  static const Color primary = Color(0xFFD4A017);      // dark goldenrod
  static const Color primaryDark = Color(0xFFB8860B);   // deep dark yellow
  static const Color primaryLight = Color(0xFFE8C547);  // lighter gold

  // ── Secondary: Amber / Darker Yellow ──
  static const Color accent = Color(0xFFC49000);        // dark amber yellow
  static const Color accentDark = Color(0xFF9E7700);    // very dark yellow
  static const Color accentLight = Color(0xFFDDA51F);   // warm yellow

  // ── Tertiary: Orange-gold ──
  static const Color emerald = Color(0xFFE6A817);

  // ── Neutrals: Dark warm tones ──
  static const Color darkBg = Color(0xFF1A1400);        // near-black warm
  static const Color darkSurface = Color(0xFF231B05);   // dark brown-yellow
  static const Color darkCard = Color(0xFF2A2008);      // dark card warm
  static const Color lightBg = Color(0xFFFFF8E1);       // cream
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ── Utility ──
  static const Color gold = Color(0xFFFFD700);
  static const Color navy = Color(0xFF111827);
  static const Color teal = Color(0xFFD4A017);
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
    colors: [Color(0xFF1A1400), Color(0xFF3D2E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mapOverlayGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0xCC1A1400)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
