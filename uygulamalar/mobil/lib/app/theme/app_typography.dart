import 'package:flutter/material.dart';
import 'colors.dart';

extension AppTypographyX on BuildContext {
  TextTheme get appText => Theme.of(this).textTheme;

  TextStyle get titleStyle => appText.titleLarge!.copyWith(
        fontWeight: FontWeight.w900,
        color: AppColors.textStrong,
      );
  /// Sheet / section header: 16sp w900. Use for bottom sheet titles, section labels.
  TextStyle get sectionTitleStyle => appText.titleMedium!.copyWith(
        fontWeight: FontWeight.w900,
        color: AppColors.textStrong,
      );
  TextStyle get subtitleStyle => appText.bodyMedium!.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
      );
  TextStyle get bodyStyle => appText.bodyMedium!;
  TextStyle get captionStyle => appText.bodySmall!.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
      );
}

