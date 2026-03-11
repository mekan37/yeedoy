import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/my_suspended_claim_models.dart';

final mySuspendedClaimRepositoryProvider = Provider<MySuspendedClaimRepository>((ref) {
  return MySuspendedClaimRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider),
  );
});

class MySuspendedClaimRepository {
  MySuspendedClaimRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'suspended_meals';
  static const Duration _claimsTtl = Duration(seconds: 75);
  static const Duration _badgeTtl = Duration(seconds: 45);

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<MySuspendedClaimItem>> listClaims({
    required String status,
    int limit = 20,
    int offset = 0,
    bool force = false,
  }) async {
    final key = _key('claims', {
      'status': status.trim(),
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<MySuspendedClaimItem>>(
        key,
        ttl: _claimsTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_my_suspended_claims_v1', params: {
        'p_status': status,
        'p_limit': limit,
        'p_offset': offset,
      });
      final items = (res as List)
          .map((row) => MySuspendedClaimItem.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(key, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<MySuspendedClaimItem>>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MySuspendedBadge> getBadge({bool force = false}) async {
    const key = 'badge|current';
    if (!force) {
      final fresh = _cache.getFresh<MySuspendedBadge>(key, ttl: _badgeTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_my_suspended_claim_badge_v1');
      final badge = MySuspendedBadge.fromMap((res as Map).cast<String, dynamic>());
      _cache.set(key, badge);
      return badge;
    } catch (e) {
      final stale = _cache.getStale<MySuspendedBadge>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
