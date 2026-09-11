import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/local_db/local_db_models.dart';
import '../../../core/storage/local_db/local_db_provider.dart';
import '../../../core/storage/local_db/local_db_store.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../business/domain/business.dart';
import '../domain/price_anomaly.dart';
import '../domain/nearby_campaign.dart';
import '../domain/regional_price_index.dart';
import '../domain/home_feed.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(
    ref.watch(supabaseProvider),
    ref.watch(appTelemetryProvider),
    ref.watch(requestCacheProvider),
    ref.watch(localDbStoreProvider),
  );
});

class DiscoveryRepository {
  DiscoveryRepository(
    this.client,
    this._telemetry,
    RequestCache requestCache,
    this._localDb,
  ) : _cache = requestCache.scope(_cacheScope);

  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final RequestCacheScope _cache;
  final LocalDbStore _localDb;

  static const String _cacheScope = 'discovery';
  static const Duration _searchTtl = Duration(minutes: 1);
  static const Duration _businessTtl = Duration(minutes: 2);
  static const Duration _offlineSnapshotTtl = Duration(days: 7);

  void invalidateBusiness(String id) {
    _cache.invalidate('business|$id');
  }

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  Future<Business> fetchBusiness(String id) async {
    final key = 'business|$id';
    final fresh = _cache.getFresh<Business>(key, ttl: _businessTtl);
    if (fresh != null) return fresh;
    try {
      final business = await _telemetry.traceRpc<Business>(
        operation: 'get_business',
        run: () async {
          // B61: bare select() yerine açık kolon listesi — ayrıca
          // businesses_with_stats'ta hiç bulunmayan (bu yüzden işletme
          // detay sayfasında hep boş görünen) logo_url/neighborhood/
          // price_level/reservation_* kolonları view'a eklendi.
          final res = await client
              .from('businesses_with_stats')
              .select(
                'id,name,category,description,phone,address,city,district,'
                'lat,lng,is_active,created_at,reviews_count,avg_rating,'
                'is_verified,is_open_now,recent_price_verified_count,'
                'logo_url,neighborhood,price_level,accepts_reservations,'
                'reservation_phone,reservation_min_party,'
                'reservation_max_party,reservation_note',
              )
              .eq('id', id)
              .single();
          return Business.fromMap(res);
        },
        sampleRate: 0.3,
      );
      _cache.set(key, business);
      await _writeBusinessSnapshot(business);
      await OfflineCachePrefs.saveRecentBusiness(business);
      return business;
    } catch (_) {
      final stale = _cache.getStale<Business>(key);
      if (stale != null) return stale;
      final local = await _readBusinessSnapshot(id);
      if (local != null) return local;
      final cached = await OfflineCachePrefs.loadBusiness(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCityDistricts() async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'get_city_districts',
      run: () => client.rpc('get_city_districts_v1'),
      sampleRate: 0.2,
    );
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<NearbyCampaign>> fetchNearbyCampaigns({
    double? lat,
    double? lng,
    int radiusKm = 10,
    String? city,
    String? district,
    int limit = 20,
  }) async {
    final cacheKey = _key('nearby_campaigns_v2', {
      'lat': lat?.toStringAsFixed(4),
      'lng': lng?.toStringAsFixed(4),
      'radius': radiusKm,
      'city': city?.trim(),
      'district': district?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<NearbyCampaign>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<NearbyCampaign>>(
        operation: 'get_nearby_campaign_stories_v2',
        run: () async {
          final res = await client.rpc(
            'get_nearby_campaign_stories_v2',
            params: {
              'p_lat': lat,
              'p_lng': lng,
              'p_radius_km': radiusKm,
              'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
              'p_district': (district ?? '').trim().isEmpty
                  ? null
                  : district!.trim(),
              'p_limit': limit,
            },
          );
          return (res as List)
              .whereType<Map>()
              .map((row) => NearbyCampaign.fromMap(row.cast<String, dynamic>()))
              .toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<NearbyCampaign>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<bool> toggleSavedCampaign(String storyId) async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'toggle_saved_campaign_v1',
      run: () => client.rpc(
        'toggle_saved_campaign_v1',
        params: {'p_story_id': storyId},
      ),
      sampleRate: 1,
    );
    if (res is Map && res['saved'] == true) return true;
    return false;
  }

  Future<List<RegionalPriceIndexItem>> fetchRegionalPriceIndex({
    String? city,
    String? district,
    int limit = 12,
  }) async {
    final cacheKey = _key('regional_price_index_v2', {
      'city': city?.trim(),
      'district': district?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<RegionalPriceIndexItem>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<RegionalPriceIndexItem>>(
        operation: 'regional_price_index_v2',
        run: () async {
          final res = await client.rpc(
            'get_regional_price_index_v2',
            params: {
              'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
              'p_district': (district ?? '').trim().isEmpty
                  ? null
                  : district!.trim(),
              'p_limit': limit,
            },
          );
          return (res as List)
              .whereType<Map>()
              .map(
                (row) =>
                    RegionalPriceIndexItem.fromMap(row.cast<String, dynamic>()),
              )
              .toList();
        },
        sampleRate: 0.25,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<RegionalPriceIndexItem>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<PriceAnomalyItem>> fetchPriceAnomalies({
    String? city,
    String? district,
    int days = 30,
    double minChangePct = 40,
    int limit = 20,
  }) async {
    final cacheKey = _key('menu_price_anomalies_v1', {
      'city': city?.trim(),
      'district': district?.trim(),
      'days': days,
      'min_change_pct': minChangePct,
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<PriceAnomalyItem>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<PriceAnomalyItem>>(
        operation: 'menu_price_anomalies_v1',
        run: () async {
          final res = await client.rpc(
            'get_menu_price_anomalies_v1',
            params: {
              'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
              'p_district': (district ?? '').trim().isEmpty
                  ? null
                  : district!.trim(),
              'p_days': days,
              'p_min_change_pct': minChangePct,
              'p_limit': limit,
            },
          );
          return (res as List)
              .whereType<Map>()
              .map(
                (row) => PriceAnomalyItem.fromMap(row.cast<String, dynamic>()),
              )
              .toList();
        },
        sampleRate: 0.25,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<PriceAnomalyItem>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<HomeFeedData> fetchHomeFeed({
    required String city,
    required String district,
    String? neighborhood,
    int nearOpenLimit = 8,
    int topCategoriesLimit = 6,
    int trendingLimit = 8,
  }) async {
    final cacheKey = _key('home_feed_v1', {
      'city': city.trim(),
      'district': district.trim(),
      'neighborhood': neighborhood?.trim(),
      'near_open_limit': nearOpenLimit,
      'top_categories_limit': topCategoriesLimit,
      'trending_limit': trendingLimit,
    });
    final fresh = _cache.getFresh<HomeFeedData>(cacheKey, ttl: _searchTtl);
    if (fresh != null) return fresh;

    try {
      final feed = await _telemetry.traceRpc<HomeFeedData>(
        operation: 'home_feed_v1',
        run: () async {
          final res = await client.rpc(
            'home_feed_v1',
            params: {
              'p_city': city.trim(),
              'p_district': district.trim(),
              'p_neighborhood': (neighborhood ?? '').trim().isEmpty
                  ? null
                  : neighborhood!.trim(),
              'p_near_open_limit': nearOpenLimit,
              'p_top_categories_limit': topCategoriesLimit,
              'p_trending_limit': trendingLimit,
            },
          );
          if (res is Map) {
            return HomeFeedData.fromMap(res.cast<String, dynamic>());
          }
          return HomeFeedData.empty();
        },
        sampleRate: 0.3,
      );
      _cache.set(cacheKey, feed);
      return feed;
    } catch (_) {
      final stale = _cache.getStale<HomeFeedData>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<void> _writeBusinessSnapshot(Business business) {
    return _localDb.upsert(
      bucket: LocalDbBucket.businessSnapshot,
      id: business.id,
      payload: <String, dynamic>{'business': business.toMap()},
      expiresAt: DateTime.now().toUtc().add(_offlineSnapshotTtl),
    );
  }

  Future<Business?> _readBusinessSnapshot(String businessId) async {
    final record = await _localDb.read(
      LocalDbBucket.businessSnapshot,
      businessId,
      allowExpired: true,
    );
    final payload = record?.payload['business'];
    if (payload is! Map) return null;
    return Business.fromMap(payload.cast<String, dynamic>());
  }
}
