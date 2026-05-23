import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ttl_memory_cache.dart';

final requestCacheProvider = Provider<RequestCache>((ref) {
  return RequestCache.shared;
});

class RequestCache {
  RequestCache();

  static final RequestCache shared = RequestCache();

  final TtlMemoryCache _memory = TtlMemoryCache();

  RequestCacheScope scope(String scope) {
    return RequestCacheScope._(this, scope.trim());
  }

  void clearAll() {
    _memory.invalidatePrefix('');
  }

  T? _getFresh<T extends Object>(String key, {required Duration ttl}) {
    return _memory.getFresh<T>(key, ttl: ttl);
  }

  T? _getStale<T extends Object>(String key) {
    return _memory.getStale<T>(key);
  }

  void _set<T extends Object>(String key, T value) {
    _memory.set<T>(key, value);
  }

  void _invalidate(String key) {
    _memory.invalidate(key);
  }

  void _invalidatePrefix(String prefix) {
    _memory.invalidatePrefix(prefix);
  }
}

class RequestCacheScope {
  RequestCacheScope._(this._cache, this._scope);

  final RequestCache _cache;
  final String _scope;

  T? getFresh<T extends Object>(String key, {required Duration ttl}) {
    return _cache._getFresh<T>(_scopedKey(key), ttl: ttl);
  }

  T? getStale<T extends Object>(String key) {
    return _cache._getStale<T>(_scopedKey(key));
  }

  void set<T extends Object>(String key, T value) {
    _cache._set<T>(_scopedKey(key), value);
  }

  void invalidate(String key) {
    _cache._invalidate(_scopedKey(key));
  }

  void invalidatePrefix(String keyPrefix) {
    _cache._invalidatePrefix(_scopedKey(keyPrefix));
  }

  String _scopedKey(String key) {
    return '$_scope|$key';
  }
}

String stableRequestCacheKey(String method, Map<String, Object?> values) {
  final ordered = values.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final payload = ordered
      .map((entry) => '${entry.key}=${entry.value ?? ''}')
      .join('&');
  return '$method|$payload';
}
