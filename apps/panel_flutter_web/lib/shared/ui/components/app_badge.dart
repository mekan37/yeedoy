import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/app_tokens.dart';

enum AppBadgeTone { neutral, success, warning, danger, info }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.semanticLabel,
  });

  final String label;
  final AppBadgeTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, borderColor) = _palette(tone);
    final tokens = AppTokens.of(context);
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.minHitTarget),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _palette(AppBadgeTone tone) {
    switch (tone) {
      case AppBadgeTone.success:
        return (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.14),
          AppColors.success.withValues(alpha: 0.4),
        );
      case AppBadgeTone.warning:
        return (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.14),
          AppColors.warning.withValues(alpha: 0.4),
        );
      case AppBadgeTone.danger:
        return (
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.14),
          AppColors.danger.withValues(alpha: 0.4),
        );
      case AppBadgeTone.info:
        return (
          AppColors.info,
          AppColors.info.withValues(alpha: 0.14),
          AppColors.info.withValues(alpha: 0.4),
        );
      case AppBadgeTone.neutral:
        return (
          AppColors.textStrong,
          AppColors.cardAlt,
          AppColors.borderStrong,
        );
    }
  }
}
