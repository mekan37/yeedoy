import 'package:flutter/material.dart';
import 'renkler.dart';

TextTheme buildAppTextTheme(TextTheme base) {
  return base.copyWith(
    titleLarge: const TextStyle(
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: AppColors.textStrong,
    ),
    titleMedium: const TextStyle(
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: AppColors.textStrong,
    ),
    titleSmall: const TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: AppColors.textStrong,
    ),
    bodyLarge: const TextStyle(
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    bodySmall: const TextStyle(
      fontSize: 11,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    ),
  );
}

