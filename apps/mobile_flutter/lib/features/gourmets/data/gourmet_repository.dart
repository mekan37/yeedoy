import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/gourmet_user.dart';

final gourmetRepositoryProvider = Provider<GourmetRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return GourmetRepository(client, ref.watch(requestCacheProvider));
});

class GourmetRepository {
  GourmetRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'gourmets';
  static const Duration _listTtl = Duration(seconds: 75);

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  void invalidateDiscover() {
    _cache.invalidatePrefix('discover|');
  }

  void invalidateFollowing() {
    _cache.invalidatePrefix('following|');
  }

  Future<List<GourmetUser>> discover({
    int limit = 20,
    int offset = 0,
    bool force = false,
  }) async {
    final key = _key('discover', {
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<GourmetUser>>(key, ttl: _listTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('discover_gourmets_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final items = (res as List)
          .map((row) => GourmetUser.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(key, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GourmetUser>>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GourmetUser>> getMyFollowing({
    int limit = 20,
    int offset = 0,
    bool force = false,
  }) async {
    final key = _key('following', {
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<GourmetUser>>(key, ttl: _listTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_my_following_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final items = (res as List)
          .map((row) => GourmetUser.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(key, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GourmetUser>>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
