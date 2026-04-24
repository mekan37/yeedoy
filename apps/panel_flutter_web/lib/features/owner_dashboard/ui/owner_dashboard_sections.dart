import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
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
        error: (error, _) => OwnerPanelFeedback.error(
          title: 'KPI özeti yüklenemedi',
          description: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(ownerKpiSummaryProvider(businessId)),
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
                    icon: Icons.visibility_outlined,
                    iconColor: AppColors.info,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardClicks,
                    value: '${kpi.outboundClicks}',
                    icon: Icons.touch_app_rounded,
                    iconColor: AppColors.primary,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardDirections,
                    value: '${kpi.directionsClicks}',
                    icon: Icons.near_me_outlined,
                    iconColor: AppColors.success,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardSearchImpressions,
                    value: '${kpi.searchImpressions}',
                    icon: Icons.search_rounded,
                    iconColor: AppColors.warning,
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
              description: AppErrorMapper.message(error),
              onRetry: () => ref.invalidate(ownerGrowthSummaryProvider(businessId)),
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
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: AppColors.primary,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerAnalyticsMenuOpensTitle,
                    value: '${growth.menuViews}',
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.info,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardAnalyticsOutboundClicks,
                    value: '${growth.outboundClicks}',
                    icon: Icons.touch_app_rounded,
                    iconColor: AppColors.success,
                  ),
                  OwnerStatCard(
                    title: l10n.ownerDashboardAnalyticsConversions,
                    value: '${growth.conversions}',
                    icon: Icons.swap_horiz_rounded,
                    iconColor: AppColors.warning,
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
              description: AppErrorMapper.message(error),
              onRetry: () => ref.invalidate(ownerGrowthSummaryProvider(businessId)),
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
        error: (error, _) => OwnerPanelFeedback.error(
          title: 'Kalite skoru yüklenemedi',
          description: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(ownerQualityScoreProvider(businessId)),
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
        error: (error, _) => OwnerPanelFeedback.error(
          title: 'Savunma özeti yüklenemedi',
          description: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(ownerMoatSummaryProvider(businessId)),
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
    final bid = businessId;
    final noAccess = bid == null || bid.isEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ownerDashboardOperationsActionsTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.ownerDashboardOperationsActionsDescription,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (noAccess) ...[
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
          ] else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickTile(
                  icon: Icons.menu_book_outlined,
                  label: l10n.ownerMenuManagementTitle,
                  primary: true,
                  onTap: () => context.go('/owner/menus?businessId=$bid'),
                ),
                _QuickTile(
                  icon: Icons.trending_up_outlined,
                  label: l10n.ownerShellGrowthLabel,
                  primary: true,
                  onTap: () => context.go('/owner/growth?businessId=$bid'),
                ),
                _QuickTile(
                  icon: Icons.price_check_outlined,
                  label: l10n.ownerShellPriceSuggestionsLabel,
                  onTap: () => context.go('/owner/price-suggestions?businessId=$bid'),
                ),
                _QuickTile(
                  icon: Icons.volunteer_activism_outlined,
                  label: l10n.ownerShellSuspendedClaimsLabel,
                  onTap: () => context.go('/owner/suspended?businessId=$bid'),
                ),
                _QuickTile(
                  icon: Icons.manage_accounts_outlined,
                  label: l10n.ownerShellTeamLabel,
                  onTap: () => context.go('/owner/team?businessId=$bid'),
                ),
                _QuickTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.ownerShellActivityLabel,
                  onTap: () => context.go('/owner/activity?businessId=$bid'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppColors.primarySoft : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: primary ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primary ? AppColors.primary : AppColors.textStrong,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
              description: AppErrorMapper.message(error),
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
              AppErrorMapper.message(_error),
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
  const OwnerStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.trend,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  /// Optional trend indicator: positive, negative, or null
  final bool? trend;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: effectiveIconColor),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 4),
                Icon(
                  trend! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: trend! ? AppColors.success : AppColors.danger,
                ),
              ],
            ],
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

// ─── Growth bar chart ────────────────────────────────────────────────────────

class OwnerGrowthBarChartCard extends ConsumerWidget {
  const OwnerGrowthBarChartCard({super.key, required this.businessId});

  final String? businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seriesAsync = ref.watch(ownerGrowthSeriesProvider(businessId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ownerGrowthBarChartTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ownerGrowthBarChartSubtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: AppColors.primary,
                label: l10n.ownerAnalyticsMenuOpensTitle,
              ),
              _LegendDot(
                color: AppColors.info,
                label: l10n.ownerAnalyticsQrScansTitle,
              ),
              _LegendDot(
                color: AppColors.success,
                label: l10n.ownerDashboardAnalyticsOutboundClicks,
              ),
            ],
          ),
          const SizedBox(height: 12),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => OwnerPanelFeedback.error(
              title: l10n.ownerDashboardAnalyticsLoadErrorTitle,
              description: AppErrorMapper.message(e),
              onRetry: () =>
                  ref.invalidate(ownerGrowthSeriesProvider(businessId)),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      l10n.ownerDashboardAnalyticsNotFound,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 180,
                child: _GrowthBarChart(rows: rows),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

class _GrowthBarChart extends StatelessWidget {
  const _GrowthBarChart({required this.rows});

  final List<OwnerGrowthDayRow> rows;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrowthBarPainter(
        rows: rows,
        primaryColor: AppColors.primary,
        secondaryColor: AppColors.info,
        tertiaryColor: AppColors.success,
        gridColor: AppColors.border,
        labelColor: AppColors.muted,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _GrowthBarPainter extends CustomPainter {
  const _GrowthBarPainter({
    required this.rows,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<OwnerGrowthDayRow> rows;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color gridColor;
  final Color labelColor;

  static const double _leftPad = 40;
  static const double _bottomPad = 28;
  static const double _rightPad = 8;
  static const double _topPad = 8;
  static const int _seriesCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;

    final maxVal = rows.fold<int>(1, (m, r) {
      final top = [r.menuViews, r.qrScans, r.outboundClicks]
          .fold<int>(0, (a, b) => b > a ? b : a);
      return top > m ? top : m;
    });

    double yOf(int v) => _topPad + chartH * (1 - v / maxVal);

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: labelColor, fontSize: 10);

    const gridCount = 4;
    for (var i = 0; i <= gridCount; i++) {
      final y = _topPad + chartH * i / gridCount;
      canvas.drawLine(
          Offset(_leftPad, y), Offset(size.width - _rightPad, y), gridPaint);
      final val = (maxVal * (1 - i / gridCount)).round();
      _drawText(canvas, '$val', Offset(0, y - 6), labelStyle, width: 36);
    }

    // Bars
    final n = rows.length;
    final groupW = chartW / n;
    final barPad = groupW * 0.08;
    final barW = ((groupW - barPad * 2) / _seriesCount).clamp(2.0, 18.0);
    final colors = [primaryColor, secondaryColor, tertiaryColor];
    final getters = [
      (OwnerGrowthDayRow r) => r.menuViews,
      (OwnerGrowthDayRow r) => r.qrScans,
      (OwnerGrowthDayRow r) => r.outboundClicks,
    ];

    for (var gi = 0; gi < n; gi++) {
      final row = rows[gi];
      final groupX = _leftPad + gi * groupW + barPad;

      for (var si = 0; si < _seriesCount; si++) {
        final val = getters[si](row);
        if (val == 0) continue;
        final x = groupX + si * barW;
        final top = yOf(val);
        final bottom = _topPad + chartH;
        final rect = Rect.fromLTWH(x, top, barW - 1, bottom - top);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()..color = colors[si].withValues(alpha: 0.85),
        );
      }

      // X labels — show every ~7 days
      final step = (n / 5).ceil().clamp(1, n);
      if (gi % step == 0) {
        final label =
            '${row.day.month}/${row.day.day}';
        _drawText(
          canvas,
          label,
          Offset(groupX + groupW / 2 - 14, size.height - _bottomPad + 6),
          labelStyle,
          width: 28,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    double width = 60,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_GrowthBarPainter old) =>
      old.rows != rows || old.primaryColor != primaryColor;
}
