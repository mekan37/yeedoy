import 'package:flutter/material.dart';

import '../../../../uygulama/tema/renkler.dart';
import '../../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../../features/shared/ui/tasarim_sistemi.dart';
import '../../domain/en_iyi_isletme.dart';

class TopBusinessCard extends StatelessWidget {
  const TopBusinessCard({
    super.key,
    required this.item,
    required this.badge,
    required this.onTap,
    this.width,
  });

  final TopBusiness item;
  final String badge;
  final VoidCallback onTap;
  final double? width;

  String _locText(BuildContext context) {
    final d = (item.district ?? '').trim();
    final c = (item.city ?? '').trim();
    if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
    if (d.isEmpty) return c;
    if (c.isEmpty) return d;
    return '$c - $d';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: width ?? double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    item.category ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locText(context),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                const SizedBox(width: 4),
                Text(
                  item.avgRating > 0 ? item.avgRating.toStringAsFixed(1) : '-',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 10),
                Text(
                  t.topBusinessReviews(item.reviewsCount),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




