part of '../kesif_sayfasi.dart';

String _homeCategoryTitle(BuildContext context, String key) {
  final t = AppLocalizations.of(context);
  return switch (key) {
    'discoveryHomeCategoryDoner' => t.discoveryHomeCategoryDoner,
    'discoveryHomeCategoryPide' => t.discoveryHomeCategoryPide,
    'discoveryHomeCategoryLahmacun' => t.discoveryHomeCategoryLahmacun,
    'discoveryHomeCategoryBurger' => t.discoveryHomeCategoryBurger,
    'discoveryHomeCategoryPizza' => t.discoveryHomeCategoryPizza,
    'discoveryHomeCategoryKebap' => t.discoveryHomeCategoryKebap,
    'discoveryHomeCategoryCorba' => t.discoveryHomeCategoryCorba,
    'discoveryHomeCategoryKahvalti' => t.discoveryHomeCategoryKahvalti,
    'discoveryHomeCategoryManti' => t.discoveryHomeCategoryManti,
    'discoveryHomeCategoryTatli' => t.discoveryHomeCategoryTatli,
    _ => key,
  };
}

String _discoveryFilterLabel(BuildContext context, String key) {
  final t = AppLocalizations.of(context);
  return switch (key) {
    'discoveryFilterCafe' => t.discoveryFilterCafe,
    'discoveryFilterRestaurant' => t.discoveryFilterRestaurant,
    'discoveryFilterDessertPastry' => t.discoveryFilterDessertPastry,
    'discoveryFilterBreakfast' => t.discoveryFilterBreakfast,
    'discoveryFilterFishMeat' => t.discoveryFilterFishMeat,
    'discoveryFilterVenue' => t.discoveryFilterVenue,
    _ => key,
  };
}

void _openMenuItem(BuildContext context, MenuItemSearchResult item) {
  final menuId = item.menuId;
  final businessId = item.businessId;
  final menuItemId = item.menuItemId;
  if (menuId.isEmpty) {
    context.go('/isletme/$businessId');
    return;
  }
  final encodedMenu = Uri.encodeComponent(menuId);
  context.go('/isletme/$businessId/menu-item/$menuItemId?menuId=$encodedMenu');
}

String _formatPrice(BuildContext context, int? cents) {
  if (cents == null) return '';
  return formatCurrency(context, cents / 100, currencyCode: 'TRY');
}

String _formatLocation(BuildContext context, String? city, String? district) {
  final c = (city ?? '').trim();
  final d = (district ?? '').trim();
  if (c.isEmpty && d.isEmpty) {
    return AppLocalizations.of(context).locationNotAvailable;
  }
  if (c.isEmpty) return d;
  if (d.isEmpty) return c;
  return '$c / $d';
}

Future<void> _logDiscoveryClick(
  AnalyticsRepository analytics, {
  required String businessId,
  required String source,
}) async {
  final clientId = await getAnalyticsClientId();
  await analytics.logEvent(
    eventName: 'discovery_business_click',
    businessId: businessId,
    source: source,
    clientId: clientId,
  );
  await analytics.logEvent(
    eventName: AppEvents.businessOpen,
    businessId: businessId,
    source: source,
    clientId: clientId,
  );
  await trackFunnelStepOnce(
    analytics,
    step: FunnelStep.firstBusiness,
    businessId: businessId,
    source: source,
  );
}

String _campaignTimeLeft(BuildContext context, DateTime expiresAt) {
  final t = AppLocalizations.of(context);
  final diff = expiresAt.difference(DateTime.now());
  if (diff.inSeconds <= 0) return t.campaignEnded;
  if (diff.inHours >= 24) {
    final days = (diff.inHours / 24).ceil();
    return t.timeDays(days);
  }
  if (diff.inHours >= 1) return t.timeHours(diff.inHours);
  return t.timeMinutes(diff.inMinutes.clamp(1, 59));
}

_StatusBadgeConfig _statusBadge(BuildContext context, String? status) {
  final t = AppLocalizations.of(context);
  switch (status) {
    case 'verified':
      return _StatusBadgeConfig(
        t.statusVerifiedShort,
        StatusBadgeType.verified,
      );
    case 'mixed':
      return _StatusBadgeConfig(t.statusMixedShort, StatusBadgeType.pending);
    case 'outdated':
      return _StatusBadgeConfig(
        t.statusOutdatedShort,
        StatusBadgeType.outdated,
      );
    default:
      return _StatusBadgeConfig(t.statusUnknownShort, StatusBadgeType.pending);
  }
}

String? _shortLocation(String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return null;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d  $c';
}

class DiscoveryHeaderSearch extends StatelessWidget {
  const DiscoveryHeaderSearch({
    super.key,
    required this.controller,
    required this.recentSearches,
    required this.catalogSuggestions,
    required this.onDebouncedChanged,
    required this.onSubmitted,
    required this.onRecentTap,
    required this.onSuggestionTap,
    required this.onRecentRemove,
    required this.onClearRecent,
  });

  final TextEditingController controller;
  final List<String> recentSearches;
  final List<DiscoverySearchSuggestion> catalogSuggestions;
  final ValueChanged<String> onDebouncedChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.header, AppColors.headerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.appName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.appTagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          DiscoverySearchBar(
            controller: controller,
            recentSearches: recentSearches,
            suggestions: catalogSuggestions,
            hintText: context.l10n.searchKebabsHint,
            onDebouncedChanged: onDebouncedChanged,
            onSubmitted: onSubmitted,
            onRecentTap: onRecentTap,
            onSuggestionTap: onSuggestionTap,
            onRecentRemove: onRecentRemove,
            onClearRecent: onClearRecent,
          ),
        ],
      ),
    );
  }
}

class DiscoveryModeToggle extends StatelessWidget {
  const DiscoveryModeToggle({
    super.key,
    required this.isNearby,
    required this.radiusKm,
    required this.onModeChanged,
    required this.onRadiusChanged,
  });

  final bool isNearby;
  final int radiusKm;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<int> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: SwitchListTile(
                  value: isNearby,
                  onChanged: onModeChanged,
                  title: Text(
                    t.discoveryNearbyTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    isNearby
                        ? t.discoveryNearbySubtitle
                        : t.discoveryLocationSubtitle,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isNearby)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryChip(
                  label: AppLocalizations.of(context).nearbyKm(5),
                  selected: radiusKm == 5,
                  onTap: () => onRadiusChanged(5),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: AppLocalizations.of(context).nearbyKm(10),
                  selected: radiusKm == 10,
                  onTap: () => onRadiusChanged(10),
                ),
                const SizedBox(width: 8),
                CategoryChip(
                  label: AppLocalizations.of(context).nearbyKm(20),
                  selected: radiusKm == 20,
                  onTap: () => onRadiusChanged(20),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DiscoveryCategoryChips extends StatelessWidget {
  const DiscoveryCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryChip(
            label: t.tumu,
            selected: selectedCategory.isEmpty,
            onTap: () => onSelect(''),
          ),
          const SizedBox(width: 8),
          for (final category in discoveryFilterConfigs) ...[
            CategoryChip(
              label: _discoveryFilterLabel(context, category.labelKey),
              selected: selectedCategory == category.value,
              onTap: () => onSelect(
                selectedCategory == category.value ? '' : category.value,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DiscoverySponsoredSection extends ConsumerWidget {
  const _DiscoverySponsoredSection({
    required this.city,
    required this.district,
    required this.category,
    required this.onOpenBusiness,
  });

  final String city;
  final String district;
  final String? category;
  final ValueChanged<String> onOpenBusiness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final sponsoredAsync = ref.watch(
      sponsoredBusinessesProvider(
        sponsoredDiscoveryParams(
          city: city,
          district: district,
          category: category,
          limit: 2,
        ),
      ),
    );

    return sponsoredAsync.when(
      loading: () => const _SponsoredSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: t.sponsored),
            const SizedBox(height: 8),
            RepaintBoundary(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: _SponsoredDisclosureLine()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final b in items) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.28),
                          ),
                        ),
                        child: BusinessTile(
                          name: b.name,
                          category: b.category,
                          subtitle:
                              '${t.sponsored} · ${b.district ?? ''} ${b.city ?? ''}',
                          badgeText: t.sponsored,
                          mealCardProviders: b.mealCardProviders,
                          onTap: () => onOpenBusiness(b.id),
                          trailingAction: const Icon(Icons.chevron_right),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SponsoredDisclosureLine extends StatelessWidget {
  const _SponsoredDisclosureLine();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            t.sponsored,
            style: TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t.sponsoredDisclosure,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Tooltip(
          message: t.sponsoredTooltip,
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.muted.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class DiscoveryTopSectionsV2 extends ConsumerWidget {
  const DiscoveryTopSectionsV2({
    super.key,
    required this.hasDistrict,
    required this.showLocalInsights,
    required this.enableSecondaryFetch,
    required this.areaLabel,
    required this.rankLabelPrefix,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.onShowInsights,
  });

  final bool hasDistrict;
  final bool showLocalInsights;
  final bool enableSecondaryFetch;
  final String areaLabel;
  final String rankLabelPrefix;
  final String city;
  final String district;
  final String neighborhood;
  final VoidCallback onShowInsights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    if (!hasDistrict) return const SizedBox.shrink();

    if (!showLocalInsights) {
      return Column(
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  color: AppColors.textStrong,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.localInsightsReady(areaLabel),
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(onPressed: onShowInsights, child: Text(t.show)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    final homeFeedKey = (city: city, district: district, neighborhood: neighborhood);
    final homeFeedAsync = ref.watch(homeFeedProvider(homeFeedKey));

    ref.listen(homeFeedProvider(homeFeedKey), (_, next) {
      next.whenData((feed) {
        HomeWidgetService.update(feed.nearOpenBusinesses);
      });
    });

    return Column(
      children: [
        _NearOpenSectionV2(
          title: t.nearOpenSectionTitle(areaLabel),
          items: homeFeedAsync.whenData((feed) => feed.nearOpenBusinesses),
        ),
        const SizedBox(height: 12),
        _MicroTrendSection(
          title: t.mostViewedThisWeekTitle(areaLabel),
          emptyText: t.noViewDataInArea,
          items: homeFeedAsync.whenData((feed) => feed.topViews),
          metricLabel: (item) => t.viewsMetric(item.metric),
          rankLabelPrefix: rankLabelPrefix,
        ),
        const SizedBox(height: 12),
        _MicroTrendSection(
          title: t.highestPriceChangeTitle(areaLabel),
          emptyText: t.noPriceMovementInArea,
          items: homeFeedAsync.whenData((feed) => feed.priceChanges),
          metricLabel: (item) => t.priceChangeMetric(item.metric),
          rankLabelPrefix: rankLabelPrefix,
        ),
        const SizedBox(height: 12),
        _MicroTrendSection(
          title: t.nightOpenFavoritesTitle(areaLabel),
          emptyText: t.noNightOpenFavoritesInArea,
          items: homeFeedAsync.whenData((feed) => feed.nightFavorites),
          metricLabel: (item) => t.followersMetric(item.metric),
          rankLabelPrefix: rankLabelPrefix,
        ),
        const SizedBox(height: 12),
        _TopCategoriesSectionV2(
          title: t.popularCategoriesTitle(areaLabel),
          items: homeFeedAsync.whenData((feed) => feed.topCategories),
        ),
        const SizedBox(height: 12),
        if (enableSecondaryFetch)
          _RegionalPriceIndexSection(
            title: t.regionalPriceIndexTitle(areaLabel),
            items: ref.watch(
              regionalPriceIndexProvider((city: city, district: district)),
            ),
          )
        else
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.hourglass_bottom_outlined),
              title: Text(t.detailedAnalysis),
              subtitle: Text(t.loadWhenScrolledDown),
            ),
          ),
        const SizedBox(height: 12),
        if (enableSecondaryFetch)
          _PriceAnomalySection(
            title: t.anomalyMonitoringTitle(areaLabel),
            items: ref.watch(
              priceAnomaliesProvider((city: city, district: district)),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NearOpenSectionV2 extends StatelessWidget {
  const _NearOpenSectionV2({required this.title, required this.items});

  final String title;
  final AsyncValue<List<BusinessCardModel>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 8),
        items.when(
          loading: () => const AppSkeletonCard(),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                for (final item in list.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            item.category,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TopCategoriesSectionV2 extends StatelessWidget {
  const _TopCategoriesSectionV2({required this.title, required this.items});

  final String title;
  final AsyncValue<List<RegionalPriceIndexItem>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 8),
        items.when(
          loading: () => const AppSkeletonCard(),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in list.take(6))
                  Chip(
                    label: Text(
                      '${item.category.isEmpty ? AppLocalizations.of(context).general : item.category}  ${_formatPrice(context, item.medianPriceCents)}',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}


