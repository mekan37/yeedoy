import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../business/domain/meal_card_provider_option.dart';
import '../../../features/shared/ui/design_system.dart';
import 'widgets/meal_card_badge.dart';

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

  String? _fmtKm(double? km) {
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                    if (qualityScore != null && qualityScore! >= 3) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 6),
                            Text(
                              t.quality,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (mealCardProviders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  MealCardBadgeRow(
                    providers: mealCardProviders,
                    maxVisible: 3,
                  ),
                ],
                if (socialProof != null && socialProof!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final label in socialProof!)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (onWhyTap != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onWhyTap,
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: Text(t.whyTop),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailingAction ?? const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}



