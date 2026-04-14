import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/swr_payload.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/local_db/local_db_models.dart';
import '../../../core/storage/local_db/local_db_provider.dart';
import '../../../core/storage/local_db/local_db_store.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../domain/business_detail.dart';

final businessDetailRepositoryProvider = Provider<BusinessDetailRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return BusinessDetailRepository(
    client,
    ref.watch(appTelemetryProvider),
    ref.watch(localDbStoreProvider),
  );
});

class _CacheEntry {
  const _CacheEntry({required this.data, required this.fetchedAt});
  final BusinessDetail data;
  final DateTime fetchedAt;
}

class BusinessDetailRepository {
  BusinessDetailRepository(this.client, this._telemetry, this._localDb);
  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final LocalDbStore _localDb;

  static const Duration _ttl = Duration(minutes: 5);
  static const Duration _offlineSnapshotTtl = Duration(days: 7);
  static final Map<String, _CacheEntry> _cache = {};

  Future<BusinessDetail> fetchBusinessDetail(
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
      await _writeLocalSnapshot(
        businessId: businessId,
        latestLimit: latestLimit,
        detail: detail,
      );
      await OfflineCachePrefs.saveBusinessDetail(
        businessId: businessId,
        latestLimit: latestLimit,
        detail: detail,
      );
      return detail;
    } catch (e) {
      final stale = _cache[key];
      if (stale != null) return stale.data;
      final local = await _readLocalSnapshot(
        businessId: businessId,
        latestLimit: latestLimit,
      );
      if (local != null) return local;
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
        refresh: fetchBusinessDetail(
          businessId,
          latestLimit: latestLimit,
          force: true,
        ),
      );
    }

    final local = await _readLocalSnapshot(
      businessId: businessId,
      latestLimit: latestLimit,
    );
    if (local != null) {
      return SwrPayload(
        data: local,
        isStale: true,
        refresh: fetchBusinessDetail(
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
        refresh: fetchBusinessDetail(
          businessId,
          latestLimit: latestLimit,
          force: true,
        ),
      );
    }

    final live = await fetchBusinessDetail(businessId, latestLimit: latestLimit);
    return SwrPayload(data: live, isStale: false);
  }

  Future<void> _writeLocalSnapshot({
    required String businessId,
    required int latestLimit,
    required BusinessDetail detail,
  }) {
    return _localDb.upsert(
      bucket: LocalDbBucket.businessSnapshot,
      id: _localKey(businessId, latestLimit),
      payload: <String, dynamic>{
        'type': 'business_detail',
        'detail': detail.toJson(),
      },
      expiresAt: DateTime.now().toUtc().add(_offlineSnapshotTtl),
    );
  }

  Future<BusinessDetail?> _readLocalSnapshot({
    required String businessId,
    required int latestLimit,
  }) async {
    final record = await _localDb.read(
      LocalDbBucket.businessSnapshot,
      _localKey(businessId, latestLimit),
      allowExpired: true,
    );
    final detail = record?.payload['detail'];
    if (detail is! Map) return null;
    return BusinessDetail.fromJson(detail.cast<String, dynamic>());
  }

  String _localKey(String businessId, int latestLimit) {
    return 'detail|$businessId|$latestLimit';
  }
}
