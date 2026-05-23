import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../app/theme/app_tokens.dart';

enum StatusBadgeType { verified, pending, outdated }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.type,
    this.label,
    this.semanticLabel,
  });

  final StatusBadgeType type;
  final String? label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final data = _data(context, type);
    final badgeLabel = label ?? data.label;
    return Semantics(
      label: semanticLabel ?? badgeLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(tokens.radius24),
          border: Border.all(color: data.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 12, color: data.color),
            const SizedBox(width: 4),
            Text(
              badgeLabel,
              style: TextStyle(
                color: data.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadgeData {
  const _StatusBadgeData({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_StatusBadgeData _data(BuildContext context, StatusBadgeType type) {
  final t = AppLocalizations.of(context);
  switch (type) {
    case StatusBadgeType.verified:
      return _StatusBadgeData(
        label: t.statusBadgeVerified,
        color: AppColors.primary,
        icon: Icons.verified_rounded,
      );
    case StatusBadgeType.pending:
      return _StatusBadgeData(
        label: t.statusBadgePending,
        color: AppColors.muted,
        icon: Icons.schedule_rounded,
      );
    case StatusBadgeType.outdated:
      return _StatusBadgeData(
        label: t.statusBadgeOutdated,
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
  }
}

