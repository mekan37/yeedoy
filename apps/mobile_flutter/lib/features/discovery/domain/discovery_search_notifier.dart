// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yeedoy/features/discovery/domain/business_card.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/errors/app_error_codes.dart';
import '../../../core/search/query_normalizer.dart';
import '../data/search_repository.dart';
import 'discovery_search_state.dart';
import '../../../core/storage/location_prefs.dart';
import '../../taste_twin/data/taste_twin_repository.dart';

final discoverySearchProvider =
    NotifierProvider<DiscoverySearchNotifier, DiscoverySearchState>(
      DiscoverySearchNotifier.new,
    );

class DiscoverySearchNotifier extends Notifier<DiscoverySearchState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;
  Timer? _debounce;
  bool _homeTtiLogged = false;

  /// Cached set of business IDs recommended by Taste Twin.
  /// Populated lazily when tasteTwinEnabled is toggled on and cleared on toggle off.
  Set<String> _tasteTwinBusinessIds = const {};

  @override
  DiscoverySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() async {
      final saved = await LocationPrefs.read();
      if (saved != null) {
        final (city, district) = saved;
        state = state.copyWith(city: city, district: district);
      }
      await loadInitial();
    });
    return DiscoverySearchState.initial();
  }

  Future<void> loadInitial() async {
    final watch = Stopwatch()..start();
    final reqId = ++_requestId;
    state = state.copyWith(
      loading: true,
      isLoadingMore: false,
      items: [],
      hasMore: true,
      error: null,
    );

    try {
      _dbg(
        'loadInitial:start mode=${state.mode.name} query="${state.query}" city="${state.city}" district="${state.district}"',
      );
      if (state.mode == DiscoveryMode.nearby &&
          (state.userLat == null || state.userLng == null)) {
        state = state.copyWith(
          loading: false,
          hasMore: false,
          error: Exception(AppErrorCodes.locationRequired),
        );
        return;
      }

      final list = await _fetchPage(offset: 0, limit: pageSize);
      _dbg('loadInitial:fetched raw=${list.length}');
      if (reqId != _requestId) return;
      final filtered = await _postProcess(list);
      _dbg('loadInitial:postProcess filtered=${filtered.length}');

      state = state.copyWith(
        loading: false,
        items: filtered,
        hasMore: list.length == pageSize,
      );
      if (!_homeTtiLogged) {
        _homeTtiLogged = true;
        unawaited(ref.read(appTelemetryProvider).logHomeTti(watch.elapsed));
      }
    } catch (e) {
      _dbg('loadInitial:error $e');
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.isLoadingMore || !state.hasMore) return;

    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      _dbg(
        'loadMore:start mode=${state.mode.name} query="${state.query}" offset=${state.items.length}',
      );
      if (state.mode == DiscoveryMode.nearby &&
          (state.userLat == null || state.userLng == null)) {
        state = state.copyWith(
          isLoadingMore: false,
          error: Exception(AppErrorCodes.locationRequired),
        );
        return;
      }

      final list = await _fetchPage(
        offset: state.items.length,
        limit: pageSize,
      );
      _dbg('loadMore:fetched raw=${list.length}');
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      final combined = [...state.items, ...list];
      final filtered = await _postProcess(combined);
      _dbg('loadMore:postProcess filtered=${filtered.length}');

      state = state.copyWith(
        isLoadingMore: false,
        items: filtered,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      _dbg('loadMore:error $e');
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    ref.read(searchRepositoryProvider).clearCache();
    await loadInitial();
  }

  void setQuery(String q, {bool withDebounce = true}) {
    _dbg('setQuery value="$q" withDebounce=$withDebounce');
    state = state.copyWith(query: q);
    _applyInstantResults(q);
    _debounce?.cancel();
    if (!withDebounce) {
      unawaited(loadInitial());
      return;
    }
    if (q.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(loadInitial());
    });
  }

  Future<void> setFilters({
    String? city,
    String? district,
    int? radiusKm,
    String? category,
    double? minRating,
    DiscoveryPriceTier? priceTier,
    DiscoverySort? sortBy,
    bool? openNow,
    bool? recentPriceBoost,
    List<String>? mealCardKeys,
    Object? maxBudgetCents = _noChange,
  }) async {
    state = state.copyWith(
      city: city ?? state.city,
      district: district ?? state.district,
      radiusKm: radiusKm ?? state.radiusKm,
      category: category ?? state.category,
      minRating: minRating ?? state.minRating,
      priceTier: priceTier ?? state.priceTier,
      sortBy: sortBy ?? state.sortBy,
      openNow: openNow ?? state.openNow,
      recentPriceBoost: recentPriceBoost ?? state.recentPriceBoost,
      mealCardKeys: mealCardKeys ?? state.mealCardKeys,
      maxBudgetCents: identical(maxBudgetCents, _noChange)
          ? state.maxBudgetCents
          : maxBudgetCents as int?,
    );
    await loadInitial();
  }

  Future<void> setLocation({
    required String city,
    required String district,
  }) async {
    state = state.copyWith(city: city, district: district);
    await loadInitial();
  }

  Future<void> setUserLocation({
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(userLat: lat, userLng: lng);
    if (state.mode == DiscoveryMode.nearby) {
      await loadInitial();
    }
  }

  Future<(double lat, double lng)> _getLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception(AppErrorCodes.locationPermissionRequired);
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return (pos.latitude, pos.longitude);
  }

  Future<void> quickRoadMode() async {
    state = state.copyWith(
      loading: true,
      error: null,
      mode: DiscoveryMode.nearby,
    );
    try {
      final (lat, lng) = await _getLocation();
      state = state.copyWith(
        userLat: lat,
        userLng: lng,
        radiusKm: 20,
        query: '',
        category: 'Restoran',
      );
      await loadInitial();
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> setMode(DiscoveryMode mode) async {
    if (state.mode == mode) return;
    state = state.copyWith(
      mode: mode,
      items: [],
      hasMore: true,
      error: null,
      isLoadingMore: false,
    );
    if (mode == DiscoveryMode.text) {
      await loadInitial();
      return;
    }
    state = state.copyWith(loading: true);
    try {
      final (lat, lng) = await _getLocation();
      state = state.copyWith(userLat: lat, userLng: lng);
      await loadInitial();
    } catch (e) {
      state = state.copyWith(loading: false, error: e, hasMore: false);
    }
  }

  Future<void> setRadius(int km) async {
    state = state.copyWith(radiusKm: km);
    await loadInitial();
  }

  /// Enables or disables Taste Twin feed boosting.
  /// When enabled, fetches the top taste match's recommended businesses and
  /// boosts them in `_scoreOf`. Requires the user to be authenticated; silently
  /// falls back to standard ranking if the RPC fails or the user has no matches.
  Future<void> toggleTasteTwin({required bool enabled}) async {
    if (state.tasteTwinEnabled == enabled) return;
    state = state.copyWith(tasteTwinEnabled: enabled);
    if (!enabled) {
      _tasteTwinBusinessIds = const {};
      await loadInitial();
      return;
    }
    // Populate the boost set before refreshing the feed.
    await _loadTasteTwinBoostIds();
    await loadInitial();
  }

  Future<void> _loadTasteTwinBoostIds() async {
    try {
      final repo = ref.read(tasteTwinRepositoryProvider);
      final matches = await repo.fetchMatches(limit: 1, minOverlap: 3);
      if (matches.isEmpty) {
        _tasteTwinBusinessIds = const {};
        return;
      }
      final topMatch = matches.first;
      final recs = await repo.fetchRecommendations(
        matchUserId: topMatch.userId,
        limit: 20,
      );
      _tasteTwinBusinessIds = recs.map((r) => r.businessId).toSet();
      _dbg('_loadTasteTwinBoostIds: ${_tasteTwinBusinessIds.length} business IDs');
    } catch (e) {
      _dbg('_loadTasteTwinBoostIds:error $e — falling back to empty set');
      _tasteTwinBusinessIds = const {};
    }
  }

  Future<void> toggleOpenNow(bool v) async {
    state = state.copyWith(openNow: v);
    await loadInitial();
  }

  Future<List<BusinessCardModel>> _fetchPage({
    required int offset,
    required int limit,
  }) async {
    final repo = ref.read(searchRepositoryProvider);
    final query = state.query.trim();
    final normalizedQuery = normalizeSearchQuery(query);
    final hasQuery = normalizedQuery.isNotEmpty;
    _dbg(
      '_fetchPage mode=${state.mode.name} hasQuery=$hasQuery query="$query" normalized="$normalizedQuery" offset=$offset limit=$limit city="${state.city}" district="${state.district}"',
    );

    // If the user typed a query, do a global business search independent
    // of location/mode so results are not constrained to current city/radius.
    if (hasQuery) {
      if (offset == 0) {
        final merged = <String, BusinessCardModel>{};
        for (final q in _queryAlternatives(query)) {
          _dbg('_fetchPage:globalText variant="$q"');
          final rows = await repo.searchBusinesses(
            query: q,
            city: null,
            district: null,
            mealCardKeys: state.mealCardKeys,
            limit: limit,
            offset: 0,
          );
          _dbg('_fetchPage:globalText variant="$q" rows=${rows.length}');
          for (final r in rows) {
            merged[r.id] = r;
          }
          if (merged.length >= limit) break;
        }
        _dbg('_fetchPage:globalText merged=${merged.length}');
        return merged.values.take(limit).toList();
      }
      _dbg('_fetchPage:globalText paged');
      return repo.searchBusinesses(
        query: normalizedQuery,
        city: null,
        district: null,
        mealCardKeys: state.mealCardKeys,
        limit: limit,
        offset: offset,
      );
    }

    final city = state.city;
    final district = state.district;

    if (state.mode == DiscoveryMode.nearby) {
      _dbg('_fetchPage:nearby branch (query empty)');
      return repo.searchNearby(
        userLat: state.userLat!,
        userLng: state.userLng!,
        radiusKm: state.radiusKm.toDouble(),
        query: null,
        city: city,
        district: district,
        mealCardKeys: state.mealCardKeys,
        limit: limit,
        offset: offset,
      );
    }

    _dbg('_fetchPage:text branch (query empty)');
    return repo.searchBusinesses(
      query: '',
      city: city,
      district: district,
      mealCardKeys: state.mealCardKeys,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<BusinessCardModel>> _postProcess(
    List<BusinessCardModel> input,
  ) async {
    final repo = ref.read(searchRepositoryProvider);
    var list = await repo.enrichBusinessCards(input);
    _dbg('_postProcess:start input=${input.length} enriched=${list.length}');

    final normalizedQuery = normalizeSearchQuery(state.query);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (queryTokens.isNotEmpty) {
      list = list.where((b) {
        final haystack = normalizeSearchQuery(
          '${b.name} ${b.category} ${b.city ?? ''} ${b.district ?? ''} ${b.address ?? ''}',
        );
        return queryTokens.every(haystack.contains);
      }).toList();
      _dbg(
        '_postProcess:queryFilter tokens=${queryTokens.join("|")} -> ${list.length}',
      );
    }

    final hasSearchQuery = state.query.trim().isNotEmpty;
    if (!hasSearchQuery && state.category.isNotEmpty) {
      list = list.where((b) => b.category == state.category).toList();
      _dbg(
        '_postProcess:categoryFilter category="${state.category}" -> ${list.length}',
      );
    }
    if (state.minRating > 0) {
      list = list.where((b) => (b.avgRating ?? 0) >= state.minRating).toList();
      _dbg('_postProcess:minRating ${state.minRating} -> ${list.length}');
    }
    if (state.priceTier != DiscoveryPriceTier.any) {
      list = list
          .where((b) => _matchesPriceTier(b.medianPriceCents, state.priceTier))
          .toList();
      _dbg('_postProcess:priceTier ${state.priceTier.name} -> ${list.length}');
    }

    if (state.hasBudgetFilter) {
      list = list
          .where((b) =>
              b.medianPriceCents != null &&
              b.medianPriceCents! > 0 &&
              b.medianPriceCents! <= state.maxBudgetCents!)
          .toList();
      _dbg('_postProcess:maxBudget ${state.maxBudgetCents} -> ${list.length}');
    }

    list.sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));
    if (state.sortBy == DiscoverySort.recommended) {
      list = _prioritizeInstantCandidates(list);
    }

    switch (state.sortBy) {
      case DiscoverySort.distance:
        list.sort(
          (a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9),
        );
        break;
      case DiscoverySort.rating:
        list.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
        break;
      case DiscoverySort.priceLow:
        list.sort(
          (a, b) => (a.medianPriceCents ?? 999999).compareTo(
            b.medianPriceCents ?? 999999,
          ),
        );
        break;
      case DiscoverySort.newlyVerified:
        list.sort(
          (a, b) => (b.recentPriceVerifiedCount ?? 0).compareTo(
            a.recentPriceVerifiedCount ?? 0,
          ),
        );
        break;
      case DiscoverySort.recommended:
        break;
    }

    _dbg('_postProcess:done sort=${state.sortBy.name} output=${list.length}');
    return list;
  }

  void _dbg(String message) {
    if (!kDebugMode) return;
    debugPrint('[DiscoverySearch] $message');
  }

  double _scoreOf(BusinessCardModel b) {
    final distanceScore = _distanceScore(b.distanceKm);
    final accuracyScore = _accuracyScore(b.recentPriceVerifiedCount);
    final engagementScore = _engagementScore(b.avgRating);
    final qualityScore = _qualityScore(b.qualityScore);
    final trustScore = _trustScore(b.trustScore);
    final ownerBoost = _ownerVerificationBoost(b.ownerVerified);
    final freshnessPenalty = _freshnessPenalty(b.recentPriceVerifiedCount);
    // Taste Twin boost: +0.12 for businesses recommended by the top taste match.
    final tasteTwinBoost =
        state.tasteTwinEnabled && _tasteTwinBusinessIds.contains(b.id)
        ? 0.12
        : 0.0;
    final raw =
        (distanceScore * _distanceWeight +
            accuracyScore * _accuracyWeight +
            engagementScore * _engagementWeight +
            qualityScore * _qualityWeight +
            trustScore * _trustWeight) +
        ownerBoost +
        tasteTwinBoost -
        freshnessPenalty;
    return (raw.clamp(0, 1) * 100).toDouble();
  }

  static const double _distanceWeight = 0.27;
  static const double _accuracyWeight = 0.27;
  static const double _engagementWeight = 0.18;
  static const double _qualityWeight = 0.13;
  static const double _trustWeight = 0.15;

  double _distanceScore(double? km) {
    if (km == null) return 0;
    final clamped = km.clamp(0, 12);
    return (12 - clamped) / 12;
  }

  double _accuracyScore(int? recentVerifiedCount) {
    return ((recentVerifiedCount ?? 0).clamp(0, 5)) / 5;
  }

  double _engagementScore(double? avgRating) {
    return ((avgRating ?? 0).clamp(0, 5)) / 5;
  }

  double _qualityScore(double? quality) {
    return ((quality ?? 0).clamp(0, 5)) / 5;
  }

  double _trustScore(double? trust) {
    return (trust ?? 0).clamp(0, 1).toDouble();
  }

  double _ownerVerificationBoost(bool? ownerVerified) {
    if (ownerVerified == true) return 0.05;
    return 0;
  }

  double _freshnessPenalty(int? recentVerifiedCount) {
    if ((recentVerifiedCount ?? 0) > 0) return 0;
    return 0.06;
  }

  bool _matchesPriceTier(int? priceCents, DiscoveryPriceTier tier) {
    if (priceCents == null || priceCents <= 0) return false;
    switch (tier) {
      case DiscoveryPriceTier.any:
        return true;
      case DiscoveryPriceTier.budget:
        return priceCents <= 20000;
      case DiscoveryPriceTier.medium:
        return priceCents > 20000 && priceCents <= 50000;
      case DiscoveryPriceTier.premium:
        return priceCents > 50000;
    }
  }

  List<String> _queryAlternatives(String query) {
    final base = buildSearchVariants(query);
    final expanded = <String>{...base};
    for (final variant in base) {
      final normalized = normalizeSearchQuery(variant);
      final tokens = normalized
          .split(' ')
          .where((t) => t.trim().isNotEmpty)
          .toList(growable: false);
      for (final token in tokens) {
        if (token.length >= 2) {
          expanded.add(token);
        }
      }
    }
    return expanded.toList(growable: false);
  }

  List<BusinessCardModel> _prioritizeInstantCandidates(
    List<BusinessCardModel> input,
  ) {
    final primary = <BusinessCardModel>[];
    final secondary = <BusinessCardModel>[];

    for (final item in input) {
      final nearby = (item.distanceKm ?? 999) <= state.radiusKm;
      final open = item.isOpenNow == true;
      final trust = (item.trustScore ?? 0) >= 0.55;
      if (nearby && open && trust) {
        primary.add(item);
      } else {
        secondary.add(item);
      }
    }

    primary.sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));
    secondary.sort((a, b) => _scoreOf(b).compareTo(_scoreOf(a)));
    return [...primary, ...secondary];
  }

  void _applyInstantResults(String query) {
    final normalized = normalizeSearchQuery(query);
    if (normalized.isEmpty || state.items.isEmpty) return;
    final tokens = normalized.split(' ').where((e) => e.isNotEmpty).toList();
    if (tokens.isEmpty) return;

    final matches = state.items.where((item) {
      final haystack = normalizeSearchQuery('${item.name} ${item.category}');
      return tokens.every((token) => haystack.contains(token));
    }).toList();

    if (matches.isNotEmpty) {
      state = state.copyWith(items: _prioritizeInstantCandidates(matches));
    }
  }
}

const Object _noChange = Object();
