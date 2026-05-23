import 'package:flutter/material.dart';
import 'renkler.dart';

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

  /// Hero / page H1: 32sp w900, tight tracking. Web eşdeğeri: .yd-heading-xl
  TextStyle get headingXl => appText.titleLarge!.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        height: 1.05,
        color: AppColors.textStrong,
      );

  /// Eyebrow label: 11sp w700, loose tracking. Büyük harf widget seviyesinde uygulanır.
  /// Web eşdeğeri: .yd-eyebrow
  TextStyle get eyebrowStyle => appText.bodySmall!.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.muted,
      );
}

