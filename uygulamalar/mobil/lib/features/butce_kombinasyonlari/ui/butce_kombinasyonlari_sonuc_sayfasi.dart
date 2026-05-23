import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../domain/butce_kombinasyon_modelleri.dart';
import '../domain/butce_kombinasyon_saglayicisi.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

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
    final t = context.l10n;
    final city = widget.city;
    final district = widget.district;
    final partySize = widget.partySize;
    final budgetTotalCents = widget.budgetTotalCents;
    final category = widget.category;

    if (city.trim().isEmpty ||
        district.trim().isEmpty ||
        budgetTotalCents <= 0) {
      return AppScaffold(
        appBar: AppBar(title: Text(t.budgetComboResultsTitle)),
        body: AppEmptyState(
          icon: Icons.info_outline,
          title: t.budgetComboMissingInfoTitle,
          description: t.budgetComboMissingInfoDescription,
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
      appBar: AppBar(title: Text(t.budgetComboResultsTitle)),
      body: async.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const AppSkeletonCard(),
        ),
        error: (err, _) => Center(child: Text(AppErrorMapper.message(err))),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off_outlined,
              title: t.budgetComboNoResultsTitle,
              description: t.budgetComboNoResultsDescription,
            );
          }

          final sorted = _sortWithWeights(items);
          final display = sorted.take(5).toList();
          final best = display.first;

          // Özet istatistikler
          final toplamlar = sorted.map((e) => e.totalCents).toList();
          final enDusuk = toplamlar.reduce((a, b) => a < b ? a : b);
          final enYuksek = toplamlar.reduce((a, b) => a > b ? a : b);
          final ortalama = toplamlar.fold(0, (a, b) => a + b) ~/ toplamlar.length;
          final tasarruf = ortalama - enDusuk;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // Bütçe Özet Kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Bütçe Analizi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (tasarruf > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₺${(tasarruf / 100).toStringAsFixed(0)} tasarruf',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _BudgetStat(
                          etiket: 'En Ucuz',
                          deger: '₺${(enDusuk / 100).toStringAsFixed(0)}',
                          renk: AppColors.success,
                        ),
                        const Expanded(child: SizedBox()),
                        _BudgetStat(
                          etiket: 'Ortalama',
                          deger: '₺${(ortalama / 100).toStringAsFixed(0)}',
                          renk: AppColors.muted,
                        ),
                        const Expanded(child: SizedBox()),
                        _BudgetStat(
                          etiket: 'En Pahalı',
                          deger: '₺${(enYuksek / 100).toStringAsFixed(0)}',
                          renk: AppColors.warning,
                        ),
                        const Expanded(child: SizedBox()),
                        _BudgetStat(
                          etiket: 'Kişi Başı',
                          deger: widget.partySize > 1
                              ? '₺${(enDusuk / 100 / widget.partySize).toStringAsFixed(0)}'
                              : '—',
                          renk: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.budgetComboAdjustCriteriaTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetWeights,
                          child: Text(t.budgetComboDefaultAction),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.radiusKm == null
                          ? t.budgetComboRadiusDistrictScope
                          : t.budgetComboRadiusTarget(
                              widget.radiusKm!.toStringAsFixed(0),
                            ),
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
                        _WeightChip(
                          label: t.budgetComboWeightDistance,
                          value: _weightDistance,
                        ),
                        _WeightChip(
                          label: t.budgetComboWeightPrice,
                          value: _weightPrice,
                        ),
                        _WeightChip(
                          label: t.budgetComboWeightRating,
                          value: _weightRating,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeightSlider(
                      label: t.budgetComboWeightDistance,
                      value: _weightDistance,
                      onChanged: (v) => setState(() => _weightDistance = v),
                    ),
                    const SizedBox(height: 6),
                    _WeightSlider(
                      label: t.budgetComboWeightPrice,
                      value: _weightPrice,
                      onChanged: (v) => setState(() => _weightPrice = v),
                    ),
                    const SizedBox(height: 6),
                    _WeightSlider(
                      label: t.budgetComboWeightRating,
                      value: _weightRating,
                      onChanged: (v) => setState(() => _weightRating = v),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.budgetComboFallbackSortHint,
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
                        Text(
                          t.budgetComboBestComboTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Tag(t.budgetComboTagTop),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ComboCard(item: best, highlight: true),
                  ],
                ),
              ),
              if (display.length > 1) ...[
                const SizedBox(height: 14),
                Text(
                  t.budgetComboOtherSuggestionsTitle,
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

class _ComboCard extends ConsumerWidget {
  const _ComboCard({required this.item, this.highlight = false});

  final BudgetComboResult item;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final meta = <String>[];
    if (item.distanceKm != null) {
      meta.add('${item.distanceKm!.toStringAsFixed(1)} km');
    }
    if (item.rating != null) {
      meta.add(
        t.budgetComboRatingLabelValue(item.rating!.toStringAsFixed(1)),
      );
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
              if (highlight) _Tag(t.budgetComboBestTag),
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
            label: t.budgetComboMainItemLabel,
            name: item.combo.main.name,
            priceCents: item.combo.main.priceCents,
            currency: item.combo.main.currency,
          ),
          if (item.combo.drink != null) ...[
            const SizedBox(height: 4),
            _ComboLine(
              label: t.budgetComboDrinkItemLabel,
              name: item.combo.drink!.name,
              priceCents: item.combo.drink!.priceCents,
              currency: item.combo.drink!.currency,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                t.budgetComboTotalLabel(_formatPrice(item.totalCents)),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  ref.read(analyticsRepositoryProvider).logEvent(
                    eventName: AppEvents.budgetComboBusinessOpen,
                    businessId: item.businessId,
                    source: 'budget_combo_results',
                  );
                  context.go('/isletme/${item.businessId}');
                },
                child: Text(t.budgetComboGoToBusinessAction),
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

class _BudgetStat extends StatelessWidget {
  final String etiket;
  final String deger;
  final Color renk;
  const _BudgetStat({
    required this.etiket,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          deger,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: renk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiket,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
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






