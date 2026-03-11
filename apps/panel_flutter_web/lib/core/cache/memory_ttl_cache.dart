class MemoryTtlCache {
  MemoryTtlCache._();

  static final MemoryTtlCache instance = MemoryTtlCache._();

  final Map<String, _CacheEntry<Object?>> _entries = <String, _CacheEntry<Object?>>{};

  Future<T> getOrLoad<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() loader,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _entries[key];
      if (cached != null && !cached.isExpired) {
        return cached.value as T;
      }
    }

    final loaded = await loader();
    _entries[key] = _CacheEntry<Object?>(
      value: loaded,
      expiresAt: DateTime.now().add(ttl),
    );
    _purgeExpired();
    return loaded;
  }

  void invalidate(String key) {
    _entries.remove(key);
  }

  void invalidatePrefix(String prefix) {
    final keys = _entries.keys.where((key) => key.startsWith(prefix)).toList(growable: false);
    for (final key in keys) {
      _entries.remove(key);
    }
  }

  void clear() {
    _entries.clear();
  }

  void _purgeExpired() {
    final now = DateTime.now();
    final expiredKeys = _entries.entries
        .where((entry) => entry.value.expiresAt.isBefore(now))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in expiredKeys) {
      _entries.remove(key);
    }
  }
}

class _CacheEntry<T> {
  const _CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final T value;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}
