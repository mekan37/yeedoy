part of '../business_page.dart';

final _businessDeliveryUrlsProvider = FutureProvider.autoDispose
    .family<({String? yemeksepeti, String? trendyolgo, String? getir}), String>(
  (ref, businessId) async {
    final client = ref.watch(supabaseProvider);
    final res = await client
        .from('businesses')
        .select(
          'order_yemeksepeti_url, order_trendyolgo_url, order_getir_url',
        )
        .eq('id', businessId)
        .single();
    final m = (res as Map).cast<String, dynamic>();
    return (
      yemeksepeti: m['order_yemeksepeti_url'] as String?,
      trendyolgo: m['order_trendyolgo_url'] as String?,
      getir: m['order_getir_url'] as String?,
    );
  },
);

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
  const _BusinessFixedHeader({
    required this.business,
    required this.isOpenNow,
    required this.heroCollapse,
  });

  final Business business;
  final bool? isOpenNow;
  final ValueNotifier<double> heroCollapse;

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
            _BusinessHeroTrustHeader(
              business: business,
              heroCollapse: heroCollapse,
            ),
            ValueListenableBuilder<double>(
              valueListenable: heroCollapse,
              builder: (context, progress, _) {
                final opacity = (1 - progress / 0.7).clamp(0.0, 1.0);
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: (1 - progress).clamp(0.0, 1.0),
                    child: Opacity(
                      opacity: opacity,
                      child: _BusinessInfoPanel(
                        business: business,
                        isOpenNow: isOpenNow,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessSegmentedTabBar extends StatelessWidget {
  const _BusinessSegmentedTabBar({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _ConstrainedContent(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.space16,
          tokens.space12,
          tokens.space16,
          tokens.space8,
        ),
        child: AppSegmentedTabBar(labels: labels),
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
          _ChainBand(businessId: business.id),
          CheckInButton(businessId: business.id),
          SizedBox(height: tokens.space16),
          _BusinessPopularDishesSection(business: business),
          _BusinessLocationHoursSection(
            business: business,
            isOpenNow: isOpenNow,
          ),
          _BusinessRecentReviewsSection(businessId: business.id),
          _BusinessPresenceBadge(businessId: business.id),
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
                  // Compact data trust bar
                  GestureDetector(
                    onTap: () => showCommunityScoreExplainerSheet(
                      context,
                      kind: CommunityScoreKind.dataTrust,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(tokens.radius12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.communityScoreDataTrustLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.help_outline_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const Spacer(),
                          Text(
                            '%${trust.trustScore}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: trust.trustScore >= 70
                                  ? AppColors.success
                                  : trust.trustScore >= 40
                                      ? AppColors.warning
                                      : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: LinearProgressIndicator(
                              value: trust.trustScore / 100,
                              backgroundColor:
                                  AppColors.border,
                              valueColor: AlwaysStoppedAnimation(
                                trust.trustScore >= 70
                                    ? AppColors.success
                                    : trust.trustScore >= 40
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                              minHeight: 6,
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.space12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                  ),
                  SizedBox(height: tokens.space16),
                  _CommunityVerifiedCard(
                    usersToday: trust.lastPriceVerifiedPeople <= 0
                        ? 12
                        : trust.lastPriceVerifiedPeople,
                  ),
                  SizedBox(height: tokens.space16),
                  if (trust.priceChanges3m.isNotEmpty &&
                      trust.priceChanges3m.any((v) => v > 0))
                    _PriceHistorySection(points: trust.priceChanges3m),
                ],
              );
            },
          ),
          SizedBox(height: tokens.space16),
          _BusinessDeliverySection(businessId: business.id),
          _ReservationSection(business: business),
          BusinessPerksSection(
            businessId: business.id,
            businessName: business.name,
          ),
        ],
      ),
    );
  }
}

class _BusinessDeliverySection extends ConsumerWidget {
  const _BusinessDeliverySection({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlsAsync = ref.watch(_businessDeliveryUrlsProvider(businessId));
    return urlsAsync.maybeWhen(
      data: (urls) {
        final platforms = <({String asset, String label, String url})>[
          if (urls.yemeksepeti != null)
            (
              asset: 'assets/images/delivery/yemeksepeti.png',
              label: 'Yemeksepeti',
              url: urls.yemeksepeti!,
            ),
          if (urls.trendyolgo != null)
            (
              asset: 'assets/images/delivery/trendyolgo.png',
              label: 'Trendyol Go',
              url: urls.trendyolgo!,
            ),
          if (urls.getir != null)
            (
              asset: 'assets/images/delivery/getiryemek.png',
              label: 'Getir Yemek',
              url: urls.getir!,
            ),
        ];
        if (platforms.isEmpty) return const SizedBox.shrink();
        final tokens = AppTokens.of(context);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Online Sipariş', style: context.sectionTitleStyle),
              SizedBox(height: tokens.space12),
              ...platforms.map(
                (p) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.space8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(tokens.radius12),
                    onTap: () => launchUrl(
                      Uri.parse(p.url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.space12,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(tokens.radius12),
                        color: AppColors.bg,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            p.asset,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ReservationSection extends StatelessWidget {
  const _ReservationSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    if (!business.acceptsReservations) return const SizedBox.shrink();

    final tokens = AppTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(top: tokens.space16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: tokens.space8),
                Text('Rezervasyon', style: context.sectionTitleStyle),
              ],
            ),
            SizedBox(height: tokens.space8),
            Text(
              'Masanızı önceden ayırtın, bekleme olmadan gelin.',
              style: context.captionStyle,
            ),
            if (business.reservationNote != null) ...[
              SizedBox(height: tokens.space8),
              Text(
                business.reservationNote!,
                style: context.captionStyle,
              ),
            ],
            SizedBox(height: tokens.space16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => showReservationSheet(context, business),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radius12),
                  ),
                ),
                child: Text(
                  'Rezervasyon Yap',
                  style: context.appText.labelLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (business.reservationPhone != null) ...[
              SizedBox(height: tokens.space8),
              Center(
                child: Text(
                  'Tel: ${business.reservationPhone}',
                  style: context.captionStyle,
                ),
              ),
            ],
          ],
        ),
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
          BusinessMealCardsSection(businessId: businessId),
        ],
      ),
    );
  }
}

class _BusinessReviewsTab extends StatefulWidget {
  const _BusinessReviewsTab({required this.businessId});

  final String businessId;

  @override
  State<_BusinessReviewsTab> createState() => _BusinessReviewsTabState();
}

class _BusinessReviewsTabState extends State<_BusinessReviewsTab> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
          // Yorum yaz butonu veya açık form
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showForm
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.reviewCreateHeroTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textStrong,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _showForm = false),
                            icon: const Icon(Icons.keyboard_arrow_up),
                            tooltip: t.cancel,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      SizedBox(height: tokens.space8),
                      ReviewCreateForm(businessId: widget.businessId),
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: () => setState(() => _showForm = true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: Text(t.writeReview),
                  ),
          ),
          SizedBox(height: tokens.space20),
          BusinessReviewsSection(businessId: widget.businessId),
          SizedBox(height: tokens.space16),
          BusinessReviewPhotosSection(businessId: widget.businessId),
          SizedBox(height: tokens.space16),
          BusinessFrequentTagsSection(businessId: widget.businessId),
        ],
      ),
    );
  }
}

/// Maps a `business_amenities` row's `key` (plain snake_case string, e.g.
/// `'kids_area'`) to a presentational Material icon. The label shown to the
/// user is always `amenity.label` from the database — this only selects the
/// glyph.


class _PopularDishCard extends StatelessWidget {
  const _PopularDishCard({required this.item, required this.fallbackCategory});

  final BusinessTrendingItem item;
  final String fallbackCategory;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final remoteUrl = _normalizeImageUrl(item.imageUrl);
    return Container(
      padding: EdgeInsets.all(tokens.space12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(tokens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius12),
            child: SizedBox(
              width: 64,
              height: 64,
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
          SizedBox(height: tokens.space8),
          Text(
            item.itemName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textStrong,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _formatPriceWithCurrency(
              context,
              item.priceCents,
              item.currency,
            ),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
    final shown = items.take(2).toList(growable: false);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0) SizedBox(width: tokens.space8),
                Expanded(
                  child: _PopularDishCard(
                    item: shown[i],
                    fallbackCategory: business.category,
                  ),
                ),
              ],
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _LocationHoursCard(
                    icon: Icons.location_on_rounded,
                    text: 'Haritada Aç',
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
