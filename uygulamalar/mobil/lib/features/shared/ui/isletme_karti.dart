import 'package:flutter/material.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../isletme/domain/ogun_karti_saglayici_secenegi.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

class BusinessTile extends StatelessWidget {
  const BusinessTile({
    super.key,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.onTap,
    this.distanceKm,
    this.qualityScore,
    this.badgeText,
    this.socialProof,
    this.trailingAction,
    this.onWhyTap,
    this.mealCardProviders = const [],
    this.isOpenNow,
  });

  final String name;
  final String category;
  final String subtitle;
  final VoidCallback onTap;
  final double? distanceKm;
  final double? qualityScore;
  final String? badgeText;
  final List<String>? socialProof;
  final Widget? trailingAction;
  final VoidCallback? onWhyTap;
  final List<MealCardProviderOption> mealCardProviders;
  /// Null = bilinmiyor (rozet gösterilmez). True = açık, False = kapalı.
  final bool? isOpenNow;

  String? _fmtKm(double? km) {
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  @override
  Widget build(BuildContext context) {
    final distText = _fmtKm(distanceKm);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDeep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.place, color: AppColors.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (badgeText != null && badgeText!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    if (distText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          distText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                    ],
                    if (trailingAction != null) ...[
                      const SizedBox(width: 8),
                      trailingAction!,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOpenNow != null) ...[
                      const SizedBox(width: 6),
                      _OpenNowBadge(isOpen: isOpenNow!),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Açık/kapalı rozeti — keşif listesi kartı için kompakt versiyon.
class _OpenNowBadge extends StatelessWidget {
  const _OpenNowBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    const openColor = Color(0xFF16A34A);
    final bgColor = isOpen
        ? openColor.withValues(alpha: 0.10)
        : AppColors.muted.withValues(alpha: 0.10);
    final borderColor = isOpen
        ? openColor.withValues(alpha: 0.30)
        : AppColors.border;
    final dotColor = isOpen ? openColor : AppColors.muted;
    final textColor = isOpen ? openColor : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Açık' : 'Kapalı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
