import 'package:flutter/material.dart';

/// BusNStay brand color palette — solid yellow transport theme
class AppColors {
  AppColors._();

  // ── Primary: Solid Yellow ──
  static const Color primary = Color(0xFFFFC107);      // solid amber yellow
  static const Color primaryDark = Color(0xFFE5A800);   // deeper yellow
  static const Color primaryLight = Color(0xFFFFD54F);  // bright lighter yellow

  // ── Secondary: Strong Yellow ──
  static const Color accent = Color(0xFFFFB300);        // vivid amber
  static const Color accentDark = Color(0xFFE59E00);    // warm dark amber
  static const Color accentLight = Color(0xFFFFCA28);   // light amber

  // ── Tertiary: Gold ──
  static const Color emerald = Color(0xFFFFD600);       // pure yellow

  // ── Neutrals ──
  static const Color darkBg = Color(0xFF1A1A1A);        // dark grey (not black)
  static const Color darkSurface = Color(0xFF212121);   // surface dark
  static const Color darkCard = Color(0xFF2C2C2C);      // card dark
  static const Color lightBg = Color(0xFFFFF8E1);       // warm cream
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ── Utility ──
  static const Color gold = Color(0xFFFFD700);
  static const Color navy = Color(0xFF111827);
  static const Color teal = Color(0xFFFFC107);          // maps to primary
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Solid colors (no gradients) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2C2C2C), Color(0xFF2C2C2C)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, primary],
  );

  static const LinearGradient mapOverlayGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0x991A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
