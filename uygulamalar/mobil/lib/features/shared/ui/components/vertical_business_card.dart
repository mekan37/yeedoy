import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/assets/category_assets.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../design_system.dart';
import '../../../discovery/domain/business_card.dart';
import 'open_price_badge.dart';

/// Estimates a walking-time range from [distanceKm] using a 4-5 km/h
/// walking speed. Returns null for non-positive distances. Falls back to
/// a single value (via [AppLocalizations.timeMinutes]) when the rounded
/// bounds collapse to the same minute.
String? walkingEtaLabel(AppLocalizations t, double distanceKm) {
  if (distanceKm <= 0) return null;
  final minMinutes = (distanceKm * 12).ceil();
  final maxMinutes = (distanceKm * 15).ceil();
  if (maxMinutes <= minMinutes) return t.timeMinutes(minMinutes);
  return t.etaRangeMinutes(minMinutes, maxMinutes);
}

/// Formats a "rating (votes)" label, e.g. "4.8 (1.2k)", from real
/// [BusinessCardModel] fields with sane fallbacks for missing data.
String businessRatingLabel(BusinessCardModel item) {
  final rating = ((item.avgRating ?? 4.6) * 10).round() / 10;
  final trust = item.trustScore ?? 1.2;
  final votes = trust >= 10
      ? '${(trust / 1000).toStringAsFixed(1)}k'
      : '1.2k';
  return '$rating ($votes)';
}

/// Resolves a category-based placeholder image asset for [category].
String categoryImageAsset(String category) {
  return CategoryAssets.resolve(category);
}

/// Vertical business card used across Discovery and Favorites: full-width
/// hero image with rating + favorite badges, business name, category and
/// open status, distance/ETA and price tier.
class VerticalBusinessCard extends StatelessWidget {
  const VerticalBusinessCard({
    super.key,
    required this.item,
    required this.imageAsset,
    required this.ratingLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.topRightExtra,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String ratingLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  /// Optional extra circular action rendered to the left of the favorite
  /// button (e.g. "add to collection" on the Favorites tab).
  final Widget? topRightExtra;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final distanceKm = item.distanceKm ?? 0.4;
    final distance = t.distanceKm(double.parse(distanceKm.toStringAsFixed(1)));
    final eta = walkingEtaLabel(t, distanceKm);
    final priceSymbol = priceLevelSymbol(item.priceLevel, item.medianPriceCents);

    return AppCard(
      padding: const EdgeInsets.all(0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tokens.radius20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: tokens.space8,
                top: tokens.space8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.solidStar,
                        size: 11,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: tokens.space8,
                top: tokens.space8,
                child: Row(
                  children: [
                    if (topRightExtra != null) ...[
                      topRightExtra!,
                      SizedBox(width: tokens.space8),
                    ],
                    Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavoriteTap,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AppColors.primary : AppColors.muted,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space12,
              tokens.space12,
              tokens.space12,
              tokens.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: tokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ),
                    if (item.isOpenNow != null) ...[
                      SizedBox(width: tokens.space8),
                      OpenStatusBadge(isOpen: item.isOpenNow!),
                    ],
                  ],
                ),
                SizedBox(height: tokens.space8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              eta == null ? distance : '$distance • $eta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (priceSymbol != null) ...[
                      SizedBox(width: tokens.space8),
                      PriceLevelBadge(symbol: priceSymbol),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
