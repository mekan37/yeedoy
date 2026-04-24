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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.menu_book_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              menu.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          _StatusChip(
                            label: _statusLabel(context, menu.status),
                            color: statusColor,
                          ),
                        ],
                      ),
                      if ((menu.activeFrom ?? '').isNotEmpty ||
                          (menu.activeTo ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 13,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _activeRange(context, menu.activeFrom, menu.activeTo),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: Text(context.l10n.duzenle),
                          ),
                          OutlinedButton.icon(
                            onPressed: onArchive,
                            icon: const Icon(Icons.archive_outlined, size: 15),
                            label: Text(context.l10n.ownerArchiveAction),
                          ),
                          if (onPublish != null)
                            FilledButton.icon(
                              onPressed: onPublish,
                              icon: const Icon(Icons.publish_outlined, size: 15),
                              label: Text(context.l10n.ownerPublishAction),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
