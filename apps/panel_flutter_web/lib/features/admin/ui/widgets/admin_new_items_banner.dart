import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';

class AdminNewItemsBanner extends StatefulWidget {
  const AdminNewItemsBanner({
    super.key,
    required this.count,
    required this.label,
    required this.onRefresh,
    this.onDismiss,
  });

  final int count;
  final String label;
  final VoidCallback onRefresh;
  final VoidCallback? onDismiss;

  @override
  State<AdminNewItemsBanner> createState() => _AdminNewItemsBannerState();
}

class _AdminNewItemsBannerState extends State<AdminNewItemsBanner> {
  int dismissedAt = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    final show = widget.count > dismissedAt;
    if (!show) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            l10n.adminNewItemsBannerLabel(widget.label, widget.count),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => dismissedAt = widget.count);
              widget.onDismiss?.call();
            },
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: widget.onRefresh,
            child: Text(l10n.yenile),
          ),
        ],
      ),
    );
  }
}
