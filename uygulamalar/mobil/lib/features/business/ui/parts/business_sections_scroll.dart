part of '../business_page.dart';

/// Constrains content to the same max-width breakpoints used across the
/// fixed header and all three tabs (1040px wide / 720px medium / full narrow).
class _ConstrainedContent extends StatelessWidget {
  const _ConstrainedContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1040
            ? 1040.0
            : (constraints.maxWidth >= 720 ? 720.0 : constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

class _BusinessFixedHeader extends StatelessWidget {
  const _BusinessFixedHeader({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _ConstrainedContent(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space16,
          tokens.space12,
          tokens.space16,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BusinessHeroTrustHeader(business: business, isOpenNow: isOpenNow),
            _BusinessBadgeChipRow(business: business),
            _BusinessDescription(description: business.description),
          ],
        ),
      ),
    );
  }
}

class _BusinessGeneralTab extends ConsumerWidget {
  const _BusinessGeneralTab({required this.business, required this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    final trustAsync = ref.watch(_businessTrustProvider(business.id));

    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          _BusinessFeaturedSection(business: business),
          _BusinessPopularDishesSection(business: business),
          _BusinessLocationHoursSection(
            business: business,
            isOpenNow: isOpenNow,
          ),
          _BusinessRecentReviewsSection(businessId: business.id),
          _BusinessPresenceBadge(businessId: business.id),
          const WeatherHintBar(compact: true),
          SizedBox(height: tokens.space16),
          trustAsync.when(
            loading: () => const AppSkeletonCard(),
            error: (error, _) => AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.trustDataUnavailable,
              description:
                  '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
              ctaLabel: AppLocalizations.of(context).retry,
              onCta: () => ref.invalidate(_businessTrustProvider(business.id)),
            ),
            data: (trust) {
              final trendingAsync = ref.watch(
                businessTrendingItemsProvider(business.id),
              );
              final topPriceCents = trendingAsync.maybeWhen(
                data: (items) => items.isEmpty ? null : items.first.priceCents,
                orElse: () => null,
              );
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TopStatCard(
                          title: t.communityScoreDataTrustLabel,
                          value: '${trust.trustScore}',
                          subtitle: '%',
                          icon: Icons.shield_rounded,
                          circleValue: trust.trustScore / 100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TopStatCard(
                          title: t.lastUpdated,
                          value: _relativeTimeLabel(
                            context,
                            trust.menuUpdatedAt,
                          ),
                          subtitle: '',
                          icon: Icons.history_toggle_off_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TopStatCard(
                          title: t.avgCost,
                          value: _formatPriceWithCurrency(
                            context,
                            topPriceCents,
                            '?',
                          ),
                          subtitle: '',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.space16),
                  const CommunityScoreGuideCard(
                    kind: CommunityScoreKind.dataTrust,
                    margin: EdgeInsets.zero,
                  ),
                  SizedBox(height: tokens.space16),
                  _CommunityVerifiedCard(
                    usersToday: trust.lastPriceVerifiedPeople <= 0
                        ? 12
                        : trust.lastPriceVerifiedPeople,
                  ),
                  SizedBox(height: tokens.space16),
                  _PriceHistorySection(points: trust.priceChanges3m),
                ],
              );
            },
          ),
          SizedBox(height: tokens.space16),
          BusinessPerksSection(
            businessId: business.id,
            businessName: business.name,
          ),
        ],
      ),
    );
  }
}

class _BusinessMenuTab extends StatelessWidget {
  const _BusinessMenuTab({
    required this.businessId,
    required this.fallbackCategory,
  });

  final String businessId;
  final String fallbackCategory;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          _BusinessMenuPreviewSection(
            businessId: businessId,
            fallbackCategory: fallbackCategory,
          ),
          SizedBox(height: tokens.space16),
          BusinessMenusSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessMealCardsSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openReportSheet(context, businessId),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(t.contributeMenuPhoto),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessReviewsTab extends StatelessWidget {
  const _BusinessReviewsTab({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    return _ConstrainedContent(
      child: ListView(
        padding: padding,
        children: [
          BusinessReviewsSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessReviewPhotosSection(businessId: businessId),
          SizedBox(height: tokens.space16),
          BusinessFrequentTagsSection(businessId: businessId),
        ],
      ),
    );
  }
}

/// Maps a `business_amenities` row's `key` (plain snake_case string, e.g.
/// `'kids_area'`) to a presentational Material icon. The label shown to the
/// user is always `amenity.label` from the database — this only selects the
/// glyph.
IconData _amenityIconFor(String key) {
  switch (key) {
    case 'kids_area':
      return Icons.child_care_outlined;
    case 'parking':
      return Icons.local_parking_outlined;
    case 'wifi':
      return Icons.wifi;
    case 'pet_friendly':
      return Icons.pets_outlined;
    case 'smoking_area':
      return Icons.smoking_rooms_outlined;
    case 'outdoor_seating':
      return Icons.deck_outlined;
    case 'alcohol':
      return Icons.local_bar_outlined;
    case 'delivery':
      return Icons.delivery_dining_outlined;
    case 'takeaway':
      return Icons.takeout_dining_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.icon,
    required this.title,
    this.subtitle = '',
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
      child: Container(
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
            ),
            SizedBox(height: tokens.space8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BusinessFeaturedSection extends ConsumerWidget {
  const _BusinessFeaturedSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final amenitiesAsync = ref.watch(businessAmenitiesProvider(business.id));
    final trustAsync = ref.watch(_businessTrustProvider(business.id));

    final cards = <Widget>[];

    if (business.avgRating > 0) {
      cards.add(
        _FeaturedCard(
          icon: Icons.star_rounded,
          title: business.avgRating.toStringAsFixed(1),
          subtitle: t.featuredRatingLabel,
        ),
      );
    }

    final amenities = amenitiesAsync.value ?? const [];
    for (final amenity in amenities) {
      if (amenity.key == 'kids_area') {
        cards.add(
          _FeaturedCard(
            icon: _amenityIconFor(amenity.key),
            title: amenity.label,
          ),
        );
        break;
      }
    }

    if (trustAsync.value?.menuSource == 'owner') {
      cards.add(
        _FeaturedCard(
          icon: Icons.verified_outlined,
          title: t.businessBadgeMenuVerified,
          subtitle: t.featuredMenuVerifiedSubtitle,
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.featuredSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: tokens.space8),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            children: cards,
          ),
        ],
      ),
    );
  }
}

class _PopularDishCard extends StatelessWidget {
  const _PopularDishCard({required this.item, required this.fallbackCategory});

  final BusinessTrendingItem item;
  final String fallbackCategory;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final remoteUrl = _normalizeImageUrl(item.imageUrl);
    return Container(
      padding: EdgeInsets.all(tokens.space8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(tokens.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: remoteUrl != null
                  ? AppNetworkImage(
                      url: remoteUrl,
                      fit: BoxFit.cover,
                      variant: AppImageVariant.thumb,
                    )
                  : Image.asset(
                      CategoryAssets.resolve(fallbackCategory),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          SizedBox(width: tokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPriceWithCurrency(
                    context,
                    item.priceCents,
                    item.currency,
                  ),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPopularDishesSection extends ConsumerWidget {
  const _BusinessPopularDishesSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));
    final items = trendingAsync.value ?? const <BusinessTrendingItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final shown = items.take(4).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.popularDishesTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                child: Text(t.seeAll),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: tokens.space8,
            crossAxisSpacing: tokens.space8,
            childAspectRatio: 2.4,
            children: [
              for (final item in shown)
                _PopularDishCard(
                  item: item,
                  fallbackCategory: business.category,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationHoursCard extends StatelessWidget {
  const _LocationHoursCard({
    required this.icon,
    required this.text,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radius16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            SizedBox(width: tokens.space8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BusinessLocationHoursSection extends ConsumerWidget {
  const _BusinessLocationHoursSection({
    required this.business,
    required this.isOpenNow,
  });

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final hoursAsync = ref.watch(_businessHoursProvider(business.id));

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.locationHoursTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: tokens.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LocationHoursCard(
                  icon: Icons.location_on_outlined,
                  text: business.address?.trim().isNotEmpty == true
                      ? business.address!
                      : _locText(context, business.district, business.city),
                  onTap: () => unawaited(
                    _openDirections(
                      businessName: business.name,
                      address: business.address,
                      lat: business.lat,
                      lng: business.lng,
                    ),
                  ),
                ),
              ),
              SizedBox(width: tokens.space8),
              Expanded(
                child: hoursAsync.when(
                  loading: () => _LocationHoursCard(
                    icon: Icons.schedule_outlined,
                    text: t.noHoursInfo,
                    onTap: null,
                  ),
                  error: (_, _) => _LocationHoursCard(
                    icon: Icons.schedule_outlined,
                    text: t.hoursInfoMissing,
                    onTap: () => _openReportSheet(context, business.id),
                  ),
                  data: (today) {
                    if (today == null) {
                      return _LocationHoursCard(
                        icon: Icons.schedule_outlined,
                        text: t.hoursInfoMissing,
                        onTap: () => _openReportSheet(context, business.id),
                      );
                    }
                    final statusLabel = isOpenNow == true
                        ? t.openNow
                        : t.closedNow;
                    return _LocationHoursCard(
                      icon: Icons.schedule,
                      iconColor: isOpenNow == true
                          ? AppColors.success
                          : AppColors.danger,
                      text:
                          '$statusLabel · ${_hoursText(context, today.open, today.close)}',
                      onTap: () => _openReportSheet(context, business.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessRecentReviewsSection extends ConsumerWidget {
  const _BusinessRecentReviewsSection({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final detailAsync = ref.watch(businessDetailProvider(businessId));
    final reviews = detailAsync.value?.latestReviews ?? const [];
    if (reviews.isEmpty) return const SizedBox.shrink();
    final review = reviews.first;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.recentReviews,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                child: Text(t.seeAll),
              ),
            ],
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.star,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTimeLabel(context, review.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space8),
                Text(
                  review.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
