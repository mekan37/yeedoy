import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../uygulama/tema/uygulama_tokenleri.dart';

enum AppButtonVariant { primary, secondary, ghost }

enum AppBadgeTone { neutral, info, success, warning, danger }

enum StatusBadgeType { verified, pending, outdated }

enum AppChipStatus { neutral, success, warning, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final AppButtonVariant variant;
  final bool fullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );

    final minHeight = tokens.minHitTarget;
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: AppColors.cardAlt,
          foregroundColor: AppColors.textStrong,
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(0, minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          foregroundColor: AppColors.primary,
        ),
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

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.elevation,
    this.borderColor,
    this.borderWidth = 1,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final double? elevation;
  final Color? borderColor;
  final double borderWidth;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? 18);
    final resolvedColor = color ?? AppColors.card;
    final resolvedElevation = elevation ?? 0;

    return Container(
      margin: margin,
      child: Material(
        color: resolvedColor,
        elevation: resolvedElevation,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: borderWidth,
          ),
        ),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
    this.onTap,
    this.status,
  });

  const AppChip.status({
    super.key,
    required this.label,
    required this.status,
    this.onTap,
  })  : color = null,
        filled = true;

  final String label;
  final Color? color;
  final bool filled;
  final VoidCallback? onTap;
  final AppChipStatus? status;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? _chipStatusColor(status);
    final fg = resolvedColor;
    final bg = filled ? fg.withValues(alpha: 0.12) : Colors.transparent;
    final border = fg.withValues(alpha: filled ? 0.0 : 0.35);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(999), onTap: onTap, child: content);
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _badgeColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$1),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.$3,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (ctaLabel != null && onCta != null) {
      actions.add(AppButton(label: ctaLabel!, onPressed: onCta));
    }
    if (secondaryLabel != null && onSecondary != null) {
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 8));
      actions.add(
        AppButton(
          label: secondaryLabel!,
          variant: AppButtonVariant.secondary,
          onPressed: onSecondary,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.type,
    required this.label,
  });

  final StatusBadgeType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$1),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.$3,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TrustScoreIndicator extends StatelessWidget {
  const TrustScoreIndicator({
    super.key,
    required this.score,
    this.size = 48,
    this.showLabel = true,
  });

  final int score;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
            border: Border.all(color: AppColors.primary),
          ),
          alignment: Alignment.center,
          child: Text(
            '$clamped',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryStrong,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          const Text(
            'Güven',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

ColorPair _badgeColors(AppBadgeTone tone) => switch (tone) {
  AppBadgeTone.info => (AppColors.info, AppColors.info.withValues(alpha: 0.10), AppColors.info),
  AppBadgeTone.success =>
    (AppColors.success, AppColors.success.withValues(alpha: 0.10), AppColors.success),
  AppBadgeTone.warning =>
    (AppColors.warning, AppColors.warning.withValues(alpha: 0.14), AppColors.warning),
  AppBadgeTone.danger =>
    (AppColors.danger, AppColors.danger.withValues(alpha: 0.10), AppColors.danger),
  AppBadgeTone.neutral =>
    (AppColors.borderStrong, AppColors.cardAlt, AppColors.textStrong),
};

ColorPair _statusColors(StatusBadgeType type) => switch (type) {
  StatusBadgeType.verified =>
    (AppColors.success, AppColors.success.withValues(alpha: 0.10), AppColors.success),
  StatusBadgeType.pending =>
    (AppColors.info, AppColors.info.withValues(alpha: 0.10), AppColors.info),
  StatusBadgeType.outdated =>
    (AppColors.warning, AppColors.warning.withValues(alpha: 0.14), AppColors.warning),
};

typedef ColorPair = (Color, Color, Color);

Color _chipStatusColor(AppChipStatus? status) => switch (status) {
  AppChipStatus.success => AppColors.success,
  AppChipStatus.warning => AppColors.warning,
  AppChipStatus.danger => AppColors.danger,
  _ => AppColors.primary,
};
