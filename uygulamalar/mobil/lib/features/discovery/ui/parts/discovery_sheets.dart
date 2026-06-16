part of '../discovery_page.dart';

class _TodayPickSheet extends ConsumerWidget {
  const _TodayPickSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(todayPickProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.whatToEatTitle,
              style: context.sectionTitleStyle,
            ),
            const SizedBox(height: 12),
            if (state.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppErrorMapper.message(state.error),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(todayPickProvider.notifier)
                        .pickOne(force: true),
                    child: Text(t.tekrarDene),
                  ),
                ],
              )
            else if (state.needsLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.locationPermissionRequired,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(todayPickProvider.notifier).requestLocation(),
                    child: Text(t.locationPermissionTitle),
                  ),
                ],
              )
            else if (state.item == null)
              Text(
                t.noFoodFoundForCriteria,
                style: TextStyle(color: AppColors.muted),
              )
            else
              _TodayPickCard(
                item: state.item!,
                onRetry: () =>
                    ref.read(todayPickProvider.notifier).pickOne(force: true),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhatToEatSheet extends ConsumerStatefulWidget {
  const _WhatToEatSheet();

  @override
  ConsumerState<_WhatToEatSheet> createState() => _WhatToEatSheetState();
}

class _WhatToEatSheetState extends ConsumerState<_WhatToEatSheet> {
  final TextEditingController _budgetCtrl = TextEditingController(text: '400');
  int _partySize = 2;
  double _radiusKm = 5;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  int _parseBudgetCents() {
    final raw = _budgetCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return 0;
    return (value * 100).round();
  }

  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  List<BusinessCardModel> _quickChoices({
    required List<BusinessCardModel> items,
    required int totalBudgetCents,
    required int partySize,
    required double radiusKm,
  }) {
    if (items.isEmpty || totalBudgetCents <= 0 || partySize <= 0) {
      return const [];
    }
    final perPersonBudget = totalBudgetCents / partySize;
    final filtered = items.where((b) {
      final distance = b.distanceKm;
      final price = b.medianPriceCents;
      if (distance != null && distance > radiusKm) return false;
      if (price != null && price > 0 && price > (perPersonBudget * 1.15)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      double scoreOf(BusinessCardModel x) {
        final distance = x.distanceKm ?? 20;
        final price = (x.medianPriceCents ?? perPersonBudget).toDouble();
        final openBoost = x.isOpenNow == true ? 35 : 0;
        final distanceScore = (20 - distance.clamp(0, 20)) * 2;
        final priceGap = (perPersonBudget - price).clamp(
          -perPersonBudget,
          perPersonBudget,
        );
        final priceScore = ((priceGap / perPersonBudget) * 20);
        final trustScore = ((x.trustScore ?? 0).clamp(0, 1) * 20);
        return openBoost + distanceScore + priceScore + trustScore;
      }

      return scoreOf(b).compareTo(scoreOf(a));
    });
    return filtered.take(3).toList();
  }

  String _formatCents(int? cents) {
    if (cents == null || cents <= 0) return '---';
    final tl = cents / 100;
    return tl.toStringAsFixed(tl == tl.truncateToDouble() ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final discoveryState = ref.watch(discoverySearchProvider);
    final loc = ref.watch(userLocationProvider);
    final city = (loc.city ?? '').trim();
    final district = (loc.district ?? '').trim();
    final hasLocation = city.isNotEmpty && district.isNotEmpty;
    final budgetCents = _parseBudgetCents();
    final quickChoices = _quickChoices(
      items: discoveryState.items,
      totalBudgetCents: budgetCents,
      partySize: _partySize,
      radiusKm: _radiusKm,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.whatToEatTitle,
              style: context.sectionTitleStyle,
            ),
            const SizedBox(height: 4),
            Text(
              t.whatToEatDescription,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(
              t.stepPeopleCount,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: t.decreaseQuantity,
                  onPressed: _partySize <= 1
                      ? null
                      : () => setState(() => _partySize--),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_partySize',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                IconButton(
                  tooltip: t.increaseQuantity,
                  onPressed: () => setState(() => _partySize++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (quickChoices.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                t.quickDecisionThreeOptions,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              for (final b in quickChoices) ...[
                AppCard(
                  onTap: () => context.go('/b/${b.id}'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.textStrong,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatCents(b.medianPriceCents)}  ${b.distanceKm == null ? '-' : '${b.distanceKm!.toStringAsFixed(1)} km'}  ${b.isOpenNow == true ? t.openNow : t.closedNow}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              t.stepBudgetTotal,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.budgetTl,
                prefixText: '₺ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(t.stepDistance, style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 20,
                    divisions: 19,
                    value: _radiusKm,
                    label: t.nearbyKm(_radiusKm.round()),
                    onChanged: (value) => setState(() => _radiusKm = value),
                  ),
                ),
                Text(t.nearbyKm(_radiusKm.round())),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasLocation ? '$city - $district' : t.locationNotSelected,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openLocationSheet,
                  child: Text(t.selectLocation),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !hasLocation || budgetCents <= 0
                    ? null
                    : () {
                        context.go('/budget-combos');
                      },
                child: Text(t.seeSuggestions),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ref.read(todayPickProvider.notifier).pickOne();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const _TodayPickSheet(),
                  );
                },
                child: Text(t.getSingleSuggestion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
