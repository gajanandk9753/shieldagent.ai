import 'package:flutter/material.dart';

/// Central color palette for ShieldAgent.
/// Keep every screen pulling from here — no hardcoded hex codes elsewhere.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF15151D);
  static const Color surfaceLight = Color(0xFF1F1F2B);
  static const Color surfaceBorder = Color(0xFF2A2A38);

  // Brand
  static const Color primary = Color(0xFF4C6FFF);
  static const Color primaryDark = Color(0xFF2F4BD0);
  static const Color accent = Color(0xFF00E5C7);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA0A0AC);
  static const Color textMuted = Color(0xFF6B6B78);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF4C6FFF);

  // Role accents (used to visually separate Buyer vs Vendor)
  static const Color buyerAccent = Color(0xFF4C6FFF);
  static const Color vendorAccent = Color(0xFFFF9E4C);
}
