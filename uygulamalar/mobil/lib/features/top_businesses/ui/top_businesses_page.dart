import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/assets/category_assets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/notifications/ui/components/notifications_bell.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import 'widgets/top_business_ranked_tile.dart';
import '../domain/top_businesses_page_controller.dart';

enum _CategoryFilter { all, foodDrink, cafes, dessert, other }

class TopBusinessesPage extends ConsumerStatefulWidget {
  const TopBusinessesPage({super.key, required this.period});
  final String period;

  @override
  ConsumerState<TopBusinessesPage> createState() => _TopBusinessesPageState();
}

class _TopBusinessesPageState extends ConsumerState<TopBusinessesPage> {
  _CategoryFilter _filter = _CategoryFilter.all;

  static const _foodDrinkSlugs = {
    'restoran', 'restaurant', 'balik', 'fish', 'et', 'meat',
    'balik et', 'fish meat', 'kahvalti', 'breakfast',
  };
  static const _cafeSlugs = {'kafe', 'cafe'};
  static const _dessertSlugs = {'tatlici', 'dessert'};

  _CategoryFilter _groupFor(String? category) {
    final slug = CategoryAssets.normalize(category);
    if (_foodDrinkSlugs.contains(slug)) return _CategoryFilter.foodDrink;
    if (_cafeSlugs.contains(slug)) return _CategoryFilter.cafes;
    if (_dessertSlugs.contains(slug)) return _CategoryFilter.dessert;
    return _CategoryFilter.other;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final period = widget.period;
    final async = ref.watch(topBusinessesListProvider(period));
    final title = period == 'month'
        ? t.bestBusinessesThisMonth
        : t.bestBusinessesThisWeek;

    return AppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(topBusinessesListProvider(period).notifier)
              .refresh(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _TopBusinessesHeader(title: title),
              const SizedBox(height: 12),
              const _TopBusinessesPromoBanner(),
              const SizedBox(height: 12),
              _PeriodToggle(period: period),
              const SizedBox(height: 12),
              _CategoryFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 12),
              ...async.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [
                  Text(
                    AppErrorMapper.message(e),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(topBusinessesListProvider(period).notifier)
                        .refresh(force: true),
                    child: Text(t.retry),
                  ),
                ],
                data: (list) {
                  final filtered = _filter == _CategoryFilter.all
                      ? list
                      : list
                          .where((b) => _groupFor(b.category) == _filter)
                          .toList();
                  if (filtered.isEmpty) {
                    return [
                      const SizedBox(height: 20),
                      Text(
                        t.topBusinessesNotEnoughData,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ];
                  }
                  return [
                    for (var i = 0; i < filtered.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      TopBusinessRankedTile(
                        item: filtered[i],
                        rank: i + 1,
                        onTap: () => context.go('/b/${filtered[i].id}'),
                      ),
                    ],
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBusinessesHeader extends StatelessWidget {
  const _TopBusinessesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Merhaba! 👋',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Bildirim Kutusu',
          onPressed: () => context.go('/inbox'),
          icon: const NotificationsBell(),
        ),
      ],
    );
  }
}

class _TopBusinessesPromoBanner extends StatelessWidget {
  const _TopBusinessesPromoBanner();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(tokens.radius20),
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'En çok değerlendirilen ve favorilenen işletmeleri keşfet!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'week', label: Text('Bu Hafta')),
        ButtonSegment(value: 'month', label: Text('Bu Ay')),
      ],
      selected: {period},
      onSelectionChanged: (selection) =>
          context.go('/top-businesses?period=${selection.first}'),
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({required this.selected, required this.onSelected});

  final _CategoryFilter selected;
  final ValueChanged<_CategoryFilter> onSelected;

  static const _labels = {
    _CategoryFilter.all: 'Tümü',
    _CategoryFilter.foodDrink: 'Yeme & İçme',
    _CategoryFilter.cafes: 'Kafeler',
    _CategoryFilter.dessert: 'Tatlı',
    _CategoryFilter.other: 'Diğer',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _CategoryFilter.values.map((f) {
        return AppFilterChip(
          label: _labels[f]!,
          selected: selected == f,
          onTap: () => onSelected(f),
        );
      }).toList(),
    );
  }
}
