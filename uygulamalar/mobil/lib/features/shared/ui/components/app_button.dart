import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.fullWidth = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticLabel;
  final bool fullWidth;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              SizedBox(width: tokens.space8),
              Text(label),
            ],
          );
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
        ),
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
        ),
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        style: TextButton.styleFrom(
          minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
        ),
        onPressed: onPressed,
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: AppColors.onPrimary,
          minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
        ),
        onPressed: onPressed,
        child: child,
      ),
    };

    final wrapped = Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: button,
    );
    if (!fullWidth) return wrapped;
    return SizedBox(width: double.infinity, child: wrapped);
  }
}

