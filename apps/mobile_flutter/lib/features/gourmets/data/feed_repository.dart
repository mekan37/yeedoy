import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/feed_item.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FeedRepository(client, ref.watch(requestCacheProvider));
});

class FeedRepository {
  FeedRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'gourmets_feed';
  static const Duration _feedTtl = Duration(seconds: 75);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<FeedItem>> getMyFeed({
    int limit = 20,
    int offset = 0,
    bool force = false,
  }) async {
    final key = stableRequestCacheKey('my_feed', {
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<FeedItem>>(key, ttl: _feedTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_my_feed_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final items = (res as List)
          .map((row) => FeedItem.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(key, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<FeedItem>>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
