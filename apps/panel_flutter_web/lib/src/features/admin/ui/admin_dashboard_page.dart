import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/config/product_guardrail_overrides.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../domain/admin_dashboard_controller.dart';
import '../domain/admin_growth_provider.dart';
import '../domain/admin_kpi_provider.dart';
import '../../../ui/components/app_hero_header.dart';
import '../../../ui/design_system.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(adminDashboardProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1040
            ? 1040.0
            : (constraints.maxWidth >= 720 ? 720.0 : constraints.maxWidth);
        final isWide = constraints.maxWidth >= 900;
        final gap = 12.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _V3QualityGateCard(),
                  const SizedBox(height: 12),
                  AppHeroHeader(
                    title: 'Genel Bakış',
                    subtitle: 'Operasyon ve büyüme metrikleri',
                    icon: Icons.dashboard_outlined,
                    trailing: IconButton(
                      onPressed: () =>
                          ref.read(adminDashboardProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Yenile',
                    ),
                  ),
                  const SizedBox(height: 12),
                  countsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      AppErrorMapper.message(e),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    data: (s) {
                      final cards = [
                        _StatCard(
                          title: 'Açık Raporlar',
                          value: '${s.counts.reportsOpen}',
                        ),
                        _StatCard(
                          title: 'Bekleyen Sahiplik',
                          value: '${s.counts.claimsPending}',
                        ),
                        _StatCard(
                          title: 'Bekleyen Öneriler',
                          value: '${s.counts.suggestionsPending}',
                        ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final card in cards)
                            SizedBox(
                              width: isWide ? (maxWidth - gap) / 2 : maxWidth,
                              child: card,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  countsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (s) {
                      final cards = [
                        _StatCard(
                          title: 'Rapor atama (dk)',
                          value: _fmtMinutes(s.sla.reportsAvgMinutesToAssign),
                        ),
                        _StatCard(
                          title: 'Rapor kapanışı (dk)',
                          value: _fmtMinutes(s.sla.reportsAvgMinutesToClose),
                        ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final card in cards)
                            SizedBox(
                              width: isWide ? (maxWidth - gap) / 2 : maxWidth,
                              child: card,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  countsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (s) {
                      final cards = [
                        _StatCard(
                          title: 'Sahiplik atama (dk)',
                          value: _fmtMinutes(s.sla.claimsAvgMinutesToAssign),
                        ),
                        _StatCard(
                          title: 'Sahiplik karar (dk)',
                          value: _fmtMinutes(s.sla.claimsAvgMinutesToDecide),
                        ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final card in cards)
                            SizedBox(
                              width: isWide ? (maxWidth - gap) / 2 : maxWidth,
                              child: card,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        'Büyüme (30 gün)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ref
                      .watch(adminGrowthSummaryProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text(
                          AppErrorMapper.message(e),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        data: (g) {
                          final cards = [
                            _StatCard(
                              title: 'Menü link açıldı',
                              value: '${g.menuLinkOpened}',
                            ),
                            _StatCard(
                              title: 'QR okutuldu',
                              value: '${g.qrScanned}',
                            ),
                            _StatCard(
                              title: 'Menü paylaşıldı',
                              value: '${g.menuShared}',
                            ),
                            _StatCard(
                              title: 'Uygulama kurulum',
                              value: '${g.appInstallFromMenu}',
                            ),
                          ];
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final card in cards)
                                SizedBox(
                                  width: isWide
                                      ? (maxWidth - gap) / 2
                                      : maxWidth,
                                  child: card,
                                ),
                            ],
                          );
                        },
                      ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        'KPI (30 gün)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ref
                      .watch(adminKpiSummaryProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text(
                          AppErrorMapper.message(e),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        data: (kpi) {
                          final ctr = _fmtPercent(kpi.discoveryCtr);
                          final menuRate = _fmtPercent(kpi.menuViewRate);
                          final priceRate = _fmtPercent(
                            kpi.priceVerificationRate,
                          );
                          final cards = [
                            _StatCard(
                              title: 'DAU',
                              value: _withTrend(
                                '${kpi.dau}',
                                kpi.dau,
                                kpi.dauPrev,
                              ),
                            ),
                            _StatCard(
                              title: 'WAU',
                              value: _withTrend(
                                '${kpi.wau}',
                                kpi.wau,
                                kpi.wauPrev,
                              ),
                            ),
                            _StatCard(
                              title: 'Keşfet â†’ İşletme CTR',
                              value: _withTrend(
                                '$ctr (${kpi.discoveryClicks}/${kpi.discoveryImpressions})',
                                kpi.discoveryCtr,
                                kpi.discoveryCtrPrev,
                              ),
                            ),
                            _StatCard(
                              title: 'İşletme â†’ Menü oranı',
                              value: _withTrend(
                                '$menuRate (${kpi.menuViews}/${kpi.businessViews})',
                                kpi.menuViewRate,
                                kpi.menuViewRatePrev,
                              ),
                            ),
                            _StatCard(
                              title: 'Fiyat doğrulama dönüşümü',
                              value: _withTrend(
                                '$priceRate (${kpi.priceSuggestions}/${kpi.menuViews})',
                                kpi.priceVerificationRate,
                                kpi.priceVerificationRatePrev,
                              ),
                            ),
                            _StatCard(
                              title: 'Rapor çözüm süresi (dk)',
                              value: _withTrend(
                                _fmtMinutes(kpi.reportsAvgResolutionMinutes),
                                kpi.reportsAvgResolutionMinutes,
                                kpi.reportsAvgResolutionMinutesPrev,
                                inverse: true,
                              ),
                            ),
                          ];
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final card in cards)
                                SizedBox(
                                  width: isWide
                                      ? (maxWidth - gap) / 2
                                      : maxWidth,
                                  child: card,
                                ),
                            ],
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _V3QualityGateCard extends ConsumerWidget {
  const _V3QualityGateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(adminDashboardProvider);
    final kpiAsync = ref.watch(adminKpiSummaryProvider);
    final guardrails = ref.watch(productGuardrailOverridesProvider);

    final queueGate = countsAsync.maybeWhen(
      data: (s) =>
          (s.counts.reportsOpen +
              s.counts.claimsPending +
              s.counts.suggestionsPending) <=
          500,
      orElse: () => false,
    );
    final reportSlaGate = countsAsync.maybeWhen(
      data: (s) =>
          s.sla.reportsAvgMinutesToClose > 0 &&
          s.sla.reportsAvgMinutesToClose <= 24 * 60,
      orElse: () => false,
    );
    final priceVerificationGate = kpiAsync.maybeWhen(
      data: (kpi) => kpi.priceVerificationRate >= 0.02,
      orElse: () => false,
    );
    final resolutionGate = kpiAsync.maybeWhen(
      data: (kpi) =>
          kpi.reportsAvgResolutionMinutes > 0 &&
          kpi.reportsAvgResolutionMinutes <= 24 * 60,
      orElse: () => false,
    );

    final scoreCards = <bool>[
      !guardrails.allowLowQualityGrowthBypass,
      guardrails.minSponsoredTrustScore >= 0.35,
      guardrails.requireSponsoredLabel,
      !guardrails.ownerCanDeleteReviews,
      queueGate,
      reportSlaGate,
      priceVerificationGate,
      resolutionGate,
    ];
    final passCount = scoreCards.where((e) => e).length;
    final totalCount = scoreCards.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'V3 Kalite & Guven Kapisi (P0)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yanlış bilgiyi düşür, güveni yükselt. Büyüme için kaliteyi gevsetme.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Canlı kapı: $passCount/$totalCount',
            style: const TextStyle(
              color: AppColors.textStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GateChip(
                label: 'Doğruluk skorları',
                ok: !guardrails.allowLowQualityGrowthBypass,
              ),
              _GateChip(label: 'Fiyat doğrulama', ok: priceVerificationGate),
              _GateChip(label: 'Menü versiyon/geçmiş', ok: true),
              _GateChip(label: 'Yanlış bilgi bildirimi', ok: resolutionGate),
              _GateChip(label: 'İşletme yaşam döngüsü', ok: true),
              _GateChip(
                label: 'Yorum kalite sistemi',
                ok: !guardrails.ownerCanDeleteReviews,
              ),
              _GateChip(label: 'Şimdi açık kontrolü', ok: true),
              _GateChip(label: 'İşletme panel temel', ok: true),
              _GateChip(label: 'Admin kayruk', ok: queueGate && reportSlaGate),
              _GateChip(label: 'Uygulama içi gelen kutusu', ok: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Korkuluk: sponsor etiketi=${guardrails.requireSponsoredLabel}, '
            'min sponsor güveni=${guardrails.minSponsoredTrustScore.toStringAsFixed(2)}, '
            'işletme yorum silme=${guardrails.ownerCanDeleteReviews}, '
            'kalite bypass=${guardrails.allowLowQualityGrowthBypass}.',
            style: const TextStyle(color: AppColors.textStrong, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GateChip extends StatelessWidget {
  const _GateChip({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: label,
      tone: ok ? AppBadgeTone.success : AppBadgeTone.warning,
    );
  }
}

String _fmtMinutes(double v) {
  if (v <= 0) return '—';
  return v.toStringAsFixed(1);
}

String _fmtPercent(double v) {
  if (v <= 0) return '0%';
  return '${(v * 100).clamp(0, 100).toStringAsFixed(1)}%';
}

String _withTrend(
  String value,
  num current,
  num previous, {
  bool inverse = false,
}) {
  if (previous == 0 && current == 0) return value;
  final delta = current - previous;
  if (delta == 0) return '$value •';
  final up = inverse ? delta < 0 : delta > 0;
  return up ? '$value â†‘' : '$value â†“';
}
