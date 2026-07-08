import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

TextTheme buildAppTextTheme(TextTheme base) {
  final outfitFamily = GoogleFonts.outfit().fontFamily;
  return base.copyWith(
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: outfitFamily,
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: AppColors.textStrong,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: outfitFamily,
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: AppColors.textStrong,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: outfitFamily,
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: AppColors.textStrong,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 11,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    ),
  );
}
