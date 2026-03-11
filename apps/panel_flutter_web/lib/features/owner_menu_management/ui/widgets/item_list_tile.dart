import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/owner_menu_models.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onArchive,
  });

  final OwnerMenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final price = _formatPrice(item.priceCents, item.currency);
    return Card(
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              price,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            _StatusChip(status: item.status),
            if (item.catalogItemId != null) const _CatalogChip(),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.duzenle,
            ),
            IconButton(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
              tooltip: context.l10n.ownerArchiveAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogChip extends StatelessWidget {
  const _CatalogChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.ownerCatalogLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(context, status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
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

String _formatPrice(int? cents, String? currency) {
  if (cents == null) return 'â€”';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  final cur = (currency ?? 'TRY').toUpperCase();
  return '$text $cur';
}

