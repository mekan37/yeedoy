import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/colors.dart';
import 'panel_icon.dart';

enum PanelActionButtonVariant { primary, secondary, neutral, ghost, danger }

class PanelActionButton extends StatelessWidget {
  const PanelActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.variant = PanelActionButtonVariant.neutral,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;
  final PanelActionButtonVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final colors = _colorsForVariant(variant);
    final iconWidget = _ActionIcon(
      icon: icon,
      color: colors.foreground,
      size: compact || label == null ? 15 : 14,
    );

    if (compact || label == null) {
      return Semantics(
        button: true,
        label: label ?? tooltip,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
            fixedSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            foregroundColor: colors.foreground,
            backgroundColor: colors.background,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius12),
            ),
          ),
          icon: iconWidget,
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      waitDuration: Duration.zero,
      child: Semantics(
        button: true,
        label: label ?? tooltip,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(tokens.minHitTarget, tokens.minHitTarget),
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space12,
              vertical: tokens.space8,
            ),
            foregroundColor: colors.foreground,
            backgroundColor: colors.background,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius12),
            ),
          ),
          icon: iconWidget,
          label: Text(
            label!,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  static _PanelActionColors _colorsForVariant(PanelActionButtonVariant variant) {
    return switch (variant) {
      PanelActionButtonVariant.primary => const _PanelActionColors(
        foreground: Colors.white,
        background: AppColors.primary,
        border: AppColors.primary,
      ),
      PanelActionButtonVariant.secondary => const _PanelActionColors(
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        border: AppColors.borderStrong,
      ),
      PanelActionButtonVariant.ghost => const _PanelActionColors(
        foreground: AppColors.textStrong,
        background: Colors.transparent,
        border: Colors.transparent,
      ),
      PanelActionButtonVariant.danger => const _PanelActionColors(
        foreground: AppColors.danger,
        background: Color(0xFFFFF1F1),
        border: Color(0xFFF4CACA),
      ),
      PanelActionButtonVariant.neutral => const _PanelActionColors(
        foreground: AppColors.textStrong,
        background: AppColors.card,
        border: AppColors.border,
      ),
    };
  }
}

class _PanelActionColors {
  const _PanelActionColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PanelIcon(
      icon: icon,
      color: color,
      materialSize: size,
      awesomeSize: size,
    );
  }
}
