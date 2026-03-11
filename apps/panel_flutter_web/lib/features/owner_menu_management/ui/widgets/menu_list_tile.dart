import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/owner_menu_models.dart';

class MenuListTile extends StatelessWidget {
  const MenuListTile({
    super.key,
    required this.menu,
    required this.onEdit,
    required this.onArchive,
    required this.onPublish,
  });

  final OwnerMenu menu;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(menu.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    menu.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusChip(
                  label: _statusLabel(context, menu.status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if ((menu.activeFrom ?? '').isNotEmpty ||
                (menu.activeTo ?? '').isNotEmpty)
              Text(
                _activeRange(context, menu.activeFrom, menu.activeTo),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: Text(context.l10n.duzenle),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onArchive,
                  child: Text(context.l10n.ownerArchiveAction),
                ),
                const Spacer(),
                if (onPublish != null)
                  FilledButton(
                    onPressed: onPublish,
                    child: Text(context.l10n.ownerPublishAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'published':
      return AppColors.success;
    case 'draft':
      return AppColors.warning;
    case 'archived':
      return AppColors.muted;
    default:
      return AppColors.muted;
  }
}

String _activeRange(BuildContext context, String? from, String? to) {
  final safeFrom = (from ?? '').isEmpty ? '-' : from!;
  final safeTo = (to ?? '').isEmpty ? '-' : to!;
  return context.l10n.ownerActiveRange(safeFrom, safeTo);
}

String _statusLabel(BuildContext context, String status) {
  switch (status) {
    case 'published':
      return context.l10n.ownerStatusPublished;
    case 'draft':
      return context.l10n.ownerStatusDraft;
    case 'archived':
      return context.l10n.ownerStatusArchived;
    default:
      return status;
  }
}
