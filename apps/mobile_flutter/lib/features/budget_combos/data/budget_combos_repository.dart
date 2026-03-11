import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../domain/budget_combo_models.dart';

class BudgetCombosRepository {
  BudgetCombosRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);

  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'budget_combos';
  static const Duration _comboTtl = Duration(minutes: 2);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<BudgetComboResult>> getCombos(
    BudgetComboQuery query, {
    bool force = false,
  }) async {
    final cacheKey = stableRequestCacheKey('budget_combos', {
      'city': query.city.trim(),
      'district': query.district.trim(),
      'party_size': query.partySize,
      'budget_total_cents': query.budgetTotalCents,
      'category': query.category?.trim(),
      'limit': query.limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<BudgetComboResult>>(
        cacheKey,
        ttl: _comboTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final data = await client.rpc('get_budget_combos_v1', params: {
        'p_city': query.city,
        'p_district': query.district,
        'p_party_size': query.partySize,
        'p_budget_total_cents': query.budgetTotalCents,
        'p_category': query.category,
        'p_limit': query.limit,
      });
      final list = (data as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final items = list.map(BudgetComboResult.fromMap).toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<BudgetComboResult>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
