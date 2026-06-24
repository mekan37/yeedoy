part of '../discovery_page.dart';

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
  const _RecommendedTab({this.initialSort});

  final String? initialSort;

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
    unawaited(AssistantShortcutsService.donateDiscoverActivity());
    if (widget.initialSort != null) {
      final sortBy = DiscoverySort.values
          .where((s) => s.name == widget.initialSort)
          .firstOrNull;
      if (sortBy != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(discoverySearchProvider.notifier)
                .setFilters(sortBy: sortBy);
          }
        });
      }
    }
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
    final isNearby = st.mode == DiscoveryMode.nearby;
    final needsLocation = isNearby && st.userLat == null && st.userLng == null;
    final city = st.city.trim();
    final district = st.district.trim();
    // MVP scope: sponsorlu işletme listeleme kapatıldı (final stratejik karar
    // raporu §16 — MVP'de sponsorluk yok). Sponsorlu bölüm ve ilgili ölü kod
    // kaldırıldı.
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
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
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

                            if (st.loading && st.items.isEmpty) ...[
                              if (_surfaceMode == _DiscoverySurfaceMode.map)
                                const _DiscoveryMapSkeleton()
                              else
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
                                    isOpenNow: entry.value.isOpenNow,
                                    medianPriceCents:
                                        entry.value.medianPriceCents,
                                    priceLevel: entry.value.priceLevel,
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
                                        transitionBuilder: (child, animation) {
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
                                                favIds.contains(entry.value.id),
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
                                          HapticFeedback.lightImpact();
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
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _openLocationSheet(
                                                        context,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(t.selectLocation),
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
              Text(t.rankingFormulaTitle, style: context.sectionTitleStyle),
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchFilterSheet(
        initialState: st,
        initialQuery: qCtrl.text,
      ),
    );
  }

  // ignore: unused_element
  Future<void> _openFiltersSheetLegacy(
    BuildContext context,
    DiscoverySearchState st,
  ) async {
    final t = AppLocalizations.of(context);
    var localRating = st.minRating;
    var localPriceTier = st.priceTier;
    var localOpenNow = st.openNow;
    var localRecentBoost = st.recentPriceBoost;
    final localMealCardKeys = <String>{...st.mealCardKeys};
    var localMaxBudgetTl = st.maxBudgetCents != null
        ? (st.maxBudgetCents! / 100).roundToDouble()
        : 0.0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final mealCardOptionsAsync = ref.watch(
              allMealCardProvidersProvider,
            );
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
                          Text(
                            t.minRatingLabel(localRating.toStringAsFixed(1)),
                          ),
                          Slider(
                            value: localRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            label: localRating.toStringAsFixed(1),
                            onChanged: (v) =>
                                setModalState(() => localRating = v),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.localeName.startsWith('tr')
                                ? (localMaxBudgetTl <= 0
                                      ? 'Kişi başı bütçe: Sınırsız'
                                      : 'Kişi başı max bütçe: ${localMaxBudgetTl.round()}₺')
                                : (localMaxBudgetTl <= 0
                                      ? 'Budget per person: No limit'
                                      : 'Max budget per person: ${localMaxBudgetTl.round()}₺'),
                          ),
                          Slider(
                            value: localMaxBudgetTl,
                            min: 0,
                            max: 500,
                            divisions: 50,
                            label: localMaxBudgetTl <= 0
                                ? (t.localeName.startsWith('tr')
                                      ? 'Sınırsız'
                                      : 'No limit')
                                : '${localMaxBudgetTl.round()}₺',
                            onChanged: (v) =>
                                setModalState(() => localMaxBudgetTl = v),
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
                                          if (localMealCardKeys.contains(
                                            option.key,
                                          )) {
                                            localMealCardKeys.remove(
                                              option.key,
                                            );
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
                            onChanged: (v) =>
                                setModalState(() => localOpenNow = v),
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
                                          maxBudgetCents: null,
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
                                    final mealCardKeys =
                                        localMealCardKeys.toList(
                                          growable: false,
                                        )..sort();
                                    await ref
                                        .read(discoverySearchProvider.notifier)
                                        .setFilters(
                                          minRating: localRating,
                                          priceTier: localPriceTier,
                                          openNow: localOpenNow,
                                          recentPriceBoost: localRecentBoost,
                                          mealCardKeys: mealCardKeys,
                                          maxBudgetCents: localMaxBudgetTl <= 0
                                              ? null
                                              : (localMaxBudgetTl * 100)
                                                    .round(),
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
  }) {
    final items = st.items;
    final freshItems = items
        .where((b) => (b.recentPriceVerifiedCount ?? 0) > 0)
        .take(8)
        .toList();
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
                const _DiscoveryGreetingHeader(),
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
                CategoryQuickFilters(
                  items: [
                    CategoryQuickFilterItem(
                      id: 'featured',
                      title: AppLocalizations.of(context).discoveryFeaturedCategory,
                      imageAsset: '',
                      isFeatured: true,
                    ),
                    ..._homeCategories.take(8).map(
                          (item) => CategoryQuickFilterItem(
                            id: item.id,
                            title: _homeCategoryTitle(context, item.titleKey),
                            imageAsset:
                                _selectedCategoryImage[item.id] ?? item.imagePool.first,
                          ),
                        ),
                  ],
                  layout: CategoryQuickFiltersLayout.roundedRow,
                  showHeader: false,
                  onTap: (item) async {
                    if (item.isFeatured) {
                      qCtrl.clear();
                      ref
                          .read(discoverySearchProvider.notifier)
                          .setQuery('', withDebounce: false);
                      if (mounted) setState(() {});
                      return;
                    }
                    final selected = _homeCategories.firstWhere((e) => e.id == item.id);
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
                        .setQuery(selected.searchTerm, withDebounce: false);
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                const WeatherHintBar(compact: true),
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
                      if (st.hasBudgetFilter) ...[
                        const SizedBox(width: 8),
                        _PremiumFilterChip(
                          label:
                              AppLocalizations.of(
                                context,
                              ).localeName.startsWith('tr')
                              ? 'Max ${(st.maxBudgetCents! / 100).round()}₺'
                              : 'Max ${(st.maxBudgetCents! / 100).round()}₺',
                          icon: Icons.money_off_rounded,
                          selected: true,
                          filledPrimary: false,
                          onTap: () {
                            ref
                                .read(discoverySearchProvider.notifier)
                                .setFilters(maxBudgetCents: null);
                          },
                        ),
                      ],
                      const SizedBox(width: 8),
                      _PremiumFilterChip(
                        label:
                            AppLocalizations.of(
                              context,
                            ).localeName.startsWith('tr')
                            ? 'Taste Twin'
                            : 'Taste Twin',
                        icon: Icons.auto_awesome_rounded,
                        selected: st.tasteTwinEnabled,
                        filledPrimary: true,
                        onTap: () {
                          ref
                              .read(discoverySearchProvider.notifier)
                              .toggleTasteTwin(enabled: !st.tasteTwinEnabled);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DiscoveryCampaignPromoCard(
                  onTap: () => DefaultTabController.of(context).animateTo(1),
                ),
                if (freshItems.isNotEmpty) ...[
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
                    child: ListView.separated(
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
                          timeLabel: AppLocalizations.of(context).menuUpdatedLabel,
                          onTap: () => _openBusiness(
                            item.id,
                            source: 'fresh_updates',
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).discoverForYou,
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
                else ...[
                  ..._buildNearbyCardsWithAds(
                    context: context,
                    ref: ref,
                    nearbyItems: nearbyItems,
                    favCache: favCache,
                    favIds: favIds,
                    isLoggedIn: isLoggedIn,
                  ),
                  _DiscoveryPromoBanner(onTap: () => _openWhatToEat(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: VerticalBusinessCard(
            item: item,
            imageAsset: _categoryImageFor(item.category, index + 2),
            ratingLabel: _ratingLabel(item),
            isFavorite: isFav,
            onTap: () => _openBusiness(item.id, source: 'nearby_verified'),
            onFavoriteTap: () async {
              if (!isLoggedIn) {
                await showQuickLoginSheet(context, redirectPath: '/discover');
                return;
              }
              try {
                HapticFeedback.lightImpact();
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
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ad != null
              ? NativeAdCard(ad: ad)
              : _DiscoveryCampaignPromoCard(
                  onTap: () => DefaultTabController.of(context).animateTo(1),
                ),
        ),
      );
      adShown += 1;
    }

    return widgets;
  }

  String _ratingLabel(BusinessCardModel item) => businessRatingLabel(item);

  String _categoryImageFor(String category, int index) =>
      categoryImageAsset(category);
}
