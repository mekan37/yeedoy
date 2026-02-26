import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memory cache: businessId -> isFavorited
final favoriteStatusCacheProvider =
    NotifierProvider<FavoriteStatusCache, Map<String, bool>>(FavoriteStatusCache.new);

final favoriteIdsProvider = NotifierProvider<FavoriteIdsCache, Set<String>>(FavoriteIdsCache.new);

class FavoriteStatusCache extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void set(String businessId, bool value) {
    state = {...state, businessId: value};
  }

  void remove(String businessId) {
    final next = {...state}..remove(businessId);
    state = next;
  }

  void clear() {
    state = <String, bool>{};
  }
}

class FavoriteIdsCache extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool contains(String id) => state.contains(id);

  void add(String id) {
    state = {...state, id};
  }

  void addAll(Iterable<String> ids) {
    state = {...state, ...ids};
  }

  void remove(String id) {
    final next = {...state}..remove(id);
    state = next;
  }

  void clear() {
    state = <String>{};
  }
}

final isFavoritedProvider = Provider.family<bool, String>((ref, businessId) {
  final cache = ref.watch(favoriteStatusCacheProvider);
  if (cache.containsKey(businessId)) return cache[businessId]!;
  final ids = ref.watch(favoriteIdsProvider);
  return ids.contains(businessId);
});
