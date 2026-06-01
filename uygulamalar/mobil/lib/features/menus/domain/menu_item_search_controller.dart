// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_error_codes.dart';
import '../data/menu_item_search_repository.dart';
import 'menu_item_search_model.dart';
import 'menu_item_search_state.dart';

final menuItemSearchProvider =
    NotifierProvider.autoDispose<MenuItemSearchController, MenuItemSearchState>(
      MenuItemSearchController.new,
    );

class MenuItemSearchController extends Notifier<MenuItemSearchState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;
  Timer? _debounce;

  @override
  MenuItemSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return MenuItemSearchState.initial();
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(
      loading: true,
      isLoadingMore: false,
      items: [],
      hasMore: true,
      error: null,
      needsLocation: false,
    );

    try {
      final ok = await _ensureLocation();
      if (!ok) {
        if (reqId != _requestId) return;
        state = state.copyWith(
          loading: false,
          hasMore: false,
          needsLocation: true,
        );
        return;
      }

      final list = await _fetchPage(offset: 0, limit: pageSize);
      if (reqId != _requestId) return;

      state = state.copyWith(
        loading: false,
        items: list,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
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
      if (state.userLat == null || state.userLng == null) {
        state = state.copyWith(isLoadingMore: false, needsLocation: true);
        return;
      }

      final list = await _fetchPage(
        offset: state.items.length,
        limit: pageSize,
      );
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;

      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...list],
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadInitial);
  }

  Future<void> setFilters({
    int? radiusKm,
    bool? vegan,
    bool? vegetarian,
    bool? glutenFree,
    bool? lactoseFree,
    bool? halal,
    bool? verifiedPriceOnly,
    int? maxCalories,
    bool? profileEnabled,
  }) async {
    final manual = _manualFromState(
      vegan: vegan,
      vegetarian: vegetarian,
      glutenFree: glutenFree,
      lactoseFree: lactoseFree,
      halal: halal,
      maxCalories: maxCalories,
    );
    final effective = _effectiveFilters(
      manual: manual,
      profileEnabled: profileEnabled ?? state.profileEnabled,
      profile: _profileFromState(),
    );
    state = state.copyWith(
      radiusKm: radiusKm ?? state.radiusKm,
      vegan: effective.vegan,
      vegetarian: effective.vegetarian,
      glutenFree: effective.glutenFree,
      lactoseFree: effective.lactoseFree,
      halal: effective.halal,
      verifiedPriceOnly: verifiedPriceOnly ?? state.verifiedPriceOnly,
      maxCalories: effective.maxCalories,
      profileEnabled: profileEnabled ?? state.profileEnabled,
      manualVegan: manual.vegan,
      manualVegetarian: manual.vegetarian,
      manualGlutenFree: manual.glutenFree,
      manualLactoseFree: manual.lactoseFree,
      manualHalal: manual.halal,
      manualMaxCalories: manual.maxCalories,
    );
    await loadInitial();
  }

  Future<void> applyProfile({
    required bool enabled,
    required bool vegan,
    required bool vegetarian,
    required bool glutenFree,
    required bool lactoseFree,
    required bool halal,
    required int? maxCalories,
  }) async {
    final profile = _Filters(
      vegan: vegan,
      vegetarian: vegetarian,
      glutenFree: glutenFree,
      lactoseFree: lactoseFree,
      halal: halal,
      maxCalories: maxCalories,
    );
    final effective = _effectiveFilters(
      manual: _manualFromState(),
      profileEnabled: enabled,
      profile: profile,
    );
    state = state.copyWith(
      vegan: effective.vegan,
      vegetarian: effective.vegetarian,
      glutenFree: effective.glutenFree,
      lactoseFree: effective.lactoseFree,
      halal: effective.halal,
      maxCalories: effective.maxCalories,
      profileEnabled: enabled,
      profileVegan: profile.vegan,
      profileVegetarian: profile.vegetarian,
      profileGlutenFree: profile.glutenFree,
      profileLactoseFree: profile.lactoseFree,
      profileHalal: profile.halal,
      profileMaxCalories: profile.maxCalories,
    );
    await loadInitial();
  }

  Future<void> requestLocation() async {
    final ok = await _ensureLocation();
    if (ok) {
      await loadInitial();
    } else {
      state = state.copyWith(needsLocation: true);
    }
  }

  Future<bool> _ensureLocation() async {
    if (state.userLat != null && state.userLng != null) return true;
    try {
      final (lat, lng) = await _getLocation();
      state = state.copyWith(userLat: lat, userLng: lng);
      return true;
    } catch (_) {
      return false;
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

  Future<List<MenuItemSearchResult>> _fetchPage({
    required int offset,
    required int limit,
  }) async {
    final repo = ref.read(menuItemSearchRepositoryProvider);
    return repo.searchMenuItems(
      userLat: state.userLat!,
      userLng: state.userLng!,
      radiusKm: state.radiusKm,
      query: state.query,
      vegan: state.vegan,
      vegetarian: state.vegetarian,
      glutenFree: state.glutenFree,
      lactoseFree: state.lactoseFree,
      halal: state.halal,
      maxCalories: state.maxCalories,
      verifiedPriceOnly: state.verifiedPriceOnly,
      limit: limit,
      offset: offset,
    );
  }

  _Filters _manualFromState({
    bool? vegan,
    bool? vegetarian,
    bool? glutenFree,
    bool? lactoseFree,
    bool? halal,
    int? maxCalories,
  }) {
    return _Filters(
      vegan: vegan ?? state.manualVegan,
      vegetarian: vegetarian ?? state.manualVegetarian,
      glutenFree: glutenFree ?? state.manualGlutenFree,
      lactoseFree: lactoseFree ?? state.manualLactoseFree,
      halal: halal ?? state.manualHalal,
      maxCalories: maxCalories ?? state.manualMaxCalories,
    );
  }

  _Filters _profileFromState() {
    return _Filters(
      vegan: state.profileVegan,
      vegetarian: state.profileVegetarian,
      glutenFree: state.profileGlutenFree,
      lactoseFree: state.profileLactoseFree,
      halal: state.profileHalal,
      maxCalories: state.profileMaxCalories,
    );
  }

  _Filters _effectiveFilters({
    required _Filters manual,
    required bool profileEnabled,
    required _Filters profile,
  }) {
    if (!profileEnabled) return manual;
    return _Filters(
      vegan: profile.vegan ? true : manual.vegan,
      vegetarian: profile.vegetarian ? true : manual.vegetarian,
      glutenFree: profile.glutenFree ? true : manual.glutenFree,
      lactoseFree: profile.lactoseFree ? true : manual.lactoseFree,
      halal: profile.halal ? true : manual.halal,
      maxCalories: profile.maxCalories ?? manual.maxCalories,
    );
  }
}

class _Filters {
  const _Filters({
    required this.vegan,
    required this.vegetarian,
    required this.glutenFree,
    required this.lactoseFree,
    required this.halal,
    required this.maxCalories,
  });

  final bool vegan;
  final bool vegetarian;
  final bool glutenFree;
  final bool lactoseFree;
  final bool halal;
  final int? maxCalories;
}
