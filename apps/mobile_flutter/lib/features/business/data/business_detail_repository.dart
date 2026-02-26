import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/swr_payload.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../domain/business_detail.dart';

final businessDetailRepositoryProvider = Provider<BusinessDetailRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return BusinessDetailRepository(client, ref.watch(appTelemetryProvider));
});

class _CacheEntry {
  const _CacheEntry({required this.data, required this.fetchedAt});
  final BusinessDetail data;
  final DateTime fetchedAt;
}

class BusinessDetailRepository {
  BusinessDetailRepository(this.client, this._telemetry);
  final SupabaseClient client;
  final AppTelemetry _telemetry;

  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _CacheEntry> _cache = {};

  Future<BusinessDetail> getBusinessDetail(
    String businessId, {
    int latestLimit = 5,
    bool force = false,
  }) async {
    final key = '$businessId|$latestLimit';
    final cached = _cache[key];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.data;
    }

    try {
      final res = await _telemetry.traceRpc<dynamic>(
        operation: 'get_business_detail',
        run: () => client.rpc(
          'get_business_detail_v1',
          params: {
            'p_business_id': businessId,
            'p_latest_reviews_limit': latestLimit,
          },
        ),
        sampleRate: 0.2,
      );
      final detail = BusinessDetail.fromJson(
        (res as Map).cast<String, dynamic>(),
      );
      _cache[key] = _CacheEntry(data: detail, fetchedAt: DateTime.now());
      await OfflineCachePrefs.saveBusinessDetail(
        businessId: businessId,
        latestLimit: latestLimit,
        detail: detail,
      );
      return detail;
    } catch (e) {
      final stale = _cache[key];
      if (stale != null) return stale.data;
      final cached = await OfflineCachePrefs.loadBusinessDetail(
        businessId: businessId,
        latestLimit: latestLimit,
      );
      if (cached != null) return cached;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<SwrPayload<BusinessDetail>> getBusinessDetailSWR(
    String businessId, {
    int latestLimit = 5,
  }) async {
    final key = '$businessId|$latestLimit';
    final cached = _cache[key];
    if (cached != null) {
      final isFresh = DateTime.now().difference(cached.fetchedAt) < _ttl;
      if (isFresh) {
        return SwrPayload(data: cached.data, isStale: false);
      }
      return SwrPayload(
        data: cached.data,
        isStale: true,
        refresh: getBusinessDetail(
          businessId,
          latestLimit: latestLimit,
          force: true,
        ),
      );
    }

    final disk = await OfflineCachePrefs.loadBusinessDetail(
      businessId: businessId,
      latestLimit: latestLimit,
    );
    if (disk != null) {
      return SwrPayload(
        data: disk,
        isStale: true,
        refresh: getBusinessDetail(
          businessId,
          latestLimit: latestLimit,
          force: true,
        ),
      );
    }

    final live = await getBusinessDetail(businessId, latestLimit: latestLimit);
    return SwrPayload(data: live, isStale: false);
  }
}
