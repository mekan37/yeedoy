import 'package:flutter/material.dart';

/// Base palette (raw colors). Keep these stable; use AppColors for semantics.
class AppPalette {
  // Deep red + slate base
  static const primary = Color(0xFF7F1D1D);
  static const accent = Color(0xFFDC2626);
  static const wine = Color(0xFF5C1515);

  static const slate900 = Color(0xFF111827);
  static const slate700 = Color(0xFF374151);
  static const slate600 = Color(0xFF4B5563);
  static const slate500 = Color(0xFF6B7280);

  static const bg = Color(0xFFF9FAFB);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const shadow = Color(0x1A0F172A);

  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFB91C1C);
  static const info = Color(0xFF1D4ED8);

  static const star = Color(0xFFFBBF24);
  static const starOff = Color(0xFFD1D5DB);
}

class AppColors {
  // Brand
  static const primary = AppPalette.primary;
  static const primarySoft = Color(0xFFF9E7E7);
  static const primaryStrong = AppPalette.accent;
  static const primaryDeep = AppPalette.wine;
  static const onPrimary = Color(0xFFFFFFFF);

  // Text
  static const slate = Color(0xFF434D57); // legacy alias (used widely)
  static const text = slate;
  static const textStrong = AppPalette.slate900;
  static const muted = AppPalette.slate500;

  // Surfaces
  static const bg = AppPalette.bg;
  static const card = AppPalette.white;
  static const cardAlt = Color(0xFFFDF8F7);
  static const border = AppPalette.border;
  static const borderStrong = Color(0xFFD1D5DB);
  static const shadow = AppPalette.shadow;
  static const header = AppPalette.primary;
  static const headerAccent = AppPalette.accent;

  // Status
  static const success = AppPalette.success;
  static const warning = AppPalette.warning;
  static const danger = AppPalette.danger;
  static const info = AppPalette.info;

  static const star = AppPalette.star;
  static const starOff = AppPalette.starOff;
}
