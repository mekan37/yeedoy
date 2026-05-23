part of '../isletme_sayfasi.dart';

class _BusinessSectionsScroll extends ConsumerWidget {
  const _BusinessSectionsScroll({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final padding = EdgeInsets.fromLTRB(
      tokens.space16,
      tokens.space12,
      tokens.space16,
      tokens.space24,
    );
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(business.id));
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));
    final isOpenNow = ref.watch(
      _businessHoursProvider(business.id).select(
        (async) => async.maybeWhen(
          data: (today) => today == null
              ? null
              : _isOpenNow(today.open, today.close, DateTime.now()),
          orElse: () => null,
        ),
      ),
    );
    final topPriceCents = trendingAsync.maybeWhen(
      data: (items) => items.isEmpty ? null : items.first.priceCents,
      orElse: () => null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1040
            ? 1040.0
            : (constraints.maxWidth >= 720 ? 720.0 : constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: padding,
              children: [
                _BusinessHeroTrustHeader(
                  business: business,
                  isOpenNow: isOpenNow,
                ),
                SizedBox(height: tokens.space12),
                BusinessActionsSection(business: business),
                SizedBox(height: tokens.space12),
                _BusinessPresenceBadge(businessId: business.id),
                const WeatherHintBar(compact: true),
                const SizedBox(height: 8),
                KalabalikGostergesi(businessId: business.id),
                SizedBox(height: tokens.space16),
                trustAsync.when(
                  loading: () => const AppSkeletonCard(),
                  error: (error, _) => AppEmptyState(
                    icon: Icons.wifi_off_outlined,
                    title: t.trustDataUnavailable,
                    description:
                        '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
                    ctaLabel: AppLocalizations.of(context).retry,
                    onCta: () =>
                        ref.invalidate(_businessTrustProvider(business.id)),
                  ),
                  data: (trust) => Column(
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
                  ),
                ),
                SizedBox(height: tokens.space16),
                BusinessPerksSection(
                  businessId: business.id,
                  businessName: business.name,
                ),
                SizedBox(height: tokens.space16),
                BusinessMealCardsSection(businessId: business.id),
                SizedBox(height: tokens.space16),
                _BusinessLoyaltyBadge(businessId: business.id),
                SizedBox(height: tokens.space20),
                _BusinessMenuPreviewSection(
                  businessId: business.id,
                  fallbackCategory: business.category,
                ),
                SizedBox(height: tokens.space16),
                BusinessFrequentTagsSection(businessId: business.id),
                SizedBox(height: tokens.space16),
                if (business.isActive) ...[
                  _MasaSiparisiSection(business: business),
                  SizedBox(height: tokens.space16),
                ],
                BusinessContactSection(business: business),
                SizedBox(height: tokens.space16),
                BusinessReviewPhotosSection(businessId: business.id),
                SizedBox(height: tokens.space16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openReportSheet(context, business.id),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(t.contributeMenuPhoto),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MasaSiparisiSection extends ConsumerWidget {
  const _MasaSiparisiSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstMenuId = ref.watch(
      businessMenusProvider(business.id).select((async) {
        final menus = async.asData?.value;
        if (menus == null || menus.isEmpty) return null;
        return menus.first.id;
      }),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masa Siparişi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                    ),
                    Text(
                      'Masanızdan sipariş verin',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: firstMenuId == null
                  ? null
                  : () {
                      final menuItemsAsync = ref.read(
                        menuItemsProvider(firstMenuId),
                      );
                      final items = menuItemsAsync.asData?.value ?? const [];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MasaSiparisiSayfasi(
                            businessId: business.id,
                            businessName: business.name,
                            menuItems: items,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'Sipariş Ver',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
