import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/app_network_image.dart';
import '../../domain/owner_menu_models.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onArchive,
    this.thumbUrl,
  });

  final OwnerMenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// Varsa ürünün küçük resmi (opsiyonel)
  final String? thumbUrl;

  @override
  Widget build(BuildContext context) {
    final price = _formatPrice(item.priceCents, item.currency);
    final statusColor = _statusColor(item.status);
    final hasThumb = thumbUrl != null && thumbUrl!.isNotEmpty;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            children: [
              // ── Görsel / İkon ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: hasThumb
                      ? AppNetworkImage(
                          url: thumbUrl!,
                          variant: AppImageVariant.thumb,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: statusColor.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.fastfood_outlined,
                            size: 22,
                            color: statusColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Ad / Fiyat / Rozetler ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _PriceChip(price: price),
                        _StatusChip(status: item.status),
                        if (item.catalogItemId != null) const _CatalogChip(),
                        if (!hasThumb) const _NoPhotoHint(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Aksiyon Butonları ─────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    tooltip: context.l10n.duzenle,
                    onTap: onEdit,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  _ActionBtn(
                    icon: Icons.archive_outlined,
                    tooltip: 'Arşivle / Kaldır',
                    onTap: onArchive,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price});
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        price,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.l10n.ownerCatalogLabel,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _NoPhotoHint extends StatelessWidget {
  const _NoPhotoHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 10, color: AppColors.warning),
          SizedBox(width: 3),
          Text(
            'Görsel yok',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(context, status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
  if (cents == null) return '—';
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  final cur = (currency ?? 'TRY').toUpperCase();
  return '$text $cur';
}
