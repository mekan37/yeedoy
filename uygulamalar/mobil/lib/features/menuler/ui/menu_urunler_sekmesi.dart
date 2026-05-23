import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/hizli_giris_paneli.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../profil/domain/diyet_profil_kontrolcusu.dart';
import '../../fiyat_uyarilari/ui/fiyat_uyari_paneli.dart';
import '../domain/menu_urun_arama_kontrolcusu.dart';
import '../domain/menu_urun_arama_modeli.dart';
import '../domain/menu_urun_arama_durumu.dart';

class MenuItemsTab extends ConsumerStatefulWidget {
  const MenuItemsTab({super.key});

  @override
  ConsumerState<MenuItemsTab> createState() => _MenuItemsTabState();
}

class _MenuItemsTabState extends ConsumerState<MenuItemsTab> {
  final qCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(menuItemSearchProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    qCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final st = ref.watch(menuItemSearchProvider);
    final profileAsync = ref.watch(dietProfileProvider);
    final user = ref.watch(userProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(menuItemSearchProvider.notifier).refresh(),
      child: ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => ref
                      .read(menuItemSearchProvider.notifier)
                      .setQuery(qCtrl.text.trim()),
                  onSubmitted: (_) =>
                      ref.read(menuItemSearchProvider.notifier).refresh(),
                  decoration: InputDecoration(
                    hintText: t.searchFoodHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: qCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: t.kapat,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              qCtrl.clear();
                              ref
                                  .read(menuItemSearchProvider.notifier)
                                  .setQuery('');
                              ref
                                  .read(menuItemSearchProvider.notifier)
                                  .refresh();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: t.filters,
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilters(context, st),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilterChip(
                label: Text(st.profileEnabled ? t.profileActive : t.profile),
                selected: st.profileEnabled,
                onSelected: (value) async {
                  if (user == null) {
                    _redirectToLogin(context);
                    return;
                  }
                  if (profileAsync.isLoading) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t.profileLoading)));
                    return;
                  }
                  if (profileAsync.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppErrorMapper.message(profileAsync.error),
                        ),
                      ),
                    );
                    return;
                  }
                  final profile = profileAsync.asData?.value;
                  if (profile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.dietProfileNotFound)),
                    );
                    return;
                  }
                  await ref
                      .read(menuItemSearchProvider.notifier)
                      .applyProfile(
                        enabled: value,
                        vegan: profile.vegan,
                        vegetarian: profile.vegetarian,
                        glutenFree: profile.glutenFree,
                        lactoseFree: profile.lactoseFree,
                        halal: profile.halal,
                        maxCalories: profile.maxCalories,
                      );
                },
              ),
              const Spacer(),
              if (st.profileEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t.profileActive,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (st.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppErrorMapper.message(st.error),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(menuItemSearchProvider.notifier).refresh(),
                    child: Text(t.retry),
                  ),
                ],
              ),
            ),

          if (st.loading && st.items.isEmpty) ...[
            const _MenuItemsSkeleton(),
          ] else ...[
            for (final item in st.items) ...[
              RepaintBoundary(
                child: _MenuItemCard(
                  item: item,
                  onTap: () => _openMenuItem(context, item),
                  onAlertTap: () => _openPriceAlert(context, item, user != null),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],

          if (st.isLoadingMore)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!st.loading && st.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _EmptyState(
                title: st.needsLocation ? t.allowLocation : t.noResultsFound,
                subtitle: st.needsLocation
                    ? t.allowLocationForNearby
                    : t.tryDifferentSearchOrFilter,
                onLocationTap: st.needsLocation
                    ? () => ref
                          .read(menuItemSearchProvider.notifier)
                          .requestLocation()
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context, MenuItemSearchState st) {
    final manual = st.profileEnabled
        ? (
            st.manualVegan,
            st.manualVegetarian,
            st.manualGlutenFree,
            st.manualLactoseFree,
            st.manualMaxCalories,
          )
        : (
            st.vegan,
            st.vegetarian,
            st.glutenFree,
            st.lactoseFree,
            st.maxCalories,
          );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MenuItemFilterSheet(
        initialRadius: st.radiusKm,
        initialVegan: manual.$1,
        initialVegetarian: manual.$2,
        initialGlutenFree: manual.$3,
        initialLactoseFree: manual.$4,
        initialMaxCalories: manual.$5 ?? 1200,
        profileEnabled: st.profileEnabled,
        initialVerifiedOnly: st.verifiedPriceOnly,
        onApply: (filters) async {
          await ref
              .read(menuItemSearchProvider.notifier)
              .setFilters(
                radiusKm: filters.radiusKm,
                vegan: filters.vegan,
                vegetarian: filters.vegetarian,
                glutenFree: filters.glutenFree,
                lactoseFree: filters.lactoseFree,
                verifiedPriceOnly: filters.verifiedOnly,
                maxCalories: filters.maxCalories,
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _openMenuItem(BuildContext context, MenuItemSearchResult item) {
    if (item.menuId.isEmpty) {
      context.go('/isletme/${item.businessId}');
      return;
    }
    context.go(
      '/isletme/${item.businessId}/menu/${item.menuId}/item/${item.menuItemId}',
    );
  }

  Future<void> _openPriceAlert(
    BuildContext context,
    MenuItemSearchResult item,
    bool isLoggedIn,
  ) async {
    if (!isLoggedIn) {
      _redirectToLogin(context);
      return;
    }
    await showPriceAlertSheet(
      context: context,
      initialQuery: item.name,
      initialCity: item.city,
      initialDistrict: item.district,
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onTap,
    required this.onAlertTap,
  });

  final MenuItemSearchResult item;
  final VoidCallback onTap;
  final VoidCallback onAlertTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatPrice(item.priceCents, locale: t.localeName),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StatusBadge(config: _statusBadge(item.priceStatus, t)),
                  const SizedBox(width: 6),
                  if (item.priceStatus == 'verified' &&
                      (item.total30d ?? 0) > 0) ...[
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      t.localeName.startsWith('tr')
                          ? '${item.total30d} kişi onayladı'
                          : '${item.total30d} verified',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (item.total30d != null) ...[
                    Text(
                      '(${t.votes(item.total30d!)})',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (item.calories != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      t.menuItemCalories(item.calories!),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (item.distanceKm != null)
                    Text(
                      t.distanceKm(item.distanceKm!),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.isVegan) _DietChip(label: t.vegan),
                  if (item.isGlutenFree) _DietChip(label: t.glutenFree),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onAlertTap,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(t.setPriceAlert),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DietChip extends StatelessWidget {
  const _DietChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.config});
  final _StatusBadgeConfig config;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(type: config.type, label: config.label);
  }
}

class _MenuItemsSkeleton extends StatelessWidget {
  const _MenuItemsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (i) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        );
      }),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, width: 160, color: AppColors.card),
            const SizedBox(height: 10),
            Container(height: 10, width: 100, color: AppColors.card),
            const SizedBox(height: 10),
            Container(height: 10, width: 140, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.onLocationTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: title.isEmpty ? t.emptyTitle : title,
      description: subtitle.isEmpty ? t.emptyRegionDescription : subtitle,
      ctaLabel: onLocationTap == null ? null : t.allowLocation,
      onCta: onLocationTap,
    );
  }
}

class _MenuItemFilterSheet extends StatefulWidget {
  const _MenuItemFilterSheet({
    required this.initialRadius,
    required this.initialVegan,
    required this.initialVegetarian,
    required this.initialGlutenFree,
    required this.initialLactoseFree,
    required this.initialMaxCalories,
    required this.profileEnabled,
    required this.initialVerifiedOnly,
    required this.onApply,
  });

  final int initialRadius;
  final bool initialVegan;
  final bool initialVegetarian;
  final bool initialGlutenFree;
  final bool initialLactoseFree;
  final int initialMaxCalories;
  final bool profileEnabled;
  final bool initialVerifiedOnly;
  final Future<void> Function(_MenuItemFilters filters) onApply;

  @override
  State<_MenuItemFilterSheet> createState() => _MenuItemFilterSheetState();
}

class _MenuItemFilterSheetState extends State<_MenuItemFilterSheet> {
  late int radius;
  late bool vegan;
  late bool vegetarian;
  late bool glutenFree;
  late bool lactoseFree;
  late int maxCalories;
  late bool verifiedOnly;

  @override
  void initState() {
    super.initState();
    radius = widget.initialRadius;
    vegan = widget.initialVegan;
    vegetarian = widget.initialVegetarian;
    glutenFree = widget.initialGlutenFree;
    lactoseFree = widget.initialLactoseFree;
    maxCalories = widget.initialMaxCalories;
    verifiedOnly = widget.initialVerifiedOnly;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.filters,
              style: context.sectionTitleStyle,
            ),
            const SizedBox(height: 12),
            if (widget.profileEnabled) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.profileActive,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              t.sortDistance,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final km in const [1, 3, 5, 10, 20])
                  AppFilterChip(
                    label: t.nearbyKm(km),
                    selected: radius == km,
                    onTap: () => setState(() => radius = km),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: vegan,
              onChanged: (v) => setState(() => vegan = v),
              title: Text(t.vegan),
            ),
            SwitchListTile(
              value: vegetarian,
              onChanged: (v) => setState(() => vegetarian = v),
              title: Text(t.vegetarian),
            ),
            SwitchListTile(
              value: glutenFree,
              onChanged: (v) => setState(() => glutenFree = v),
              title: Text(t.glutenFree),
            ),
            SwitchListTile(
              value: lactoseFree,
              onChanged: (v) => setState(() => lactoseFree = v),
              title: Text(t.lactoseFree),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  t.maxCalories,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  t.menuItemCalories(maxCalories),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            Slider(
              value: maxCalories.toDouble(),
              min: 300,
              max: 1200,
              divisions: 9,
              label: '$maxCalories',
              onChanged: (v) => setState(() => maxCalories = v.round()),
            ),
            SwitchListTile(
              value: verifiedOnly,
              onChanged: (v) => setState(() => verifiedOnly = v),
              title: Text(t.onlyVerifiedPrice),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onApply(
                  _MenuItemFilters(
                    radiusKm: radius,
                    vegan: vegan,
                    vegetarian: vegetarian,
                    glutenFree: glutenFree,
                    lactoseFree: lactoseFree,
                    maxCalories: maxCalories,
                    verifiedOnly: verifiedOnly,
                  ),
                ),
                child: Text(t.apply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemFilters {
  const _MenuItemFilters({
    required this.radiusKm,
    required this.vegan,
    required this.vegetarian,
    required this.glutenFree,
    required this.lactoseFree,
    required this.maxCalories,
    required this.verifiedOnly,
  });

  final int radiusKm;
  final bool vegan;
  final bool vegetarian;
  final bool glutenFree;
  final bool lactoseFree;
  final int maxCalories;
  final bool verifiedOnly;
}

void _redirectToLogin(BuildContext context) {
  showQuickLoginSheet(context);
}

String _formatPrice(int? cents, {String? locale}) {
  if (cents == null) {
    return (locale ?? '').startsWith('tr') ? 'Fiyata sorunuz' : 'Price on request';
  }
  final value = cents / 100.0;
  final text = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  return 'TL$text';
}

_StatusBadgeConfig _statusBadge(String status, AppLocalizations t) {
  switch (status) {
    case 'verified':
      return _StatusBadgeConfig(
        t.statusVerifiedShort,
        StatusBadgeType.verified,
      );
    case 'unverified':
      return _StatusBadgeConfig(t.statusMixedShort, StatusBadgeType.pending);
    case 'stale':
      return _StatusBadgeConfig(
        t.statusOutdatedShort,
        StatusBadgeType.outdated,
      );
    default:
      return _StatusBadgeConfig(t.statusUnknownShort, StatusBadgeType.pending);
  }
}

class _StatusBadgeConfig {
  const _StatusBadgeConfig(this.label, this.type);
  final String label;
  final StatusBadgeType type;
}







