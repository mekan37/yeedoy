import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../../discovery/domain/business_card.dart';
import '../../../src/data/repositories/favorites_repository.dart';
import 'favorite_status_provider.dart';

class FavoritesPagingState {
  const FavoritesPagingState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
  });

  final List<BusinessCardModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  factory FavoritesPagingState.initial() => const FavoritesPagingState(
    items: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: true,
    error: null,
  );

  FavoritesPagingState copyWith({
    List<BusinessCardModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return FavoritesPagingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, FavoritesPagingState>(
      FavoritesController.new,
    );

class FavoritesController extends Notifier<FavoritesPagingState> {
  static const int pageSize = 20;
  final Set<String> _statusInflight = <String>{};

  @override
  FavoritesPagingState build() {
    final user = ref.watch(userProvider);
    if (user == null) {
      Future.microtask(() {
        ref.read(favoriteIdsProvider.notifier).clear();
        ref.read(favoriteStatusCacheProvider.notifier).clear();
      });
      return FavoritesPagingState.initial().copyWith(hasMore: false);
    }
    Future.microtask(loadInitial);
    return FavoritesPagingState.initial();
  }

  bool _sameIds(List<BusinessCardModel> a, List<BusinessCardModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> loadInitial() async {
    if (ref.read(userProvider) == null) return;
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final cached = await repo.getCachedFavorites();
      if (cached != null && cached.items.isNotEmpty) {
        state = state.copyWith(
          items: cached.items,
          isLoading: true,
          hasMore: true,
        );
        _syncIds(cached.ids);
      }
      final page = await repo.getMyFavoritesWithBusinesses(
        limit: pageSize,
        offset: 0,
      );
      final unchanged = _sameIds(state.items, page.items);
      state = state.copyWith(
        items: unchanged ? state.items : page.items,
        isLoading: false,
        hasMore: page.ids.length == pageSize,
      );
      _syncIds(page.ids);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (ref.read(userProvider) == null) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final page = await repo.getMyFavoritesWithBusinesses(
        limit: pageSize,
        offset: state.items.length,
      );
      final all = [...state.items, ...page.items];
      state = state.copyWith(
        items: all,
        isLoadingMore: false,
        hasMore: page.ids.length == pageSize,
      );
      _syncIds(page.ids);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    if (ref.read(userProvider) == null) return;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    await loadInitial();
  }

  Future<void> ensureFavoriteStatus(String businessId) async {
    if (ref.read(userProvider) == null) return;
    final cache = ref.read(favoriteStatusCacheProvider);
    final ids = ref.read(favoriteIdsProvider);
    if (cache.containsKey(businessId) || ids.contains(businessId)) return;
    if (_statusInflight.contains(businessId)) return;
    _statusInflight.add(businessId);

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      final isFav = await repo.isFavorited(businessId);
      ref.read(favoriteStatusCacheProvider.notifier).set(businessId, isFav);
      if (isFav) {
        ref.read(favoriteIdsProvider.notifier).add(businessId);
      }
    } catch (_) {
      ref.read(favoriteStatusCacheProvider.notifier).set(businessId, false);
    } finally {
      _statusInflight.remove(businessId);
    }
  }

  Future<bool> toggleFavorite(String businessId) async {
    if (ref.read(userProvider) == null) {
      throw Exception('Giri?Y gerekli.');
    }
    final repo = ref.read(favoritesRepositoryProvider);
    final cache = ref.read(favoriteStatusCacheProvider.notifier);
    final cacheValues = ref.read(favoriteStatusCacheProvider);
    final ids = ref.read(favoriteIdsProvider.notifier);
    final idsValue = ref.read(favoriteIdsProvider);

    final wasFav = cacheValues[businessId] ?? idsValue.contains(businessId);
    if (wasFav) {
      state = state.copyWith(
        items: state.items.where((b) => b.id != businessId).toList(),
      );
      ids.remove(businessId);
      cache.set(businessId, false);
    } else {
      ids.add(businessId);
      cache.set(businessId, true);
    }

    try {
      final newFav = await repo.toggleFavorite(businessId);
      cache.set(businessId, newFav);
      if (newFav) {
        ids.add(businessId);
        final exists = state.items.any((b) => b.id == businessId);
        if (!exists) {
          final card = await repo.getBusinessById(businessId);
          if (card != null) {
            state = state.copyWith(items: [card, ...state.items]);
          }
        }
      } else {
        ids.remove(businessId);
      }
      return newFav;
    } catch (e) {
      cache.set(businessId, wasFav);
      if (wasFav) {
        ids.add(businessId);
        await loadInitial();
      } else {
        ids.remove(businessId);
      }
      rethrow;
    }
  }

  void _syncIds(List<String> ids) {
    if (ids.isEmpty) return;
    ref.read(favoriteIdsProvider.notifier).addAll(ids);
  }
}
