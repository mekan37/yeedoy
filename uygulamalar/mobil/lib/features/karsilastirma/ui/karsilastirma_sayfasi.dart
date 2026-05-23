import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../domain/karsilastirma_kontrolcusu.dart';
import '../domain/karsilastirma_saglayicisi.dart';

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  String? _bestPickId;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final ids = ref.watch(compareControllerProvider);
    final compareAsync = ref.watch(compareBusinessesProvider);
    final bestPick = _bestPickId;

    return AppScaffold(
      appBar: AppAppBar(
        title: Text(t.comparePageTitle),
        actions: [
          if (ids.isNotEmpty)
            IconButton(
              tooltip: t.temizle,
              onPressed: () =>
                  ref.read(compareControllerProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: compareAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const AppSkeletonCard(),
        ),
        error: (e, _) => Center(child: Text(AppErrorMapper.message(e))),
        data: (items) {
          if (ids.isEmpty) {
            return Center(
              child: AppEmptyState(
                icon: Icons.compare_arrows,
                title: t.compareEmptyTitle,
                description: t.compareEmptyDescription,
                ctaLabel: t.compareBackToDiscover,
                onCta: () => context.go('/discover'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (items.length >= 2)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showBestPick(
                      context,
                      (id) => setState(() => _bestPickId = id),
                      items,
                    ),
                    child: Text(t.compareBestPickAction),
                  ),
                ),
              if (items.length >= 2) const SizedBox(height: 12),
              for (final item in items) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (bestPick == item.businessId)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                t.compareSuggestedBadge,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _locText(item.district, item.city),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: t.compareMedianPriceLabel,
                        value: _formatPriceFromCents(item.medianPriceCents),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: t.compareVerifiedRateLabel,
                        value: _formatRatio(item.verifiedRatio),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: t.compareLastUpdateLabel,
                        value: _formatDate(item.lastUpdateAt),
                      ),
                      if ((item.cheapestItemName ?? '').isNotEmpty &&
                          item.cheapestItemPriceCents != null) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          t.compareBestItemTitle,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.cheapestItemName} · ${_formatPriceFromCents(item.cheapestItemPriceCents)}',
                          style: const TextStyle(color: AppColors.slate),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/isletme/${item.businessId}'),
                            child: Text(t.compareGoToBusinessAction),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: t.compareRemoveTooltip,
                            onPressed: () => ref
                                .read(compareControllerProvider.notifier)
                                .remove(item.businessId),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

void _showBestPick(
  BuildContext context,
  void Function(String?) onPick,
  List<CompareBusiness> items,
) {
  if (items.isEmpty) return;
  CompareBusiness? best;
  double bestScore = double.infinity;
  for (final item in items) {
    final price = item.medianPriceCents ?? 0;
    final ratio = item.verifiedRatio ?? 0;
    final score = price * (1 - ratio);
    if (best == null || score < bestScore) {
      best = item;
      bestScore = score;
    }
  }
  if (best == null) return;
  onPick(best.businessId);
  final t = context.l10n;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(t.compareRecommendedSnack(best.name))));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

String _locText(String district, String city) {
  final d = district.trim();
  final c = city.trim();
  if (d.isEmpty && c.isEmpty) return '-';
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d, $c';
}

String _formatPriceFromCents(int? cents) {
  if (cents == null) return '-';
  final value = (cents / 100).toStringAsFixed(0);
  return '$value TRY';
}

String _formatRatio(double? ratio) {
  if (ratio == null) return '-';
  final percent = (ratio * 100).clamp(0, 100).toStringAsFixed(0);
  return '%$percent';
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}






