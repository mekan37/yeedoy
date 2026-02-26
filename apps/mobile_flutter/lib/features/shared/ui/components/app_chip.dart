import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
    this.semanticLabel,
  });

  final String label;
  final Color? color;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final useColor = color ?? AppColors.textStrong;
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.minHitTarget),
        padding: EdgeInsets.symmetric(horizontal: tokens.space12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? useColor.withValues(alpha: 0.14) : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(tokens.radius24),
          border: Border.all(
            color: filled ? useColor.withValues(alpha: 0.35) : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: useColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  static AppChip status({
    required String label,
    required AppChipStatus status,
  }) {
    switch (status) {
      case AppChipStatus.success:
        return AppChip(label: label, color: AppColors.success, filled: true);
      case AppChipStatus.warning:
        return AppChip(label: label, color: AppColors.warning, filled: true);
      case AppChipStatus.danger:
        return AppChip(label: label, color: AppColors.danger, filled: true);
      case AppChipStatus.info:
        return AppChip(label: label, color: AppColors.info, filled: true);
    }
  }
}

enum AppChipStatus { success, warning, danger, info }

