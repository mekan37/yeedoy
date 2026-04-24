import 'package:flutter/material.dart';

import 'colors.dart';

/// Dark-mode semantic color map for Yeedoy.
/// Mirrors [AppColors] slot-for-slot; use [AppDarkColors] in
/// [buildDarkAppTheme] and [buildDarkPanelTheme].
///
/// Source palette decisions:
///   - Background: near-black with a warm, slate-tinted hue (#0F111A)
///   - Surface: slightly lighter card (#1A1D2B)
///   - Brand primary stays #7F1D1D; it reads well on dark surfaces at this
///     saturation and maintains Yeedoy identity.
///   - Text: near-white (#E8EAF0) for body, full-white for strong headings.
class AppDarkColors {
  // Brand (unchanged — reads well on dark)
  static const primary = AppPalette.primary;
  static const primarySoft = Color(0xFF3B1515); // darkened soft red
  static const primaryStrong = AppPalette.accent;
  static const primaryDeep = AppPalette.wine;
  static const onPrimary = Color(0xFFFFFFFF);

  // Text
  static const text = Color(0xFFCBD0D9);
  static const textStrong = Color(0xFFF0F2F6);
  static const muted = Color(0xFF7B8696);

  // Surfaces
  static const bg = Color(0xFF0F111A);
  static const card = Color(0xFF1A1D2B);
  static const cardAlt = Color(0xFF1E2130);
  static const border = Color(0xFF2D3148);
  static const borderStrong = Color(0xFF3C4160);
  static const shadow = Color(0x33000000);
  static const header = AppPalette.primary;
  static const headerAccent = AppPalette.accent;
  static const slate = Color(0xFFABB3C2); // legacy alias

  // Status (slightly adjusted for dark background legibility)
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const star = AppPalette.star;
  static const starOff = Color(0xFF3A3D52);
}
