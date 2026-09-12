import 'package:flutter/material.dart';

/// Centralized color constants for the Tiga Angkatan app.
///
/// Refactored to a modern high-contrast Black & Vibrant Green design system.
class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF111111); // Solid Black
  static const Color primaryTeal = primary; // keeping alias to prevent breaking existing code
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF22C55E); // Vibrant Green
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFF22C55E);

  // ── Backgrounds & Surfaces ───────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA); // Very light grey/white
  static const Color pageBackground = background; 
  static const Color surface = Color(0xFFFFFFFF);

  // ── Foreground / Text ────────────────────────────────────────────
  static const Color foreground = Color(0xFF111111);
  static const Color darkText = foreground; 

  static const Color mutedForeground = Color(0xFF6B7280);
  static const Color mutedText = mutedForeground; 

  // ── Cards ────────────────────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBackground = card;
  static const Color cardBorder = Color(0xFFF3F4F6); // subtle border
  static const Color lightTealBorder = cardBorder; // keeping alias

  // ── Muted / Tinted Backgrounds ───────────────────────────────────
  static const Color muted = Color(0xFFF3F4F6); // Grey 100
  static const Color tealBackgrounds = muted; // keeping alias

  // ── Semantic Colors ──────────────────────────────────────────────
  static const Color successGreen = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color destructive = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFFB91C1C);

  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1D4ED8);

  // ── AI Business Insight (Premium Dark Theme) ─────────────────────
  static const Color forestTeal = Color(0xFF1F2937); // Dark grey
  static const Color forestTealDark = Color(0xFF111111); // Black
  static const Color forestTealBorder = Color(0xFF374151); 
  static const Color mintAccent = Color(0xFF22C55E); // Green
  static const Color mintText = Color(0xFFF0FDF4);
  static const Color terracotta = Color(0xFFF59E0B);
  static const Color terracottaDark = Color(0xFFB45309);
  static const Color bronzeGold = Color(0xFFF59E0B);
  static const Color neutralSubCard = Color(0xFFF9FAFB);
  static const Color neutralSubBorder = Color(0xFFE5E7EB);

  // ── Border / Divider ─────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x0A111111);
}
