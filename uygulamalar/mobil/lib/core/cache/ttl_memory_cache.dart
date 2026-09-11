/// LRU olarak sınırlandırılmış bellek-içi cache. `_store` (LinkedHashMap)
/// ekleme/erişim sırasını korur; her erişimde giriş sona taşınır (en son
/// kullanılan), kapasite aşılınca en baştaki (en eski kullanılan) silinir —
/// aksi halde uzun oturumlarda (30+ dk gezinme) kontrolsüz büyür.
class TtlMemoryCache {
  TtlMemoryCache({this.maxEntries = 400});

  final int maxEntries;
  final Map<String, _CacheEntry> _store = <String, _CacheEntry>{};

  T? getFresh<T extends Object>(String key, {required Duration ttl}) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) return null;
    final value = entry.value;
    if (value is T) {
      _touch(key, entry);
      return value;
    }
    return null;
  }

  T? getStale<T extends Object>(String key) {
    final entry = _store[key];
    final value = entry?.value;
    if (value is T) {
      _touch(key, entry!);
      return value;
    }
    return null;
  }

  void set<T extends Object>(String key, T value) {
    _store.remove(key);
    _store[key] = _CacheEntry(value: value, fetchedAt: DateTime.now());
    while (_store.length > maxEntries) {
      _store.remove(_store.keys.first);
    }
  }

  void invalidate(String key) {
    _store.remove(key);
  }

  void invalidatePrefix(String prefix) {
    final keys = _store.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      _store.remove(key);
    }
  }

  void _touch(String key, _CacheEntry entry) {
    _store.remove(key);
    _store[key] = entry;
  }
}

class _CacheEntry {
  const _CacheEntry({required this.value, required this.fetchedAt});

  final Object value;
  final DateTime fetchedAt;
}
