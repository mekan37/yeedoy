import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memory cache: businessId -> isFavorited
final favoriteStatusCacheProvider =
    NotifierProvider<FavoriteStatusCache, Map<String, bool>>(
      FavoriteStatusCache.new,
    );

final favoriteIdsProvider = NotifierProvider<FavoriteIdsCache, Set<String>>(
  FavoriteIdsCache.new,
);

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

  /// Clears cached `true` entries for businesses not present in [knownFavoriteIds].
  /// Only call this with the complete, authoritative set of the user's current
  /// favorites (e.g. once the favorites list has finished loading with no more
  /// pages) — otherwise a partial page would wrongly clear valid entries.
  void reconcileWithKnownFavorites(Set<String> knownFavoriteIds) {
    var changed = false;
    final next = {...state};
    for (final entry in state.entries) {
      if (entry.value && !knownFavoriteIds.contains(entry.key)) {
        next[entry.key] = false;
        changed = true;
      }
    }
    if (changed) state = next;
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

  /// Replaces the whole set. Only call this with the complete, authoritative
  /// set of the user's current favorites (e.g. once the favorites list has
  /// finished loading with no more pages left) — otherwise a partial page
  /// would wrongly drop ids that simply weren't on that page.
  void replaceAll(Set<String> ids) {
    state = {...ids};
  }
}

// autoDispose: aksi halde her görülen businessId için kalıcı bir provider
// örneği birikirdi (uzun bir kaydırma oturumunda sınırsız büyür) — B67.
final isFavoritedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  businessId,
) {
  final cache = ref.watch(favoriteStatusCacheProvider);
  if (cache.containsKey(businessId)) return cache[businessId]!;
  final ids = ref.watch(favoriteIdsProvider);
  return ids.contains(businessId);
});
