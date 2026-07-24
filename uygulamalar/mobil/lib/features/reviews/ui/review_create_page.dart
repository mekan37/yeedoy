import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/assets/category_assets.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/media/app_network_image.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../business/domain/business.dart';
import '../../discovery/data/discovery_repository.dart';
import 'review_create_form.dart';

final _reviewBusinessProvider = FutureProvider.autoDispose.family<Business, String>((
  ref,
  id,
) {
  return ref.watch(discoveryRepositoryProvider).fetchBusiness(id);
});

class ReviewCreatePage extends ConsumerWidget {
  const ReviewCreatePage({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final tokens = AppTokens.of(context);

    return AppScaffold(
      appBar: AppBar(title: Text(t.writeReview)),
      body: ListView(
        padding: EdgeInsets.all(tokens.space16),
        children: [
          Text(
            t.reviewCreateHeroTitle,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: tokens.space4),
          Text(
            t.reviewCreateHeroSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          SizedBox(height: tokens.space16),
          _ReviewBusinessSummaryCard(businessId: businessId),
          SizedBox(height: tokens.space20),
          ReviewCreateForm(
            businessId: businessId,
            onSubmitted: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _ReviewBusinessSummaryCard extends ConsumerWidget {
  const _ReviewBusinessSummaryCard({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final businessAsync = ref.watch(_reviewBusinessProvider(businessId));
    return businessAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (_, _) => const SizedBox.shrink(),
      data: (business) {
        final image = _firstHttpUrl([
          business.heroImageUrl,
          business.coverImageUrl,
          business.imageUrl,
          business.logoUrl,
        ]);
        final locationLabel = business.district?.trim().isNotEmpty == true
            ? business.district!.trim()
            : (business.city?.trim() ?? '');
        return AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius16),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: image != null
                      ? AppNetworkImage(
                          url: image,
                          fit: BoxFit.cover,
                          variant: AppImageVariant.thumb,
                        )
                      : Image.asset(
                          CategoryAssets.resolve(business.category),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(width: tokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: tokens.space4),
                    Text(
                      locationLabel.isEmpty
                          ? business.category
                          : '${business.category} · $locationLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (business.reviewsCount > 0) ...[
                      SizedBox(height: tokens.space4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.star,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${business.avgRating.toStringAsFixed(1)} (${business.reviewsCount})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String? _firstHttpUrl(List<String?> candidates) {
  for (final raw in candidates) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) continue;
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return value;
    }
  }
  return null;
}
