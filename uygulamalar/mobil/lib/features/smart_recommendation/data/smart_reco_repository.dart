import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../domain/smart_reco_models.dart';

class SmartRecoRepository {
  SmartRecoRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);

  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'smart_reco';
  static const Duration _ttl = Duration(minutes: 2);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<SmartRecommendation>> fetchRecommendations(
    SmartRecoQuery query, {
    bool force = false,
  }) async {
    final cacheKey = stableRequestCacheKey('smart_reco', {
      'city': query.city.trim(),
      'district': query.district.trim(),
      'party_size': query.partySize,
      'budget_max_cents': query.budgetMaxCents,
      'limit': query.limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<SmartRecommendation>>(
        cacheKey,
        ttl: _ttl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final data = await client.rpc('get_smart_recommendations_v1', params: {
        'p_city': query.city,
        'p_district': query.district,
        'p_party_size': query.partySize,
        'p_budget_max_cents': query.budgetMaxCents,
        'p_limit': query.limit,
      });
      final list = (data as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final items = list.map(SmartRecommendation.fromMap).toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<SmartRecommendation>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
