import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../business/domain/meal_card_provider_option.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/sponsorluk/ui/sponsored_badge.dart';
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
    this.isSponsored = false,
    this.isOpenNow,
    this.medianPriceCents,
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

  /// When true, renders a [SponsoredBadge] beneath the business name row.
  final bool isSponsored;

  /// Open/closed status from the RPC response. Null means unknown — badge is
  /// hidden. False means closed, true means open.
  final bool? isOpenNow;

  /// Median price in Turkish kurus (1/100 TL). Null or zero hides the badge.
  ///
  /// TODO(P2): Replace threshold-based mapping with `businesses.price_level`
  /// column once the migration from docs/db-open-hours-price-badge-plan.md
  /// (section 5.2) is applied. See: compute_business_price_level_v1.
  final int? medianPriceCents;

  String? _fmtKm(double? km) {
    if (km == null) return null;
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  /// Returns a ₺ symbol string based on [cents], or null when cents is
  /// unavailable/zero. Thresholds are in kurus (1/100 TL).
  ///
  /// TODO(P2): Replace with `businesses.price_level` column value once the
  /// migration from docs/db-open-hours-price-badge-plan.md (section 5.2)
  /// is applied; update this helper to read 'budget'/'mid'/'premium' directly.
  static String? _priceLevelSymbol(int? cents) {
    if (cents == null || cents <= 0) return null;
    if (cents < 20000) return '₺';      // < 200 TL
    if (cents < 45000) return '₺₺';    // 200-450 TL
    return '₺₺₺';                      // > 450 TL
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
                if (isSponsored) ...[
                  const SponsoredBadge(),
                  const SizedBox(height: 4),
                ],
                if (isOpenNow != null || _priceLevelSymbol(medianPriceCents) != null) ...[
                  _OpenPriceBadgeRow(
                    isOpenNow: isOpenNow,
                    priceLevelSymbol: _priceLevelSymbol(medianPriceCents),
                  ),
                  const SizedBox(height: 6),
                ],
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

/// A compact horizontal row that shows open/closed status and price level
/// badges side by side. Each badge is independently nullable — if both are
/// absent the row is not rendered (caller guards with the `if` check).
class _OpenPriceBadgeRow extends StatelessWidget {
  const _OpenPriceBadgeRow({
    required this.isOpenNow,
    required this.priceLevelSymbol,
  });

  final bool? isOpenNow;
  final String? priceLevelSymbol;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isOpenNow != null) _OpenStatusBadge(isOpen: isOpenNow!),
        if (priceLevelSymbol != null)
          _PriceLevelBadge(symbol: priceLevelSymbol!),
      ],
    );
  }
}

/// Shows "Acik" (green dot) or "Kapali" (grey dot).
/// Rendered only when [isOpenNow] is non-null — null means unknown.
class _OpenStatusBadge extends StatelessWidget {
  const _OpenStatusBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = isOpen ? AppColors.success : AppColors.muted;
    final label = isOpen ? t.openNow : t.closedNow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows ₺ / ₺₺ / ₺₺₺ price level symbol.
class _PriceLevelBadge extends StatelessWidget {
  const _PriceLevelBadge({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

