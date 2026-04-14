import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/ttl_memory_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_analytics_models.dart';

final ownerAnalyticsRepositoryProvider = Provider<OwnerAnalyticsRepository>((
  ref,
) {
  return OwnerAnalyticsRepository(ref.watch(supabaseProvider));
});

class OwnerAnalyticsRepository {
  OwnerAnalyticsRepository(this.client);

  final SupabaseClient client;
  static final TtlMemoryCache _cache = TtlMemoryCache();
  static const Duration _ttl = Duration(minutes: 5);

  Future<OwnerAnalyticsHourlySnapshot> fetchAnalyticsHourly({
    required String businessId,
    int hours = 24,
  }) async {
    final key = 'owner_analytics_hourly|$businessId|$hours';
    final fresh = _cache.getFresh<OwnerAnalyticsHourlySnapshot>(key, ttl: const Duration(minutes: 5));
    if (fresh != null) return fresh;
    try {
      final res = await client.rpc(
        'list_owner_analytics_hourly_v1',
        params: {'p_business_id': businessId, 'p_hours': hours},
      );
      final snapshot = OwnerAnalyticsHourlySnapshot.fromMap(
        (res as Map).cast<String, dynamic>(),
      );
      _cache.set(key, snapshot);
      return snapshot;
    } catch (error) {
      final stale = _cache.getStale<OwnerAnalyticsHourlySnapshot>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<OwnerAnalyticsSnapshot> fetchAnalytics({
    required String businessId,
    required int days,
    required bool compareBranches,
  }) async {
    final key = 'owner_analytics|$businessId|$days|$compareBranches';
    final fresh = _cache.getFresh<OwnerAnalyticsSnapshot>(key, ttl: _ttl);
    if (fresh != null) return fresh;
    try {
      final res = await client.rpc(
        'list_owner_analytics_v1',
        params: {
          'p_business_id': businessId,
          'p_days': days,
          'p_compare_branches': compareBranches,
        },
      );
      final snapshot = OwnerAnalyticsSnapshot.fromMap(
        (res as Map).cast<String, dynamic>(),
      );
      _cache.set(key, snapshot);
      return snapshot;
    } catch (error) {
      final stale = _cache.getStale<OwnerAnalyticsSnapshot>(key);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
