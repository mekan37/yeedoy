import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
    this.compact = false,
    this.semanticLabel,
    this.leading,
  });

  final String label;
  final Color? color;
  final bool filled;
  final bool compact;
  final String? semanticLabel;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final useColor = color ?? AppColors.textStrong;
    final hPad = compact ? tokens.space8 : tokens.space12;
    final vPad = compact ? 3.0 : 6.0;
    final textWidget = Text(
      label,
      style: TextStyle(
        color: useColor,
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w800,
      ),
    );
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        constraints: compact
            ? null
            : BoxConstraints(minHeight: tokens.minHitTarget),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: filled ? useColor.withValues(alpha: 0.14) : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(tokens.radius24),
          border: Border.all(
            color: filled ? useColor.withValues(alpha: 0.35) : AppColors.border,
          ),
        ),
        child: leading == null
            ? Center(child: textWidget)
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading!,
                  const SizedBox(width: 4),
                  textWidget,
                ],
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

