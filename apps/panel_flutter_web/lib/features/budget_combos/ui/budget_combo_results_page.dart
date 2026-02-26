import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../domain/budget_combo_models.dart';
import '../domain/budget_combo_provider.dart';
import '../../../src/ui/design_system.dart';

class BudgetComboResultsPage extends ConsumerStatefulWidget {
  const BudgetComboResultsPage({
    super.key,
    required this.city,
    required this.district,
    required this.partySize,
    required this.budgetTotalCents,
    this.category,
    this.radiusKm,
  });

  final String city;
  final String district;
  final int partySize;
  final int budgetTotalCents;
  final String? category;
  final double? radiusKm;

  @override
  ConsumerState<BudgetComboResultsPage> createState() =>
      _BudgetComboResultsPageState();
}

class _BudgetComboResultsPageState
    extends ConsumerState<BudgetComboResultsPage> {
  double _weightDistance = 0.35;
  double _weightPrice = 0.45;
  double _weightRating = 0.2;

  void _resetWeights() {
    setState(() {
      _weightDistance = 0.35;
      _weightPrice = 0.45;
      _weightRating = 0.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    final district = widget.district;
    final partySize = widget.partySize;
    final budgetTotalCents = widget.budgetTotalCents;
    final category = widget.category;

    if (city.trim().isEmpty ||
        district.trim().isEmpty ||
        budgetTotalCents <= 0) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Bütçe Kombinleri')),
        body: AppEmptyState(
          icon: Icons.info_outline,
          title: 'Eksik bilgi',
          description: 'Lütfen bütçe ve konum bilgisini girin.',
        ),
      );
    }

    final query = BudgetComboQuery(
      city: city,
      district: district,
      partySize: partySize,
      budgetTotalCents: budgetTotalCents,
      category: category,
      limit: 30,
    );
    final async = ref.watch(budgetCombosProvider(query));

    return AppScaffold(
      appBar: AppBar(title: const Text('Bütçe Kombinleri')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppErrorMapper.message(err))),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.search_off_outlined,
              title: 'Henüz uygun kombin yok',
              description:
                  'Bütçeyi artırmayı ya da kişi sayısını azaltmayı deneyin.',
            );
          }

          final sorted = _sortWithWeights(items);
          final display = sorted.take(5).toList();
          final best = display.first;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Kriter değiştir',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetWeights,
                          child: const Text('Varsayılan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.radiusKm == null
                          ? 'Yakınlık filtresi şehir/ilçe düzeyinde uygulanır.'
                          : 'Yakınlık hedefi: ${widget.radiusKm!.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _WeightChip(label: 'Mesafe', value: _weightDistance),
                        _WeightChip(label: 'Fiyat', value: _weightPrice),
                        _WeightChip(label: 'Puan', value: _weightRating),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeightSlider(
                      label: 'Mesafe',
                      value: _weightDistance,
                      onChanged: (v) => setState(() => _weightDistance = v),
                    ),
                    const SizedBox(height: 6),
                    _WeightSlider(
                      label: 'Fiyat',
                      value: _weightPrice,
                      onChanged: (v) => setState(() => _weightPrice = v),
                    ),
                    const SizedBox(height: 6),
                    _WeightSlider(
                      label: 'Puan',
                      value: _weightRating,
                      onChanged: (v) => setState(() => _weightRating = v),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mesafe/puan verisi yoksa sıralama fiyata göre yapılır.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'En uygun kombin',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Tag('Top'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ComboCard(item: best, highlight: true),
                  ],
                ),
              ),
              if (display.length > 1) ...[
                const SizedBox(height: 14),
                const Text(
                  'Diğer öneriler',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final item in display.skip(1)) ...[
                  _ComboCard(item: item),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  List<BudgetComboResult> _sortWithWeights(List<BudgetComboResult> items) {
    final priceValues = items.map((e) => e.totalCents).toList();
    final minPrice = priceValues.reduce((a, b) => a < b ? a : b).toDouble();
    final maxPrice = priceValues.reduce((a, b) => a > b ? a : b).toDouble();
    final priceRange = (maxPrice - minPrice).clamp(1, maxPrice).toDouble();

    final distanceValues = items
        .map((e) => e.distanceKm)
        .whereType<double>()
        .toList();
    final minDistance = distanceValues.isEmpty
        ? null
        : distanceValues.reduce((a, b) => a < b ? a : b);
    final maxDistance = distanceValues.isEmpty
        ? null
        : distanceValues.reduce((a, b) => a > b ? a : b);
    final distanceRange = (minDistance == null || maxDistance == null)
        ? null
        : (maxDistance - minDistance).clamp(0.1, 9999.0).toDouble();

    final ratingValues = items
        .map((e) => e.rating)
        .whereType<double>()
        .toList();
    final minRating = ratingValues.isEmpty
        ? null
        : ratingValues.reduce((a, b) => a < b ? a : b);
    final maxRating = ratingValues.isEmpty
        ? null
        : ratingValues.reduce((a, b) => a > b ? a : b);
    final ratingRange = (minRating == null || maxRating == null)
        ? null
        : (maxRating - minRating).clamp(0.1, 10.0).toDouble();

    final weights = [_weightDistance, _weightPrice, _weightRating];
    final totalWeight = weights.fold<double>(0, (a, b) => a + b);
    final wDistance = totalWeight == 0 ? 0.0 : _weightDistance / totalWeight;
    final wPrice = totalWeight == 0 ? 1.0 : _weightPrice / totalWeight;
    final wRating = totalWeight == 0 ? 0.0 : _weightRating / totalWeight;

    double scoreItem(BudgetComboResult item) {
      final priceScore =
          1 - ((item.totalCents.toDouble() - minPrice) / priceRange);

      final parts = <double>[priceScore];
      final weights = <double>[wPrice];

      if (item.distanceKm != null &&
          distanceRange != null &&
          minDistance != null) {
        final distScore =
            1 - ((item.distanceKm! - minDistance) / distanceRange);
        parts.add(distScore);
        weights.add(wDistance);
      }

      if (item.rating != null && ratingRange != null && minRating != null) {
        final rScore = (item.rating! - minRating) / ratingRange;
        parts.add(rScore);
        weights.add(wRating);
      }

      final sumW = weights.fold<double>(0, (a, b) => a + b);
      if (sumW == 0) return priceScore;
      double score = 0;
      for (var i = 0; i < parts.length; i++) {
        score += parts[i] * weights[i];
      }
      return score / sumW;
    }

    final sorted = [...items];
    sorted.sort((a, b) => scoreItem(b).compareTo(scoreItem(a)));
    return sorted;
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.item, this.highlight = false});

  final BudgetComboResult item;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[];
    if (item.distanceKm != null) {
      meta.add('${item.distanceKm!.toStringAsFixed(1)} km');
    }
    if (item.rating != null) {
      meta.add('Puan ${item.rating!.toStringAsFixed(1)}');
    }

    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.businessName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              if (highlight) _Tag('En uygun'),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta.join(' • '),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          _ComboLine(
            label: 'Ana',
            name: item.combo.main.name,
            priceCents: item.combo.main.priceCents,
            currency: item.combo.main.currency,
          ),
          if (item.combo.drink != null) ...[
            const SizedBox(height: 4),
            _ComboLine(
              label: 'İçecek',
              name: item.combo.drink!.name,
              priceCents: item.combo.drink!.priceCents,
              currency: item.combo.drink!.currency,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_formatPrice(item.totalCents)} toplam',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go('/b/${item.businessId}'),
                child: const Text('İşletmeye git'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!highlight) return card;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: card,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textStrong,
        ),
      ),
    );
  }
}

class _ComboLine extends StatelessWidget {
  const _ComboLine({
    required this.label,
    required this.name,
    required this.priceCents,
    required this.currency,
  });

  final String label;
  final String name;
  final int priceCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatPrice(priceCents, currency: currency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: 1,
            divisions: 10,
            value: safeValue,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text('$percent%')),
      ],
    );
  }
}

String _formatPrice(int cents, {String currency = 'TRY'}) {
  final value = (cents / 100).toStringAsFixed(2);
  return '$value $currency';
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label $percent%',
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    );
  }
}

