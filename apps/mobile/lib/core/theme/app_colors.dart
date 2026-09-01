import 'package:flutter/material.dart';

/// Centralized color constants for the Tiga Angkatan app.
///
/// Based on a teal/emerald design system matching the reference UI.
/// Uses both semantic names (for theme) and descriptive names (for widgets).
class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryTeal = primary; // alias used in widgets
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF14B8A6);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFF0F766E);

  // ── Backgrounds & Surfaces ───────────────────────────────────────
  static const Color background = Color(0xFFF8FFFE);
  static const Color pageBackground = background; // alias
  static const Color surface = Color(0xFFF1F5F9);

  // ── Foreground / Text ────────────────────────────────────────────
  static const Color foreground = Color(0xFF0F172A);
  static const Color darkText = foreground; // alias

  static const Color mutedForeground = Color(0xFF64748B);
  static const Color mutedText = mutedForeground; // alias

  // ── Cards ────────────────────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBackground = card; // alias
  static const Color cardBorder = Color(0xFFCCFBF1);
  static const Color lightTealBorder = cardBorder; // alias

  // ── Muted / Tinted Backgrounds ───────────────────────────────────
  static const Color muted = Color(0xFFF0FDFA);
  static const Color tealBackgrounds = muted; // alias

  // ── Semantic Colors ──────────────────────────────────────────────
  static const Color successGreen = Color(0xFF10B981);
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

  // ── Border / Divider ─────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0A0F172A);
}
