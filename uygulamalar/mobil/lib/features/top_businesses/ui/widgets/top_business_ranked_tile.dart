import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/assets/category_assets.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../auth/domain/auth_providers.dart';
import '../../../favorites/domain/favorite_status_provider.dart';
import '../../../favorites/domain/favorites_controller.dart';
import '../../../shared/ui/components/quick_login_sheet.dart';
import '../../../../features/shared/ui/design_system.dart';
import '../../domain/top_business.dart';

class TopBusinessRankedTile extends ConsumerWidget {
  const TopBusinessRankedTile({
    super.key,
    required this.item,
    required this.rank,
    required this.onTap,
  });

  final TopBusiness item;
  final int rank;
  final VoidCallback onTap;

  String _locText(BuildContext context) {
    final d = (item.district ?? '').trim();
    final c = (item.city ?? '').trim();
    if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
    if (d.isEmpty) return c;
    if (c.isEmpty) return d;
    return '$c - $d';
  }

  static int walkingMinutes(double km) => (km / 4.5 * 60).round().clamp(1, 999);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final category = (item.category ?? '').trim();
    final subtitle = category.isEmpty
        ? _locText(context)
        : '$category · ${_locText(context)}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankedImage(item: item, rank: rank),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (item.distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '${item.distanceKm!.toStringAsFixed(1)} km · ~${walkingMinutes(item.distanceKm!)} dk',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: tokens.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopBusinessFavoriteButton(businessId: item.id),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                  const SizedBox(width: 2),
                  Text(
                    item.avgRating > 0 ? item.avgRating.toStringAsFixed(1) : '-',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${item.reviewsCount})',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TrustScoreIndicator(
                score: (item.avgRating * 10).round().clamp(0, 100),
                size: 36,
                showLabel: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankedImage extends StatelessWidget {
  const _RankedImage({required this.item, required this.rank});

  final TopBusiness item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (url != null && url.isNotEmpty)
                  ? AppNetworkImage(url: url, fit: BoxFit.cover, variant: AppImageVariant.thumb)
                  : Image.asset(CategoryAssets.resolve(item.category), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppColors.primary : AppColors.cardAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3 ? Colors.white : AppColors.textStrong,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBusinessFavoriteButton extends ConsumerWidget {
  const _TopBusinessFavoriteButton({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(businessId));

    Future<void> handleToggle() async {
      if (!isLoggedIn) {
        await showQuickLoginSheet(context, redirectPath: '/b/$businessId');
        return;
      }
      try {
        HapticFeedback.lightImpact();
        await ref.read(favoritesControllerProvider.notifier).toggleFavorite(businessId);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorMapper.message(error))),
        );
      }
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isFavorited ? t.favoriteAdded : t.addToFavorites,
        onPressed: () => unawaited(handleToggle()),
        icon: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFavorited ? AppColors.danger : AppColors.text,
        ),
      ),
    );
  }
}
