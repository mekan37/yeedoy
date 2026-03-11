import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:yeedoy/features/discovery/domain/business_card.dart';
import 'package:yeedoy/features/discovery/domain/discovery_search_state.dart';
import 'package:yeedoy/features/favorites/domain/favorites_controller.dart';
import 'package:yeedoy/features/menus/data/food_catalog_repository.dart';
import 'package:yeedoy/features/menus/domain/food_catalog_models.dart';
import 'package:yeedoy/features/menus/ui/menu_items_tab.dart';
import 'package:yeedoy/features/menus/domain/menu_item_search_model.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../core/storage/category_prefs.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/search_prefs.dart';

import '../../auth/domain/auth_providers.dart';
import '../../top_businesses/ui/top_businesses_strip.dart';

import '../domain/discovery_search_notifier.dart';
import '../domain/discovery_feed_composer.dart';
import '../domain/nearby_campaign.dart';
import '../domain/nearby_campaigns_provider.dart';
import '../domain/price_anomaly.dart';
import '../domain/regional_price_index.dart';
import '../data/discovery_repository.dart';
import '../domain/home_feed.dart';
import '../domain/trend_business.dart';
import '../../../features/shared/ui/components/location_picker_sheet.dart';
import '../domain/today_pick_controller.dart';
import '../../favorites/domain/favorite_status_provider.dart';
import '../../shared/ui/business_tile.dart';
import '../../shared/ui/category_chip.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/growth/ab_experiments.dart';
import '../../../core/growth/funnel_tracker.dart';
import '../../../core/perf/firebase_perf_trace.dart';
import '../../monetization/domain/sponsored_businesses_provider.dart';
import '../../ads/data/native_ad_controller.dart';
import '../../ads/ui/native_ad_card.dart';
import '../../profile/domain/profile_progress_provider.dart';
import '../../profile/domain/profile_progress.dart';
import '../../contribute/ui/contribute_entry.dart';
import '../../embed/data/embed_repository.dart';
import '../../embed/ui/embed_viewer_page.dart';
import '../../business/domain/meal_card_providers_provider.dart';
import '../../shared/ui/widgets/meal_card_badge.dart';
import 'categories_config.dart';
import 'components/category_quick_filters.dart';
import 'components/discovery_search_bar.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../../features/shared/ui/components/weather_hint_bar.dart';

part 'surfaces/discovery_campaigns_tab.dart';
part 'surfaces/discovery_map_surface.dart';
part 'surfaces/discovery_insight_sections.dart';

final regionalPriceIndexProvider =
    FutureProvider.family<
      List<RegionalPriceIndexItem>,
      ({String city, String district})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .getRegionalPriceIndex(
            city: params.city,
            district: params.district,
            limit: 10,
          );
    });

final priceAnomaliesProvider =
    FutureProvider.family<
      List<PriceAnomalyItem>,
      ({String city, String district})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .getPriceAnomalies(
            city: params.city,
            district: params.district,
            days: 30,
            minChangePct: 40,
            limit: 8,
          );
    });

final homeFeedProvider =
    FutureProvider.family<
      HomeFeedData,
      ({String city, String district, String? neighborhood})
    >((ref, params) {
      return ref
          .watch(discoveryRepositoryProvider)
          .getHomeFeed(
            city: params.city,
            district: params.district,
            neighborhood: params.neighborhood,
          );
    });

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: t.tabRecommended),
              Tab(text: t.tabCampaigns),
              Tab(text: t.tabFoods),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KeepAliveTab(child: _RecommendedTab()),
                _KeepAliveTab(child: _CampaignsTab()),
                _KeepAliveTab(child: MenuItemsTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

enum _DiscoverySurfaceMode { list, map }

enum _SerendipityKind { randomGood, unexpected, valueSurprise }

class _RecommendedTab extends ConsumerStatefulWidget {
  const _RecommendedTab();

  @override
  ConsumerState<_RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends ConsumerState<_RecommendedTab>
    with AutomaticKeepAliveClientMixin {
  final qCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  _DiscoverySurfaceMode _surfaceMode = _DiscoverySurfaceMode.list;
  String _lastImpressionKey = '';
  final _rng = math.Random();
  late final List<DiscoveryCategoryConfig> _homeCategories;
  final Map<String, String> _selectedCategoryImage = <String, String>{};
  List<String> _recentSearches = const [];
  List<FoodCatalogHit> _catalogSuggestions = const [];
  int _catalogQueryToken = 0;
  bool _showLocalInsights = false;
  bool _enableBelowFoldFetch = false;
  bool _loggedHomeView = false;
  bool _loggedHomeCategoryExperiment = false;
  CategoryQuickFiltersLayout _categoryLayout =
      CategoryQuickFiltersLayout.horizontal;
  ProviderSubscription<DiscoverySearchState>? _impressionSub;
  Trace? _discoveryLoadTrace;
  bool _discoveryTraceStopped = false;
  bool _pendingSurfaceRouteSync = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      startFirebaseTrace('discovery_load').then((trace) {
        if (!mounted || _discoveryTraceStopped) {
          return stopFirebaseTrace(trace);
        }
        _discoveryLoadTrace = trace;
      }),
    );
    _homeCategories = List<DiscoveryCategoryConfig>.from(
      discoveryHomeCategories,
    );
    for (final category in _homeCategories) {
      final pool = category.imagePool;
      _selectedCategoryImage[category.id] = pool[_rng.nextInt(pool.length)];
    }
    unawaited(_loadCategoryOrder());
    unawaited(_loadRecentSearches());
    _impressionSub = ref.listenManual<DiscoverySearchState>(
      discoverySearchProvider,
      (_, next) {
        if (!_discoveryTraceStopped && !next.loading) {
          _discoveryTraceStopped = true;
          unawaited(stopFirebaseTrace(_discoveryLoadTrace));
          _discoveryLoadTrace = null;
        }
        if (!next.loading && next.items.isNotEmpty) {
          unawaited(_trackDiscoveryImpression(next, next.items));
        }
      },
      fireImmediately: true,
    );
    unawaited(_trackHomeView());
    unawaited(_initGrowthExperiments());

    scrollCtrl.addListener(() {
      if (!_enableBelowFoldFetch && scrollCtrl.position.pixels > 700) {
        setState(() => _enableBelowFoldFetch = true);
      }
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(discoverySearchProvider.notifier).loadMore();
      }
    });
  }

  Future<void> _initGrowthExperiments() async {
    final experiments = await ref.read(growthExperimentsProvider.future);
    final variant = experiments.variantOf(GrowthExperiment.homeCategoryLayout);
    if (!mounted) return;
    setState(() {
      _categoryLayout = variant == 'grid2x4'
          ? CategoryQuickFiltersLayout.grid2x4
          : CategoryQuickFiltersLayout.horizontal;
    });
    if (_loggedHomeCategoryExperiment) return;
    _loggedHomeCategoryExperiment = true;
    await logExperimentExposure(
      ref.read(analyticsRepositoryProvider),
      experiment: GrowthExperiment.homeCategoryLayout,
      variant: variant,
      source: 'discovery_home',
    );
  }

  Future<void> _loadCategoryOrder() async {
    final counts = await CategoryPrefs.readTapCounts();
    if (counts.isNotEmpty) {
      _homeCategories.sort(
        (a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0),
      );
    } else {
      final cached = await OfflineCachePrefs.loadCategoriesSnapshot();
      if (cached.isNotEmpty) {
        final rank = <String, int>{
          for (var i = 0; i < cached.length; i++) cached[i]: i,
        };
        _homeCategories.sort((a, b) {
          final ra = rank[a.id] ?? 999;
          final rb = rank[b.id] ?? 999;
          return ra.compareTo(rb);
        });
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    final recent = await SearchPrefs.readRecentQueries();
    if (!mounted) return;
    setState(() => _recentSearches = recent);
  }

  Future<void> _rememberSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final next = await SearchPrefs.pushQuery(value);
    if (!mounted) return;
    setState(() => _recentSearches = next);
  }

  Future<void> _removeRecentSearch(String query) async {
    final next = await SearchPrefs.removeQuery(query);
    if (!mounted) return;
    setState(() => _recentSearches = next);
  }

  Future<void> _clearRecentSearches() async {
    await SearchPrefs.clearAll();
    if (!mounted) return;
    setState(() => _recentSearches = const []);
  }

  Future<void> _refreshCatalogSuggestions(String query) async {
    final trimmed = query.trim();
    final token = ++_catalogQueryToken;
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() => _catalogSuggestions = const []);
      return;
    }
    try {
      final hits = await ref
          .read(foodCatalogRepositoryProvider)
          .search(trimmed, limit: 6);
      if (!mounted || token != _catalogQueryToken) return;
      setState(() => _catalogSuggestions = hits);
    } catch (_) {
      if (!mounted || token != _catalogQueryToken) return;
      setState(() => _catalogSuggestions = const []);
    }
  }

  Future<void> _trackSearchAction({
    required String action,
    required String query,
  }) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: 'discovery_search_action',
          source: 'discovery_search_bar',
          meta: {'action': action, 'query': value},
          clientId: clientId,
        );
    if (action == 'submit') {
      await ref
          .read(analyticsRepositoryProvider)
          .logEvent(
            eventName: AppEvents.searchSubmit,
            source: 'discovery_search_bar',
            meta: {'query': value},
            clientId: clientId,
          );
    }
  }

  Future<void> _trackHomeView() async {
    if (_loggedHomeView) return;
    _loggedHomeView = true;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.homeView,
          source: 'discovery_home',
          clientId: clientId,
        );
    await trackFunnelStepOnce(
      ref.read(analyticsRepositoryProvider),
      step: FunnelStep.open,
      source: 'discovery_home',
    );
  }

  @override
  void dispose() {
    if (!_discoveryTraceStopped) {
      _discoveryTraceStopped = true;
      unawaited(stopFirebaseTrace(_discoveryLoadTrace));
    }
    _impressionSub?.close();
    qCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _syncSurfaceModeFromRoute(context);
    final t = AppLocalizations.of(context);
    final st = ref.watch(discoverySearchProvider);
    final flags = ref.watch(featureFlagsProvider);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final favIds = ref.watch(favoriteIdsProvider);
    final favCache = ref.watch(favoriteStatusCacheProvider);
    final freshLinksAsync = ref.watch(freshEmbedsProvider(8));
    final isNearby = st.mode == DiscoveryMode.nearby;
    final needsLocation = isNearby && st.userLat == null && st.userLng == null;
    final city = st.city.trim();
    final district = st.district.trim();
    final hasDistrict = city.isNotEmpty && district.isNotEmpty;
    final neighborhood = ref.watch(
      userLocationProvider.select((loc) => (loc.neighborhood ?? '').trim()),
    );
    final hasNeighborhood = neighborhood.isNotEmpty;
    final areaLabel = hasNeighborhood
        ? '$neighborhood mahallesinde'
        : '$district bölgesinde';
    final rankLabelPrefix = hasNeighborhood ? 'Mahallende' : 'İlçende';
    final usePremiumLayout = Theme.of(context).useMaterial3;
    if (usePremiumLayout) {
      return _buildPremiumDiscoveryLayout(
        context: context,
        st: st,
        isLoggedIn: isLoggedIn,
        favIds: favIds,
        favCache: favCache,
        freshLinksAsync: freshLinksAsync,
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              sponsoredBusinessesProvider(
                sponsoredDiscoveryParams(
                  city: st.city,
                  district: st.district,
                  category: st.category.isEmpty ? null : st.category,
                  limit: 2,
                ),
              ),
            );
            await ref.read(discoverySearchProvider.notifier).refresh();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 1040
                  ? 1040.0
                  : (constraints.maxWidth >= 720
                        ? 720.0
                        : constraints.maxWidth);
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: CustomScrollView(
                    controller: scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        sliver: SliverList.list(
                          children: [
                            DiscoveryHeaderSearch(
                              controller: qCtrl,
                              recentSearches: _recentSearches,
                              catalogSuggestions: _catalogSuggestions
                                  .map(
                                    (hit) => DiscoverySearchSuggestion(
                                      label: hit.name,
                                      subtitle: hit.categoryName,
                                    ),
                                  )
                                  .toList(growable: false),
                              onDebouncedChanged: (query) {
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setQuery(query, withDebounce: false);
                                unawaited(_refreshCatalogSuggestions(query));
                              },
                              onSubmitted: (query) async {
                                await _rememberSearch(query);
                                unawaited(
                                  _trackSearchAction(
                                    action: 'submit',
                                    query: query,
                                  ),
                                );
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setQuery(query, withDebounce: false);
                                if (mounted) {
                                  setState(
                                    () => _catalogSuggestions = const [],
                                  );
                                }
                              },
                              onRecentTap: (query) async {
                                await _rememberSearch(query);
                                unawaited(
                                  _trackSearchAction(
                                    action: 'recent_tap',
                                    query: query,
                                  ),
                                );
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setQuery(query, withDebounce: false);
                                if (mounted) {
                                  setState(
                                    () => _catalogSuggestions = const [],
                                  );
                                }
                              },
                              onSuggestionTap: (query) async {
                                await _rememberSearch(query);
                                unawaited(
                                  _trackSearchAction(
                                    action: 'catalog_suggestion_tap',
                                    query: query,
                                  ),
                                );
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setQuery(query, withDebounce: false);
                                if (mounted) {
                                  setState(
                                    () => _catalogSuggestions = const [],
                                  );
                                }
                              },
                              onRecentRemove: (query) {
                                unawaited(_removeRecentSearch(query));
                              },
                              onClearRecent: () {
                                unawaited(_clearRecentSearches());
                              },
                            ),
                            const SizedBox(height: 14),
                            CategoryQuickFilters(
                              items: _homeCategories
                                  .take(12)
                                  .map(
                                    (item) => CategoryQuickFilterItem(
                                      id: item.id,
                                      title: _homeCategoryTitle(
                                        context,
                                        item.titleKey,
                                      ),
                                      imageAsset:
                                          _selectedCategoryImage[item.id] ??
                                          item.imagePool.first,
                                    ),
                                  )
                                  .toList(),
                              onTap: (item) async {
                                final selected = _homeCategories.firstWhere(
                                  (e) => e.id == item.id,
                                );
                                final clientId = await getAnalyticsClientId();
                                if (mounted) {
                                  unawaited(
                                    ref
                                        .read(analyticsRepositoryProvider)
                                        .logEvent(
                                          eventName: AppEvents.categoryClick,
                                          source: 'category_quick_filters',
                                          clientId: clientId,
                                          meta: {'category_id': selected.id},
                                        ),
                                  );
                                }
                                unawaited(CategoryPrefs.bumpTapCount(item.id));
                                qCtrl.text = selected.searchTerm;
                                await _rememberSearch(selected.searchTerm);
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setQuery(
                                      selected.searchTerm,
                                      withDebounce: false,
                                    );
                                if (mounted) setState(() {});
                              },
                              layout: _categoryLayout,
                            ),
                            const SizedBox(height: 12),
                            const _V4GrowthHubCard(),
                            const SizedBox(height: 14),
                            if (flags.hasExperimentalNavigation) ...[
                              const _DiscoveryLabsHubCard(),
                              const SizedBox(height: 12),
                            ],
                            AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.whatToEatTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textStrong,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          t.whatToEatSubtitle,
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _SmallBadge(t.nearbyShort),
                                            _SmallBadge(t.affordableShort),
                                            _SmallBadge(t.quickDecisionShort),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => _openWhatToEat(context),
                                    child: Text(t.start),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick road mode card
                            AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.onTheRoadTitle,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textStrong,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          t.onTheRoadSubtitle,
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => ref
                                        .read(discoverySearchProvider.notifier)
                                        .quickRoadMode(),
                                    child: Text(t.start),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            DiscoveryTopSectionsV2(
                              hasDistrict: hasDistrict,
                              showLocalInsights: _showLocalInsights,
                              enableSecondaryFetch: _enableBelowFoldFetch,
                              areaLabel: areaLabel,
                              rankLabelPrefix: rankLabelPrefix,
                              city: city,
                              district: district,
                              neighborhood: neighborhood,
                              onShowInsights: () {
                                setState(() => _showLocalInsights = true);
                              },
                            ),

                            AppSectionHeader(
                              title: t.bestBusinessesThisWeek,
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go('/top-businesses?period=week'),
                                child: Text(t.seeAll),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const AppCard(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: TopBusinessesStrip(period: 'week'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            AppSectionHeader(
                              title: t.bestBusinessesThisMonth,
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go('/top-businesses?period=month'),
                                child: Text(t.seeAll),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const AppCard(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: TopBusinessesStrip(period: 'month'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (isNearby && st.radiusKm == 20) ...[
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    CategoryChip(
                                      label: t.restaurant,
                                      selected: st.category == 'Restoran',
                                      onTap: () => ref
                                          .read(
                                            discoverySearchProvider.notifier,
                                          )
                                          .setFilters(category: 'Restoran'),
                                    ),
                                    const SizedBox(width: 8),
                                    CategoryChip(
                                      label: t.cafe,
                                      selected: st.category == 'Kafe',
                                      onTap: () => ref
                                          .read(
                                            discoverySearchProvider.notifier,
                                          )
                                          .setFilters(category: 'Kafe'),
                                    ),
                                    const SizedBox(width: 8),
                                    CategoryChip(
                                      label: t.venue,
                                      selected: st.category == 'Mekan',
                                      onTap: () => ref
                                          .read(
                                            discoverySearchProvider.notifier,
                                          )
                                          .setFilters(category: 'Mekan'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            const SizedBox(height: 12),

                            DiscoveryModeToggle(
                              isNearby: isNearby,
                              radiusKm: st.radiusKm,
                              onModeChanged: (v) => ref
                                  .read(discoverySearchProvider.notifier)
                                  .setMode(
                                    v
                                        ? DiscoveryMode.nearby
                                        : DiscoveryMode.text,
                                  ),
                              onRadiusChanged: (km) => ref
                                  .read(discoverySearchProvider.notifier)
                                  .setRadius(km),
                            ),
                            const SizedBox(height: 8),

                            if (isNearby) const SizedBox(height: 10),

                            DiscoveryCategoryChips(
                              selectedCategory: st.category,
                              onSelect: (category) async {
                                final clientId = await getAnalyticsClientId();
                                if (mounted) {
                                  unawaited(
                                    ref
                                        .read(analyticsRepositoryProvider)
                                        .logEvent(
                                          eventName: AppEvents.categoryClick,
                                          source: 'discovery_category_chips',
                                          clientId: clientId,
                                          meta: {'category_id': category},
                                        ),
                                  );
                                }
                                ref
                                    .read(discoverySearchProvider.notifier)
                                    .setFilters(category: category);
                              },
                            ),
                            const SizedBox(height: 12),

                            AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child:
                                        SegmentedButton<_DiscoverySurfaceMode>(
                                          segments: [
                                            ButtonSegment(
                                              value: _DiscoverySurfaceMode.list,
                                              icon: Icon(
                                                Icons.view_list_rounded,
                                              ),
                                              label: Text(t.list),
                                            ),
                                            ButtonSegment(
                                              value: _DiscoverySurfaceMode.map,
                                              icon: Icon(Icons.map_outlined),
                                              label: Text(t.map),
                                            ),
                                          ],
                                          selected: {_surfaceMode},
                                          onSelectionChanged: (selection) {
                                            final selectedMode =
                                                selection.first;
                                            setState(
                                              () => _surfaceMode = selectedMode,
                                            );
                                            final uri = GoRouterState.of(
                                              context,
                                            ).uri;
                                            final isMapRoute =
                                                uri.path.startsWith(
                                                  '/discover',
                                                ) &&
                                                uri.queryParameters['view'] ==
                                                    'map';
                                            if (selectedMode ==
                                                _DiscoverySurfaceMode.map) {
                                              if (!isMapRoute) {
                                                context.go(
                                                  '/discover?view=map',
                                                );
                                              }
                                            } else if (isMapRoute) {
                                              context.go('/discover');
                                            }
                                          },
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _openFiltersSheet(context, st),
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: Text(t.filters),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<DiscoverySort>(
                                    initialValue: st.sortBy,
                                    onSelected: (value) => ref
                                        .read(discoverySearchProvider.notifier)
                                        .setFilters(sortBy: value),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: DiscoverySort.recommended,
                                        child: Text(t.sortRecommended),
                                      ),
                                      PopupMenuItem(
                                        value: DiscoverySort.distance,
                                        child: Text(t.sortDistance),
                                      ),
                                      PopupMenuItem(
                                        value: DiscoverySort.rating,
                                        child: Text(t.sortRating),
                                      ),
                                      PopupMenuItem(
                                        value: DiscoverySort.priceLow,
                                        child: Text(t.sortPriceLow),
                                      ),
                                      PopupMenuItem(
                                        value: DiscoverySort.newlyVerified,
                                        child: Text(t.sortNewlyVerified),
                                      ),
                                    ],
                                    child: Chip(
                                      avatar: const Icon(
                                        Icons.swap_vert,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _sortLabel(context, st.sortBy),
                                      ),
                                    ),
                                  ),
                                  if (st.sortBy ==
                                      DiscoverySort.recommended) ...[
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _showRankingFormula(context),
                                      icon: const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                      ),
                                      label: Text(t.whyTop),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (st.items.isNotEmpty) ...[
                              _SerendipityCard(
                                onPick: (kind) =>
                                    _openSerendipityPick(context, st, kind),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Header
                            Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    final headerText = isNearby
                                        ? (st.radiusKm == 20
                                              ? t.onTheRoad20km
                                              : t.nearbyKm(st.radiusKm))
                                        : _formatLocation(
                                            context,
                                            st.city,
                                            st.district,
                                          );

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: isNearby
                                          ? null
                                          : () => _openLocationSheet(context),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.place_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              headerText,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            if (!isNearby) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.expand_more,
                                                size: 18,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Spacer(),
                                Text(
                                  '${st.items.length}${st.hasMore ? '+' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (st.loading && st.items.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    t.liveResultsUpdating,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                            if (st.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppErrorMapper.message(st.error),
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => ref
                                          .read(
                                            discoverySearchProvider.notifier,
                                          )
                                          .refresh(),
                                      child: Text(t.tekrarDene),
                                    ),
                                  ],
                                ),
                              ),

                            _DiscoverySponsoredSection(
                              city: st.city,
                              district: st.district,
                              category: st.category.isEmpty
                                  ? null
                                  : st.category,
                              onOpenBusiness: (id) {
                                _openBusiness(id, source: 'sponsored');
                              },
                            ),

                            if (st.loading && st.items.isEmpty) ...[
                              const _DiscoverySkeleton(),
                            ] else if (_surfaceMode ==
                                _DiscoverySurfaceMode.map) ...[
                              _DiscoveryMapSurface(
                                items: st.items,
                                onOpenBusiness: (id) =>
                                    _openBusiness(id, source: 'map'),
                              ),
                            ] else ...[
                              for (final entry in st.items.asMap().entries) ...[
                                RepaintBoundary(
                                  child: BusinessTile(
                                    name: entry.value.name,
                                    category: entry.value.category,
                                    subtitle:
                                        '${entry.value.district ?? ''}  ${entry.value.city ?? ''}',
                                    badgeText: entry.value.ownerVerified == true
                                        ? t.businessApprovedData
                                        : t.communityData,
                                    distanceKm: isNearby
                                        ? entry.value.distanceKm
                                        : null,
                                    qualityScore: entry.value.qualityScore,
                                    mealCardProviders:
                                        entry.value.mealCardProviders,
                                    socialProof: _discoverySocialProof(
                                      context: context,
                                      item: entry.value,
                                      district: st.district,
                                      isTopResult:
                                          st.sortBy ==
                                              DiscoverySort.recommended &&
                                          entry.key == 0,
                                    ),
                                    onWhyTap:
                                        st.sortBy == DiscoverySort.recommended
                                        ? () => _showRankingFormula(context)
                                        : null,
                                    onTap: () => _openBusiness(
                                      entry.value.id,
                                      source: 'discover_list',
                                    ),
                                    trailingAction: IconButton(
                                      tooltip:
                                          (favCache[entry.value.id] ??
                                              favIds.contains(entry.value.id))
                                          ? t.removeFromFavorites
                                          : t.addToFavorites,
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        transitionBuilder:
                                            (child, animation) {
                                              return ScaleTransition(
                                                scale: Tween<double>(
                                                  begin: 0.7,
                                                  end: 1,
                                                ).animate(animation),
                                                child: child,
                                              );
                                            },
                                        child: Icon(
                                          (favCache[entry.value.id] ??
                                                  favIds.contains(
                                                    entry.value.id,
                                                  ))
                                              ? Icons.star
                                              : Icons.star_outline,
                                          key: ValueKey(
                                            favCache[entry.value.id] ??
                                                favIds.contains(
                                                  entry.value.id,
                                                ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (!isLoggedIn) {
                                          await showQuickLoginSheet(
                                            context,
                                            redirectPath: '/discover',
                                          );
                                          return;
                                        }
                                        try {
                                          await ref
                                              .read(
                                                favoritesControllerProvider
                                                    .notifier,
                                              )
                                              .toggleFavorite(entry.value.id);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppErrorMapper.message(e),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],

                            if (st.loading && st.items.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),

                            if (st.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),

                            if (!st.loading && st.items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: needsLocation
                                    ? AppCard(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.locationPermissionTitle,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              t.locationPermissionDescription,
                                              style: TextStyle(
                                                color: AppColors.muted,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: FilledButton(
                                                    onPressed: () => ref
                                                        .read(
                                                          discoverySearchProvider
                                                              .notifier,
                                                        )
                                                        .setMode(
                                                          DiscoveryMode.nearby,
                                                        ),
                                                    child: Text(t.allow),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      ref
                                                          .read(
                                                            discoverySearchProvider
                                                                .notifier,
                                                          )
                                                          .setMode(
                                                            DiscoveryMode.text,
                                                          );
                                                      _openLocationSheet(
                                                        context,
                                                      );
                                                    },
                                                    child: Text(
                                                      t.selectLocation,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              t.manualLocationHint,
                                              style: TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : AppCard(
                                        child: Column(
                                          children: [
                                            AppEmptyState(
                                              icon: Icons.search_off,
                                              title: st.query.trim().isNotEmpty
                                                  ? t.noResultsYet
                                                  : t.lowDataInArea,
                                              description:
                                                  st.query.trim().isNotEmpty
                                                  ? t.tryDifferentSearchOrFilter
                                                  : t.beFirstContributorInArea,
                                            ),
                                            const SizedBox(height: 10),
                                            AppCard(
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.verified_outlined,
                                                    color: AppColors.textStrong,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          t.topVerifiedMenus,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          t.mostTrustedMenusInCity,
                                                          style: TextStyle(
                                                            color:
                                                                AppColors.muted,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final tab =
                                                          DefaultTabController.of(
                                                            context,
                                                          );
                                                      tab.animateTo(2);
                                                    },
                                                    child: Text(t.seeList),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            AppCard(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.volunteer_activism,
                                                    color: AppColors.textStrong,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      t.localContributionCall,
                                                      style: TextStyle(
                                                        color: AppColors.muted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                FilledButton.tonalIcon(
                                                  onPressed: () =>
                                                      context.go('/suggest'),
                                                  icon: const Icon(
                                                    Icons.storefront_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    t.suggestBusiness,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Positioned(right: 16, bottom: 16, child: ContributeFab()),
      ],
    );
  }

  void _syncSurfaceModeFromRoute(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    if (!uri.path.startsWith('/discover')) return;
    final wantedMode = uri.queryParameters['view'] == 'map'
        ? _DiscoverySurfaceMode.map
        : _DiscoverySurfaceMode.list;
    if (_surfaceMode == wantedMode || _pendingSurfaceRouteSync) return;
    _pendingSurfaceRouteSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingSurfaceRouteSync = false;
      if (!mounted || _surfaceMode == wantedMode) return;
      setState(() => _surfaceMode = wantedMode);
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  void _openSerendipityPick(
    BuildContext context,
    DiscoverySearchState st,
    _SerendipityKind kind,
  ) {
    final items = st.items;
    if (items.isEmpty) {
      _showSnack(context, AppLocalizations.of(context).noSurpriseSuggestionNow);
      return;
    }

    List<BusinessCardModel> candidates = items;
    switch (kind) {
      case _SerendipityKind.randomGood:
        candidates = items
            .where((b) => (b.qualityScore ?? 0) >= 3 || (b.avgRating ?? 0) >= 4)
            .toList();
        break;
      case _SerendipityKind.unexpected:
        if (st.category.isNotEmpty) {
          candidates = items.where((b) => b.category != st.category).toList();
        } else {
          candidates = items.where((b) => (b.avgRating ?? 0) >= 4).toList();
        }
        break;
      case _SerendipityKind.valueSurprise:
        final prices =
            items
                .map((b) => b.medianPriceCents ?? 0)
                .where((p) => p > 0)
                .toList()
              ..sort();
        final median = prices.isEmpty
            ? null
            : prices[prices.length ~/ 2].toDouble();
        if (median != null) {
          candidates = items
              .where(
                (b) =>
                    (b.avgRating ?? 0) >= 4 &&
                    (b.medianPriceCents ?? 0) > 0 &&
                    (b.medianPriceCents ?? 0) <= median,
              )
              .toList();
        } else {
          candidates = items.where((b) => (b.avgRating ?? 0) >= 4).toList();
        }
        break;
    }

    if (candidates.isEmpty) {
      candidates = items;
    }
    final picked = candidates[_rng.nextInt(candidates.length)];
    _openBusiness(picked.id, source: 'serendipity');
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openBusiness(String businessId, {required String source}) {
    unawaited(_trackDiscoveryClick(businessId, source: source));
    if (!mounted) return;
    context.go('/b/$businessId');
  }

  Future<void> _trackDiscoveryClick(
    String businessId, {
    required String source,
  }) async {
    final analytics = ref.read(analyticsRepositoryProvider);
    await _logDiscoveryClick(analytics, businessId: businessId, source: source);
  }

  Future<void> _trackDiscoveryImpression(
    DiscoverySearchState st,
    List<BusinessCardModel> items,
  ) async {
    if (items.isEmpty) return;
    final key = [
      st.mode.name,
      st.city,
      st.district,
      st.category,
      st.query,
      st.radiusKm.toString(),
      st.priceTier.name,
      st.minRating.toString(),
      st.openNow.toString(),
      st.sortBy.name,
      items.length.toString(),
    ].join('|');
    if (key == _lastImpressionKey) return;
    _lastImpressionKey = key;
    final clientId = await getAnalyticsClientId();
    final analytics = ref.read(analyticsRepositoryProvider);
    final source = st.query.trim().isNotEmpty ? 'discover_search' : 'discover';
    await analytics.logEvent(
      eventName: 'discovery_impression',
      source: source,
      clientId: clientId,
      meta: {
        'count': items.length,
        if (st.query.trim().isNotEmpty) 'query': st.query.trim(),
      },
    );
    var rank = 0;
    for (final item in items.take(8)) {
      rank += 1;
      await analytics.logEvent(
        eventName: 'business_impression',
        businessId: item.id,
        source: 'discover_list',
        clientId: clientId,
        meta: {'rank': rank},
      );
    }
  }

  String _sortLabel(BuildContext context, DiscoverySort value) {
    final t = AppLocalizations.of(context);
    switch (value) {
      case DiscoverySort.recommended:
        return t.sortRecommended;
      case DiscoverySort.distance:
        return t.sortDistance;
      case DiscoverySort.rating:
        return t.sortRating;
      case DiscoverySort.priceLow:
        return t.sortPriceLow;
      case DiscoverySort.newlyVerified:
        return t.sortNewlyVerified;
    }
  }

  void _showRankingFormula(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.rankingFormulaTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(t.rankingFormulaIntro),
              const SizedBox(height: 6),
              Text(' ${t.rankingWeightDistance}'),
              Text(' ${t.rankingWeightAccuracy}'),
              Text(' ${t.rankingWeightEngagement}'),
              Text(' ${t.rankingWeightQuality}'),
              const SizedBox(height: 10),
              Text(
                t.rankingFormulaNote,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }

  String _priceTierLabel(BuildContext context, DiscoveryPriceTier value) {
    final t = AppLocalizations.of(context);
    switch (value) {
      case DiscoveryPriceTier.any:
        return t.priceTierAny;
      case DiscoveryPriceTier.budget:
        return t.priceTierBudget;
      case DiscoveryPriceTier.medium:
        return t.priceTierMedium;
      case DiscoveryPriceTier.premium:
        return t.priceTierPremium;
    }
  }

  List<String> _discoverySocialProof({
    required BuildContext context,
    required BusinessCardModel item,
    required String? district,
    required bool isTopResult,
  }) {
    final t = AppLocalizations.of(context);
    final labels = <String>[];
    final recentVerified = item.recentPriceVerifiedCount ?? 0;
    if (recentVerified > 0) {
      labels.add(t.priceVerifiedInLast48h);
    } else {
      labels.add(t.menuMayBeOutdated);
    }
    if (item.ownerVerified == true) {
      labels.add(t.verifiedByBusiness);
    } else {
      labels.add(t.updatedByCommunity);
    }
    if (isTopResult && (district ?? '').trim().isNotEmpty) {
      labels.add(t.topRankedInDistrict);
    }
    return labels;
  }

  Future<void> _openFiltersSheet(
    BuildContext context,
    DiscoverySearchState st,
  ) async {
    final t = AppLocalizations.of(context);
    var localRating = st.minRating;
    var localPriceTier = st.priceTier;
    var localOpenNow = st.openNow;
    var localRecentBoost = st.recentPriceBoost;
    final localMealCardKeys = <String>{...st.mealCardKeys};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final mealCardOptionsAsync = ref.watch(allMealCardProvidersProvider);
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.filters,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(t.minRatingLabel(localRating.toStringAsFixed(1))),
                          Slider(
                            value: localRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            label: localRating.toStringAsFixed(1),
                            onChanged: (v) => setModalState(() => localRating = v),
                          ),
                          const SizedBox(height: 8),
                          Text(t.priceLevel),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: DiscoveryPriceTier.values
                                .map(
                                  (tier) => AppFilterChip(
                                    label: _priceTierLabel(context, tier),
                                    selected: localPriceTier == tier,
                                    onTap: () => setModalState(
                                      () => localPriceTier = tier,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Yemek Kartı',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          mealCardOptionsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                            error: (error, _) => Text(
                              AppErrorMapper.message(error),
                              style: const TextStyle(color: AppColors.danger),
                            ),
                            data: (options) {
                              if (options.isEmpty) {
                                return const Text(
                                  'Aktif yemek kartı tanımı bulunmuyor.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final option in options)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        setModalState(() {
                                          if (localMealCardKeys.contains(option.key)) {
                                            localMealCardKeys.remove(option.key);
                                          } else {
                                            localMealCardKeys.add(option.key);
                                          }
                                        });
                                      },
                                      child: MealCardBadge(
                                        provider: option,
                                        selected: localMealCardKeys.contains(
                                          option.key,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: localOpenNow,
                            title: Text(t.prioritizeOpenNow),
                            onChanged: (v) => setModalState(() => localOpenNow = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: localRecentBoost,
                            title: Text(t.prioritizeNewlyVerified),
                            onChanged: (v) =>
                                setModalState(() => localRecentBoost = v),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await ref
                                        .read(discoverySearchProvider.notifier)
                                        .setFilters(
                                          minRating: 0,
                                          priceTier: DiscoveryPriceTier.any,
                                          openNow: false,
                                          recentPriceBoost: true,
                                          mealCardKeys: const <String>[],
                                        );
                                  },
                                  child: Text(t.reset),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final mealCardKeys = localMealCardKeys
                                        .toList(growable: false)
                                      ..sort();
                                    await ref
                                        .read(discoverySearchProvider.notifier)
                                        .setFilters(
                                          minRating: localRating,
                                          priceTier: localPriceTier,
                                          openNow: localOpenNow,
                                          recentPriceBoost: localRecentBoost,
                                          mealCardKeys: mealCardKeys,
                                        );
                                  },
                                  child: Text(t.apply),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _openWhatToEat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _WhatToEatSheet(),
    );
  }

  Widget _buildPremiumDiscoveryLayout({
    required BuildContext context,
    required DiscoverySearchState st,
    required bool isLoggedIn,
    required Set<String> favIds,
    required Map<String, bool> favCache,
    required AsyncValue<List<Embed>> freshLinksAsync,
  }) {
    final items = st.items;
    final freshItems = items.take(8).toList();
    final nearbyItems = items;
    final locationLabel = _formatLocation(context, st.city, st.district);

    return RefreshIndicator(
      onRefresh: () => ref.read(discoverySearchProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
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
                              AppLocalizations.of(context).currentLocation,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationLabel,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).changeLocation,
                        onPressed: () => _openLocationSheet(context),
                        icon: const Icon(Icons.expand_more_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const WeatherHintBar(compact: true),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: qCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (query) {
                      ref
                          .read(discoverySearchProvider.notifier)
                          .setQuery(query);
                    },
                    onSubmitted: (query) async {
                      await _rememberSearch(query);
                      unawaited(
                        _trackSearchAction(action: 'submit', query: query),
                      );
                      ref
                          .read(discoverySearchProvider.notifier)
                          .setQuery(query, withDebounce: false);
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchKebabsHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.muted,
                      ),
                      suffixIcon: IconButton(
                        tooltip: AppLocalizations.of(context).filters,
                        onPressed: () => _openFiltersSheet(context, st),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PremiumFilterChip(
                        label: AppLocalizations.of(context).budget,
                        icon: Icons.payments_outlined,
                        selected: st.priceTier == DiscoveryPriceTier.budget,
                        filledPrimary: false,
                        onTap: () {
                          final target =
                              st.priceTier == DiscoveryPriceTier.budget
                              ? DiscoveryPriceTier.any
                              : DiscoveryPriceTier.budget;
                          ref
                              .read(discoverySearchProvider.notifier)
                              .setFilters(priceTier: target);
                        },
                      ),
                      const SizedBox(width: 8),
                      _PremiumFilterChip(
                        label: AppLocalizations.of(context).verified,
                        icon: Icons.verified_rounded,
                        selected: st.recentPriceBoost,
                        filledPrimary: true,
                        onTap: () {
                          ref
                              .read(discoverySearchProvider.notifier)
                              .setFilters(
                                recentPriceBoost: !st.recentPriceBoost,
                              );
                        },
                      ),
                      const SizedBox(width: 8),
                      _PremiumFilterChip(
                        label: AppLocalizations.of(context).openNow,
                        icon: Icons.schedule_rounded,
                        selected: st.openNow,
                        filledPrimary: false,
                        onTap: () {
                          ref
                              .read(discoverySearchProvider.notifier)
                              .setFilters(openNow: !st.openNow);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).freshMenuUpdates,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context).seeAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: freshItems.isEmpty
                      ? AppEmptyState(
                          icon: Icons.update_rounded,
                          title: AppLocalizations.of(context).noFreshData,
                          description: AppLocalizations.of(
                            context,
                          ).freshDataWillAppear,
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: freshItems.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = freshItems[index];
                            return _DiscoveryUpdateCard(
                              item: item,
                              imageAsset: _categoryImageFor(
                                item.category,
                                index,
                              ),
                              timeLabel: _freshTimeLabel(context, index),
                              onTap: () => _openBusiness(
                                item.id,
                                source: 'fresh_updates',
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).freshLinks,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: _buildFreshLinksSection(context, freshLinksAsync),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).nearbyVerifiedSpots,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (nearbyItems.isEmpty)
                  AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: AppLocalizations.of(context).noNearbyVerifiedSpots,
                    description: AppLocalizations.of(
                      context,
                    ).changeFiltersTryAgain,
                  )
                else
                  ..._buildNearbyCardsWithAds(
                    context: context,
                    ref: ref,
                    nearbyItems: nearbyItems,
                    favCache: favCache,
                    favIds: favIds,
                    isLoggedIn: isLoggedIn,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _freshTimeLabel(BuildContext context, int index) {
    final t = AppLocalizations.of(context);
    const hours = [2, 5, 8];
    if (index % 4 == 3) return t.timeDaysAgo(1);
    return t.timeHoursAgo(hours[index % hours.length]);
  }

  String _updatedLabel(BuildContext context, int index) {
    final t = AppLocalizations.of(context);
    const days = [0, 2, 1];
    return t.updatedDaysAgo(days[index % days.length]);
  }

  List<Widget> _buildNearbyCardsWithAds({
    required BuildContext context,
    required WidgetRef ref,
    required List<BusinessCardModel> nearbyItems,
    required Map<String, bool> favCache,
    required Set<String> favIds,
    required bool isLoggedIn,
  }) {
    if (nearbyItems.isEmpty) return const <Widget>[];

    ref.watch(nativeAdControllerProvider);
    final adController = ref.read(nativeAdControllerProvider.notifier);
    final widgets = <Widget>[];
    var adShown = 0;

    for (var index = 0; index < nearbyItems.length; index++) {
      final item = nearbyItems[index];
      final isFav = favCache[item.id] ?? favIds.contains(item.id);
      final hasVerified = (item.recentPriceVerifiedCount ?? 0) > 0;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _NearbyVerifiedSpotCard(
            item: item,
            imageAsset: _categoryImageFor(item.category, index + 2),
            ratingLabel: _ratingLabel(item),
            averageSpend: _avgSpendLabel(context, item),
            updatedLabel: _updatedLabel(context, index),
            statusType: hasVerified
                ? StatusBadgeType.verified
                : StatusBadgeType.outdated,
            isFavorite: isFav,
            onTap: () => _openBusiness(item.id, source: 'nearby_verified'),
            onFavoriteTap: () async {
              if (!isLoggedIn) {
                await showQuickLoginSheet(context, redirectPath: '/discover');
                return;
              }
              try {
                await ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleFavorite(item.id);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppErrorMapper.message(e))),
                );
              }
            },
          ),
        ),
      );

      final businessCount = index + 1;
      final shouldInsertAd = shouldInsertDiscoveryAdAfterBusiness(
        businessCountShown: businessCount,
        adsShown: adShown,
      );
      if (!shouldInsertAd) continue;
      final ad = adController.adForSlot(adShown);
      if (ad == null) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: NativeAdCard(ad: ad),
        ),
      );
      adShown += 1;
    }

    return widgets;
  }

  String _avgSpendLabel(BuildContext context, BusinessCardModel item) {
    final t = AppLocalizations.of(context);
    final raw = item.medianPriceCents;
    if (raw == null || raw <= 0) return t.avgSpendPerPerson('---');
    final amount = formatCurrency(context, raw / 100, currencyCode: 'TRY');
    return t.avgSpendPerPerson(amount);
  }

  String _ratingLabel(BusinessCardModel item) {
    final rating = ((item.avgRating ?? 4.6) * 10).round() / 10;
    final trust = item.trustScore ?? 1.2;
    final votes = trust >= 10
        ? '${(trust / 1000).toStringAsFixed(1)}k'
        : '1.2k';
    return '$rating ($votes)';
  }

  String _categoryImageFor(String category, int index) {
    final normalized = category.toLowerCase();
    for (final cfg in discoveryHomeCategories) {
      if (normalized.contains(cfg.searchTerm.toLowerCase())) {
        return cfg.imagePool.first;
      }
    }
    final fallback =
        discoveryHomeCategories[index % discoveryHomeCategories.length];
    return fallback.imagePool.first;
  }

  Widget _buildFreshLinksSection(
    BuildContext context,
    AsyncValue<List<Embed>> freshLinksAsync,
  ) {
    return freshLinksAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => AppEmptyState(
        icon: Icons.link_off_rounded,
        title: AppLocalizations.of(context).noLinkFound,
        description: AppLocalizations.of(context).newEmbedLinksWillAppear,
      ),
      data: (freshLinks) {
        if (freshLinks.isEmpty) {
          return AppEmptyState(
            icon: Icons.link_off_rounded,
            title: AppLocalizations.of(context).noLinkFound,
            description: AppLocalizations.of(context).newEmbedLinksWillAppear,
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: freshLinks.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final link = freshLinks[index];
            return _FreshLinkCard(
              item: link,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmbedViewerPage(
                      url: link.urlNormalized,
                      title: link.title,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FreshLinkCard extends StatelessWidget {
  const _FreshLinkCard({required this.item, required this.onTap});

  final Embed item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = item.provider.toLowerCase();
    final (icon, color, label) = switch (provider) {
      'youtube' => (Icons.play_circle_fill_rounded, Colors.red, 'YouTube'),
      'instagram' => (Icons.camera_alt_rounded, Colors.pink, 'Instagram'),
      'facebook' => (Icons.facebook_rounded, Colors.blue, 'Facebook'),
      _ => (
        Icons.link_rounded,
        AppColors.muted,
        AppLocalizations.of(context).link,
      ),
    };
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : AppLocalizations.of(context).untitledLink;
    final ownerType = item.ownerType.toLowerCase() == 'business'
        ? AppLocalizations.of(context).businessLabel
        : AppLocalizations.of(context).profile;
    return SizedBox(
      width: 220,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              ownerType,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _agoText(context, item.createdAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

String _agoText(BuildContext context, DateTime value) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 60) return t.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.timeHoursAgo(diff.inHours);
  return t.timeDaysAgo(diff.inDays);
}

class _PremiumFilterChip extends StatelessWidget {
  const _PremiumFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.filledPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool filledPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usePrimary = selected && filledPrimary;
    final bg = usePrimary ? AppColors.primary : AppColors.card;
    final textColor = usePrimary ? AppColors.onPrimary : AppColors.textStrong;
    final borderColor = usePrimary ? AppColors.primary : AppColors.borderStrong;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryUpdateCard extends StatelessWidget {
  const _DiscoveryUpdateCard({
    required this.item,
    required this.imageAsset,
    required this.timeLabel,
    required this.onTap,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyVerifiedSpotCard extends StatelessWidget {
  const _NearbyVerifiedSpotCard({
    required this.item,
    required this.imageAsset,
    required this.ratingLabel,
    required this.averageSpend,
    required this.updatedLabel,
    required this.statusType,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String ratingLabel;
  final String averageSpend;
  final String updatedLabel;
  final StatusBadgeType statusType;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final distance = t.distanceKm(
      double.parse((item.distanceKm ?? 0.4).toStringAsFixed(1)),
    );
    return AppCard(
      padding: const EdgeInsets.all(0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.star,
                        size: 10,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onFavoriteTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.primary : AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          t.avgSpend,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          averageSpend,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$distance • ${item.category}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusBadge(type: statusType, label: t.priceVerified),
                    const Spacer(),
                    Text(
                      updatedLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SerendipityCard extends StatelessWidget {
  const _SerendipityCard({required this.onPick});

  final void Function(_SerendipityKind kind) onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.surpriseDiscoveryTitle,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            t.surpriseDiscoverySubtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.randomGood),
                icon: const Icon(Icons.shuffle),
                label: Text(t.randomButGood),
              ),
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.unexpected),
                icon: const Icon(Icons.explore_outlined),
                label: Text(t.outsideYourUsual),
              ),
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.valueSurprise),
                icon: const Icon(Icons.savings_outlined),
                label: Text(t.pricePerformanceSurprise),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SponsoredSkeleton extends StatelessWidget {
  const _SponsoredSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeletonCard(),
        SizedBox(height: 10),
        AppSkeletonCard(),
        SizedBox(height: 6),
      ],
    );
  }
}

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                        final params = <String, String>{
                          'city': city,
                          'district': district,
                          'party': _partySize.toString(),
                          'budget': budgetCents.toString(),
                          'radius': _radiusKm.toStringAsFixed(0),
                        };
                        context.go(
                          Uri(
                            path: '/budget-combos',
                            queryParameters: params,
                          ).toString(),
                        );
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

class _TodayPickCard extends StatelessWidget {
  const _TodayPickCard({required this.item, required this.onRetry});

  final MenuItemSearchResult item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(context, item.priceCents);
    final status = _statusBadge(context, item.priceStatus);
    final locationText = _shortLocation(item.district, item.city);

    return Card(
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
                Text(
                  priceText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _StatusBadge(config: status),
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
                    '${item.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (locationText != null) ...[
              const SizedBox(height: 4),
              Text(
                locationText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openMenuItem(context, item),
                    child: Text(AppLocalizations.of(context).go),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: Text(AppLocalizations.of(context).restart),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: label, tone: AppBadgeTone.neutral);
  }
}

class _V4GrowthHubCard extends ConsumerStatefulWidget {
  const _V4GrowthHubCard();

  @override
  ConsumerState<_V4GrowthHubCard> createState() => _V4GrowthHubCardState();
}

class _V4GrowthHubCardState extends ConsumerState<_V4GrowthHubCard> {
  bool _loggedNearMiss = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(myProfileProgressProvider, (_, next) {
      unawaited(_maybeLogNearMiss(next.asData?.value));
    }, fireImmediately: true);
  }

  Future<void> _maybeLogNearMiss(ProfileProgress? progress) async {
    if (_loggedNearMiss || progress == null) return;
    final remaining = progress.nextLevelXp - progress.xpInLevel;
    if (remaining <= 0 || remaining > 20) return;
    _loggedNearMiss = true;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.achievementNearMiss,
          source: 'discovery_growth_hub',
          clientId: clientId,
          meta: {'remaining_xp': remaining, 'level': progress.level},
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final progressAsync = ref.watch(myProfileProgressProvider);
    final progress = progressAsync.asData?.value;
    final levelText = progress == null ? 'Seviye' : 'Seviye ${progress.level}';
    final xpText = progress == null ? null : '${progress.totalXp} XP';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_outlined, color: AppColors.textStrong),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.quickShortcuts,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.quickShortcutsSubtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _V4Pill(t.trustScoreLabel),
              _V4Pill(t.savedItems),
              _V4Pill(t.createGroup),
              _V4Pill(t.notifications),
              _V4Pill(t.newPlaces),
            ],
          ),
          const SizedBox(height: 10),
          if (xpText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$levelText  $xpText',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(levelText),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/favorites'),
                icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                label: Text(t.savedItems),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/labs'),
                icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                label: Text(t.myFriendGroup),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/inbox'),
                icon: const Icon(Icons.inbox_outlined, size: 18),
                label: Text(t.notifications),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/labs'),
                icon: const Icon(Icons.emoji_events_outlined, size: 18),
                label: Text(t.tasteExperts),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoveryLabsHubCard extends StatelessWidget {
  const _DiscoveryLabsHubCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.drawerExperimental,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SmallBadge(t.budgetComboResultsTitle),
                    _SmallBadge(t.drawerGroupRequests),
                    _SmallBadge(t.drawerHeroes),
                    _SmallBadge(t.drawerTasteTwin),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.go('/labs'),
            child: Text(t.view),
          ),
        ],
      ),
    );
  }
}

class _V4Pill extends StatelessWidget {
  const _V4Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
    context.go('/b/$businessId');
    return;
  }
  final encodedMenu = Uri.encodeComponent(menuId);
  context.go('/b/$businessId/menu-item/$menuItemId?menuId=$encodedMenu');
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

class _StatusBadgeConfig {
  const _StatusBadgeConfig(this.label, this.type);
  final String label;
  final StatusBadgeType type;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.config});
  final _StatusBadgeConfig config;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(type: config.type, label: config.label);
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
              onTap: () => onSelect(category.value),
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

    final homeFeedAsync = ref.watch(
      homeFeedProvider((
        city: city,
        district: district,
        neighborhood: neighborhood,
      )),
    );

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
