part of '../business_page.dart';

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
                _BusinessHeroTrustHeader(business: business),
                SizedBox(height: tokens.space12),
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
                BusinessMealCardsSection(businessId: business.id),
                SizedBox(height: tokens.space20),
                _BusinessMenuPreviewSection(
                  businessId: business.id,
                  fallbackCategory: business.category,
                ),
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
