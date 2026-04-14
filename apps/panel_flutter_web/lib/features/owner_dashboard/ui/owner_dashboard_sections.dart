import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/app_card.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../owner_monetization/data/owner_monetization_repository.dart';
import '../domain/owner_growth_provider.dart';
import '../domain/owner_kpi_provider.dart';
import '../domain/owner_moat_provider.dart';
import '../domain/owner_quality_score_provider.dart';

final ownerSponsorshipCatalogProvider =
    FutureProvider.family<List<OwnerSponsorshipCatalogItem>, String?>((
      ref,
      businessId,
    ) async {
      if (businessId == null || businessId.isEmpty) {
        return const [];
      }
      final repo = ref.read(ownerMonetizationRepositoryProvider);
      return repo.fetchSponsorshipCatalog(businessId: businessId);
    });

class OwnerKpiOverviewCard extends ConsumerWidget {
  const OwnerKpiOverviewCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kpiAsync = ref.watch(ownerKpiSummaryProvider(businessId));

    return AppCard(
      child: kpiAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ownerDashboardKpiLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 8),
          ],
        ),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (kpi) {
          if (businessId == null || businessId!.isEmpty) {
            return Text(
              l10n.ownerDashboardSelectBusinessForKpi,
              style: const TextStyle(color: AppColors.muted),
            );
          }
          if (kpi == null) {
            return Text(
              l10n.ownerDashboardKpiNotFound,
              style: const TextStyle(color: AppColors.muted),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ownerDashboardKpiLast30Days,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OwnerStatCard(
                    title: l10n.ownerDashboardViews,
                    value: '${kpi.businessViews}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardClicks,
                    value: '${kpi.outboundClicks}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardDirections,
                    value: '${kpi.directionsClicks}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardSearchImpressions,
                    value: '${kpi.searchImpressions}',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerAnalyticsPreviewCard extends ConsumerWidget {
  const OwnerAnalyticsPreviewCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final growthAsync = ref.watch(ownerGrowthSummaryProvider(businessId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ownerDashboardAnalyticsTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.ownerDashboardAnalyticsDescription,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: businessId == null || businessId!.isEmpty
                    ? null
                    : () => context.go('/owner/analytics?businessId=$businessId'),
                icon: const Icon(Icons.open_in_new_outlined),
                label: Text(l10n.ownerDashboardOpenAnalyticsAction),
              ),
            ],
          ),
          const SizedBox(height: 12),
          growthAsync.when(
            loading: () => const OwnerPanelFeedback.loading(cardCount: 2),
            error: (error, _) => OwnerPanelFeedback.error(
              title: l10n.ownerDashboardAnalyticsLoadErrorTitle,
              description: error.toString(),
            ),
            data: (growth) {
              if (businessId == null || businessId!.isEmpty) {
                return Text(
                  l10n.ownerDashboardAnalyticsSelectBusiness,
                  style: const TextStyle(color: AppColors.muted),
                );
              }
              if (growth == null) {
                return Text(
                  l10n.ownerDashboardAnalyticsNotFound,
                  style: const TextStyle(color: AppColors.muted),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OwnerStatCard(
                    title: l10n.ownerAnalyticsQrScansTitle,
                    value: '${growth.qrScans}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerAnalyticsMenuOpensTitle,
                    value: '${growth.menuViews}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardAnalyticsOutboundClicks,
                    value: '${growth.outboundClicks}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardAnalyticsConversions,
                    value: '${growth.conversions}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class OwnerGrowthSignalsCard extends ConsumerWidget {
  const OwnerGrowthSignalsCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final growthAsync = ref.watch(ownerGrowthSummaryProvider(businessId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ownerGrowthSignalsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerGrowthSignalsDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          growthAsync.when(
            loading: () => const OwnerPanelFeedback.loading(cardCount: 2),
            error: (error, _) => OwnerPanelFeedback.error(
              title: l10n.ownerDashboardAnalyticsLoadErrorTitle,
              description: error.toString(),
            ),
            data: (growth) {
              if (businessId == null || businessId!.isEmpty) {
                return Text(
                  l10n.ownerDashboardAnalyticsSelectBusiness,
                  style: const TextStyle(color: AppColors.muted),
                );
              }
              if (growth == null) {
                return Text(
                  l10n.ownerStatsNotFound,
                  style: const TextStyle(color: AppColors.muted),
                );
              }

              final conversionRate = growth.searchImpressions > 0
                  ? (growth.conversions / growth.searchImpressions) * 100.0
                  : 0.0;
              final districtGap = growth.districtPriceGapPct == null
                  ? l10n.ownerPricePositionNoData
                  : '%${growth.districtPriceGapPct!.abs().toStringAsFixed(0)}';

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OwnerStatCard(
                    title: l10n.ownerMetricSearchImpressions,
                    value: '${growth.searchImpressions}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerGrowthConversionRateLabel,
                    value: '${conversionRate.toStringAsFixed(1)}%',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardAnalyticsOutboundClicks,
                    value: l10n.ownerOutboundClicksValue(
                      growth.outboundClicks,
                      growth.reservationClicks,
                      growth.orderClicks,
                    ),
                  ),
                  OwnerStatCard(
                    title: l10n.ownerMetricPriceDropoff,
                    value: '${growth.priceDropoffEstimate}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerGrowthDistrictGapLabel,
                    value: districtGap,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerMetricPriceVsCompetitors,
                    value: ownerPricePositionLabel(
                      context,
                      growth.districtPricePosition,
                      growth.districtPriceGapPct,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class OwnerQualityScoreCard extends ConsumerWidget {
  const OwnerQualityScoreCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scoreAsync = ref.watch(ownerQualityScoreProvider(businessId));

    return AppCard(
      child: scoreAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ownerDashboardQualityScoreLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 8),
          ],
        ),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (quality) {
          if (businessId == null || businessId!.isEmpty) {
            return Text(
              l10n.ownerDashboardSelectBusinessForScore,
              style: const TextStyle(color: AppColors.muted),
            );
          }
          if (quality == null) {
            return Text(
              l10n.ownerDashboardScoreNotFound,
              style: const TextStyle(color: AppColors.muted),
            );
          }

          final progress = (quality.score / 100).clamp(0, 1).toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ownerDashboardMenuQualityScore(quality.score),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                quality.score >= 80
                    ? l10n.ownerDashboardScoreGood
                    : l10n.ownerDashboardScoreTarget,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (quality.tips.isEmpty)
                Text(l10n.ownerDashboardNoExtraTasks)
              else
                ...quality.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerMoatCard extends ConsumerWidget {
  const OwnerMoatCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final moatAsync = ref.watch(ownerMoatSummaryProvider(businessId));

    return AppCard(
      child: moatAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ownerDashboardMoatLoading,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 8),
          ],
        ),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (moat) {
          if (businessId == null || businessId!.isEmpty) {
            return Text(
              l10n.ownerDashboardSelectBusinessForMoat,
              style: const TextStyle(color: AppColors.muted),
            );
          }
          if (moat == null) {
            return Text(
              l10n.ownerDashboardMoatNotFound,
              style: const TextStyle(color: AppColors.muted),
            );
          }

          final signalsText = l10n.ownerDashboardSignals(moat.uniqueValidators);
          final lastVerificationText = moat.lastPriceVerificationAt == null
              ? null
              : l10n.ownerDashboardLastVerification(
                  _fmtDateTime(moat.lastPriceVerificationAt!),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ownerDashboardLongTermDefense,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.ownerDashboardLongTermDefenseDescription,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OwnerStatCard(
                    title: l10n.ownerDashboardBusinessTrust,
                    value: '${moat.businessTrustScore}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardMenuFreshness,
                    value: '${moat.menuFreshnessScore}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardPriceAccuracy,
                    value: '${moat.priceAccuracyScore}',
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardContributionTrust,
                    value: '${moat.contributionTrustScore}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                lastVerificationText == null
                    ? signalsText
                    : '$signalsText - $lastVerificationText',
                style: const TextStyle(color: AppColors.textStrong),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.ownerDashboardEvidenceSummary(
                  (moat.evidenceRate * 100).round(),
                  (moat.contributionQualityRate * 100).round(),
                ),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                moat.districtRank == null
                    ? l10n.ownerDashboardLocalMicroData(moat.menuViewsToday)
                    : l10n.ownerDashboardLocalMicroDataWithRank(
                        moat.menuViewsToday,
                        moat.districtRank!,
                      ),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OwnerOperationsQuickActionsCard extends StatelessWidget {
  const OwnerOperationsQuickActionsCard({
    super.key,
    required this.businessId,
  });

  final String? businessId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ownerDashboardOperationsActionsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerDashboardOperationsActionsDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (businessId == null || businessId!.isEmpty) ...[
            Text(
              l10n.ownerDashboardSelectBusinessForActions,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/owner/businesses'),
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n.ownerBusinessesTitle),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/owner/menus?businessId=$businessId'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.ownerMenuManagementTitle),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/owner/growth?businessId=$businessId'),
                  icon: const Icon(Icons.trending_up_outlined),
                  label: Text(l10n.ownerShellGrowthLabel),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/owner/price-suggestions?businessId=$businessId',
                  ),
                  icon: const Icon(Icons.price_check_outlined),
                  label: Text(l10n.ownerShellPriceSuggestionsLabel),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/owner/suspended?businessId=$businessId'),
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: Text(l10n.ownerShellSuspendedClaimsLabel),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/owner/team?businessId=$businessId'),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: Text(l10n.ownerShellTeamLabel),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/owner/activity?businessId=$businessId'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l10n.ownerShellActivityLabel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class OwnerSponsorshipCatalogCard extends ConsumerWidget {
  const OwnerSponsorshipCatalogCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalogAsync = ref.watch(ownerSponsorshipCatalogProvider(businessId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ownerGrowthCatalogTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerGrowthCatalogDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          catalogAsync.when(
            loading: () => const OwnerPanelFeedback.loading(cardCount: 2),
            error: (error, _) => OwnerPanelFeedback.error(
              title: l10n.ownerGrowthCatalogLoadErrorTitle,
              description: error.toString(),
            ),
            data: (items) {
              if (businessId == null || businessId!.isEmpty) {
                return Text(
                  l10n.ownerDashboardSelectBusinessFirst,
                  style: const TextStyle(color: AppColors.muted),
                );
              }
              if (items.isEmpty) {
                return Text(
                  l10n.ownerGrowthCatalogEmpty,
                  style: const TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                children: [
                  for (final item in items)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.packageName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ownerSponsorshipSurfaceLabel(
                                        context,
                                        item.surface,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.priceDisplay.isNotEmpty
                                    ? item.priceDisplay
                                    : _formatOwnerMoneyCents(
                                        item.priceCents,
                                        item.currencyCode,
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OwnerStatCard(
                                title: l10n.ownerGrowthCatalogDurationLabel,
                                value: l10n.adminSponsorshipPackagesDurationValue(
                                  item.durationDays,
                                ),
                              ),
                              OwnerStatCard(
                                title: l10n.ownerGrowthCatalogInventoryLabel,
                                value: l10n.ownerGrowthCatalogInventoryValue(
                                  item.surfaceOpenSlots,
                                  item.inventoryLimit,
                                ),
                              ),
                              OwnerStatCard(
                                title: l10n.ownerGrowthCatalogLiveUnitsLabel,
                                value: l10n.ownerGrowthCatalogLiveUnitsValue(
                                  item.surfaceLiveUnits,
                                  item.businessLiveUnits,
                                ),
                              ),
                              OwnerStatCard(
                                title: l10n.ownerGrowthCatalogReachLabel,
                                value: l10n.ownerGrowthCatalogReachValue(
                                  item.businessImpressions30d,
                                  item.businessUniqueUsers30d,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.ownerGrowthCatalogLeadStatus(
                              ownerSponsorshipLeadStatusLabel(
                                context,
                                item.latestLeadStatus,
                              ),
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class OwnerProLeadCard extends ConsumerStatefulWidget {
  const OwnerProLeadCard({super.key, required this.businessId});

  final String? businessId;

  @override
  ConsumerState<OwnerProLeadCard> createState() => _OwnerProLeadCardState();
}

class _OwnerProLeadCardState extends ConsumerState<OwnerProLeadCard> {
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _impressionsCtrl = TextEditingController();
  var _surface = 'discovery';
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _categoryCtrl.dispose();
    _budgetCtrl.dispose();
    _impressionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ownerDashboardProTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ownerDashboardProDescription,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _featureRow(l10n.ownerDashboardProFeatureSponsoredLabel),
          _featureRow(l10n.ownerDashboardProFeatureAdvancedAnalytics),
          _featureRow(l10n.ownerDashboardProFeatureCampaignAreas),
          _featureRow(l10n.ownerDashboardProFeatureFeaturedPlacement),
          _featureRow(l10n.ownerDashboardProFeatureMultiBranch),
          const SizedBox(height: 12),
          Text(
            l10n.ownerDashboardProDisclaimer,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_surface),
            initialValue: _surface,
            items: [
              DropdownMenuItem(
                value: 'discovery',
                child: Text(l10n.ownerDashboardSurfaceDiscovery),
              ),
              DropdownMenuItem(
                value: 'business_page',
                child: Text(l10n.ownerDashboardSurfaceBusinessPage),
              ),
              DropdownMenuItem(
                value: 'stories',
                child: Text(l10n.ownerDashboardSurfaceStories),
              ),
              DropdownMenuItem(
                value: 'verified',
                child: Text(l10n.ownerDashboardSurfaceVerified),
              ),
              DropdownMenuItem(
                value: 'premium',
                child: Text(l10n.ownerDashboardSurfacePremium),
              ),
            ],
            onChanged: (value) => setState(() => _surface = value ?? 'discovery'),
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardPreferredSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityCtrl,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardTargetCities,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _districtCtrl,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardTargetDistricts,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryCtrl,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardTargetCategories,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardMonthlyBudgetOptional,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _impressionsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardMonthlyImpressionsOptional,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.ownerDashboardPhoneOptional,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.ownerDescriptionOptional,
              hintText: l10n.ownerDashboardNoteHint,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _submitProLead(context, widget.businessId),
              child: Text(
                _submitting
                    ? l10n.ownerDashboardSubmitting
                    : l10n.ownerDashboardSubmitProLead,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _submitProLead(BuildContext context, String? businessId) async {
    final l10n = context.l10n;
    if (businessId == null || businessId.isEmpty) {
      setState(() => _error = l10n.ownerDashboardSelectBusinessFirst);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(ownerMonetizationRepositoryProvider);
      final targeting = <String, dynamic>{};
      final cities = _parseList(_cityCtrl.text);
      if (cities.isNotEmpty) targeting['city'] = cities;
      final districts = _parseList(_districtCtrl.text);
      if (districts.isNotEmpty) targeting['district'] = districts;
      final categories = _parseList(_categoryCtrl.text);
      if (categories.isNotEmpty) targeting['category'] = categories;
      final budget = _parseInt(_budgetCtrl.text);
      if (budget != null) targeting['monthly_budget'] = budget;
      final impressions = _parseInt(_impressionsCtrl.text);
      if (impressions != null) targeting['monthly_impressions'] = impressions;
      await repo.submitSponsorshipLead(
        businessId: businessId,
        phone: _phoneCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        preferredSurface: _surface,
        preferredTargeting: targeting,
      );
      if (!context.mounted) return;
      _phoneCtrl.clear();
      _messageCtrl.clear();
      _cityCtrl.clear();
      _districtCtrl.clear();
      _categoryCtrl.clear();
      _budgetCtrl.clear();
      _impressionsCtrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(l10n.ownerDashboardRequestReceived)),
      );
    } catch (error) {
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<String> _parseList(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  int? _parseInt(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}

class OwnerStatCard extends StatelessWidget {
  const OwnerStatCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

String ownerPricePositionLabel(
  BuildContext context,
  String position,
  double? gapPct,
) {
  final pctText = gapPct == null ? '' : ' (%${gapPct.abs().toStringAsFixed(0)})';
  return switch (position) {
    'higher' => context.l10n.ownerPricePositionHigher(pctText),
    'lower' => context.l10n.ownerPricePositionLower(pctText),
    'similar' => context.l10n.ownerPricePositionSimilar,
    _ => context.l10n.ownerPricePositionNoData,
  };
}

String _fmtDateTime(DateTime value) {
  String two(int input) => input.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

String ownerSponsorshipSurfaceLabel(BuildContext context, String surface) {
  final l10n = context.l10n;
  return switch (surface) {
    'discovery' => l10n.ownerDashboardSurfaceDiscovery,
    'business_page' => l10n.ownerDashboardSurfaceBusinessPage,
    'stories' => l10n.ownerDashboardSurfaceStories,
    'verified' => l10n.ownerDashboardSurfaceVerified,
    'premium' => l10n.ownerDashboardSurfacePremium,
    _ => surface,
  };
}

String ownerSponsorshipLeadStatusLabel(BuildContext context, String? status) {
  final l10n = context.l10n;
  return switch (status) {
    'new' => l10n.adminSponsorshipLeadStatusNew,
    'contacted' => l10n.adminSponsorshipLeadStatusContacted,
    'closed' => l10n.adminSponsorshipLeadStatusClosed,
    null || '' => l10n.ownerGrowthCatalogLeadStatusNone,
    _ => status,
  };
}

String _formatOwnerMoneyCents(int amount, String currencyCode) {
  final whole = amount / 100;
  return '${whole.toStringAsFixed(2)} $currencyCode';
}
