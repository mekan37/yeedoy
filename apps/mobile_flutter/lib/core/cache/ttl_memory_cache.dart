class TtlMemoryCache {
  final Map<String, _CacheEntry> _store = <String, _CacheEntry>{};

  T? getFresh<T extends Object>(String key, {required Duration ttl}) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) > ttl) return null;
    final value = entry.value;
    if (value is T) return value;
    return null;
  }

  T? getStale<T extends Object>(String key) {
    final value = _store[key]?.value;
    if (value is T) return value;
    return null;
  }

  void set<T extends Object>(String key, T value) {
    _store[key] = _CacheEntry(value: value, fetchedAt: DateTime.now());
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
}

class _CacheEntry {
  const _CacheEntry({required this.value, required this.fetchedAt});

  final Object value;
  final DateTime fetchedAt;
}
