import 'package:yeedoy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../src/ui/components/app_appbar.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../domain/compare_controller.dart';
import '../domain/compare_provider.dart';
import '../../../src/ui/design_system.dart';

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  String? _bestPickId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ids = ref.watch(compareControllerProvider);
    final compareAsync = ref.watch(compareBusinessesProvider);
    final bestPick = _bestPickId;

    return AppScaffold(
      appBar: AppAppBar(
        title: const Text('KarÃ…Å¸Ã„Â±laÃ…Å¸tÃ„Â±rma'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppErrorMapper.message(e))),
        data: (items) {
          if (ids.isEmpty) {
            return Center(
              child: AppEmptyState(
                icon: Icons.compare_arrows,
                title: 'KarÃ…Å¸Ã„Â±laÃ…Å¸tÃ„Â±rma boÃ…Å¸',
                description:
                    'Ã„Â°Ã…Å¸letme sayfalarÃ„Â±ndan karÃ…Å¸Ã„Â±laÃ…Å¸tÃ„Â±rmaya ekle.',
                ctaLabel: 'KeÃ…Å¸fe dÃƒÂ¶n',
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
                    child: const Text('En mantÃ„Â±klÃ„Â± seÃƒÂ§imi gÃƒÂ¶ster'),
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
                                color: AppColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Ãƒâ€“neri',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
                        label: 'Median fiyat',
                        value: _formatPriceFromCents(item.medianPriceCents),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: 'Verified oranÃ„Â±',
                        value: _formatRatio(item.verifiedRatio),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: 'Son gÃƒÂ¼ncelleme',
                        value: _formatDate(item.lastUpdateAt),
                      ),
                      if ((item.cheapestItemName ?? '').isNotEmpty &&
                          item.cheapestItemPriceCents != null) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Uygun item',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.cheapestItemName} Ã‚Â· ${_formatPriceFromCents(item.cheapestItemPriceCents)}',
                          style: const TextStyle(color: AppColors.slate),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                context.go('/b/${item.businessId}'),
                            child: const Text('Ã„Â°Ã…Å¸letmeye git'),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'KaldÃ„Â±r',
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
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Ãƒâ€“neri: ${best.name}')));
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

