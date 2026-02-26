import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/ttl_memory_cache.dart';
import '../../../core/cache/swr_payload.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../business/domain/business.dart';
import '../domain/business_card.dart';
import '../domain/price_anomaly.dart';
import '../domain/nearby_campaign.dart';
import '../domain/regional_price_index.dart';
import '../domain/home_feed.dart';
import '../domain/top_business.dart';
import '../domain/trend_business.dart';

final discoveryRepoProvider = Provider<DiscoveryRepo>((ref) {
  return DiscoveryRepo(
    ref.watch(supabaseProvider),
    ref.watch(appTelemetryProvider),
    ref.watch(productGuardrailOverridesProvider),
  );
});

class DiscoveryRepo {
  DiscoveryRepo(this.client, this._telemetry, this._guardrails);

  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final ProductGuardrailOverrides _guardrails;

  static final TtlMemoryCache _cache = TtlMemoryCache();
  static const Duration _listTtl = Duration(minutes: 2);
  static const Duration _searchTtl = Duration(minutes: 1);

  String _key(String method, Map<String, Object?> values) {
    final ordered = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final payload = ordered
        .map((entry) => '${entry.key}=${entry.value ?? ''}')
        .join('&');
    return '$method|$payload';
  }

  String _feedDiskKey({String? query, String? category, required int limit}) {
    return _key('feed', {
      'query': query?.trim(),
      'category': category?.trim(),
      'limit': limit,
    });
  }

  Future<List<Business>> listBusinesses({
    String? query,
    String? category,
    int limit = 30,
  }) async {
    final cacheKey = _key('list_businesses', {
      'query': query?.trim(),
      'category': category?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<Business>>(cacheKey, ttl: _listTtl);
    if (fresh != null) return fresh;

    try {
      final businesses = await _telemetry.traceRpc<List<Business>>(
        operation: 'list_businesses',
        run: () async {
          var q = client.from('businesses_with_stats').select();
          if (category != null && category.isNotEmpty) {
            q = q.eq('category', category);
          }
          if (query != null && query.trim().isNotEmpty) {
            q = q.ilike('name', '%${query.trim()}%');
          }
          final res = await q
              .order('created_at', ascending: false)
              .limit(limit);
          return (res as List).map((e) => Business.fromMap(e)).toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, businesses);
      await OfflineCachePrefs.saveDiscoveryFeed(
        _feedDiskKey(query: query, category: category, limit: limit),
        businesses.map((e) => e.toMap()).toList(),
      );
      await OfflineCachePrefs.saveCategoriesSnapshot(
        businesses
            .map((e) => e.category)
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList(),
      );
      return businesses;
    } catch (_) {
      final stale = _cache.getStale<List<Business>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<SwrPayload<List<Business>>> listBusinessesSWR({
    String? query,
    String? category,
    int limit = 30,
  }) async {
    final cacheKey = _key('list_businesses', {
      'query': query?.trim(),
      'category': category?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<Business>>(cacheKey, ttl: _listTtl);
    if (fresh != null) {
      return SwrPayload(data: fresh, isStale: false);
    }

    final stale = _cache.getStale<List<Business>>(cacheKey);
    if (stale != null) {
      return SwrPayload(
        data: stale,
        isStale: true,
        refresh: listBusinesses(query: query, category: category, limit: limit),
      );
    }

    final disk = await OfflineCachePrefs.loadDiscoveryFeed(
      _feedDiskKey(query: query, category: category, limit: limit),
    );
    if (disk != null && disk.isNotEmpty) {
      final items = disk.map(Business.fromMap).toList();
      _cache.set(cacheKey, items);
      return SwrPayload(
        data: items,
        isStale: true,
        refresh: listBusinesses(query: query, category: category, limit: limit),
      );
    }

    final live = await listBusinesses(
      query: query,
      category: category,
      limit: limit,
    );
    return SwrPayload(data: live, isStale: false);
  }

  Future<Business> getBusiness(String id) async {
    try {
      final business = await _telemetry.traceRpc<Business>(
        operation: 'get_business',
        run: () async {
          final res = await client
              .from('businesses_with_stats')
              .select()
              .eq('id', id)
              .single();
          return Business.fromMap(res);
        },
        sampleRate: 0.3,
      );
      await OfflineCachePrefs.saveRecentBusiness(business);
      return business;
    } catch (_) {
      final cached = await OfflineCachePrefs.loadBusiness(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<TopBusiness>> getTopBusinesses({
    required String period,
    int limit = 10,
    int minReviews = 2,
  }) async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'get_top_businesses',
      run: () => client.rpc(
        'get_top_businesses',
        params: {
          'p_period': period,
          'p_limit': limit,
          'p_min_reviews': minReviews,
        },
      ),
      sampleRate: 0.3,
    );

    return (res as List).map((e) => TopBusiness.fromMap(e)).toList();
  }

  Future<List<TopBusiness>> getDailyPicks({int limit = 3}) async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'get_daily_picks',
      run: () => client.rpc('get_daily_picks', params: {'p_limit': limit}),
      sampleRate: 0.3,
    );
    return (res as List).map((e) => TopBusiness.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCityDistricts() async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'get_city_districts',
      run: () => client.rpc('get_city_districts_v1'),
      sampleRate: 0.2,
    );
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<BusinessCardModel>> searchBusinesses({
    String? query,
    String? city,
    String? district,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final cacheKey = _key('search_businesses', {
      'query': query?.trim(),
      'city': city?.trim(),
      'district': district?.trim(),
      'category': category?.trim(),
      'limit': limit,
      'offset': offset,
    });
    final fresh = _cache.getFresh<List<BusinessCardModel>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final cards = await _telemetry.traceRpc<List<BusinessCardModel>>(
        operation: 'search_businesses',
        run: () async {
          final res = await client.rpc(
            'search_businesses_v1',
            params: {
              'p_query': (query ?? '').trim().isEmpty ? null : query!.trim(),
              'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
              'p_district': (district ?? '').trim().isEmpty
                  ? null
                  : district!.trim(),
              'p_category': (category ?? '').trim().isEmpty
                  ? null
                  : category!.trim(),
              'p_limit': limit,
              'p_offset': offset,
            },
          );
          final cards = (res as List)
              .map((e) => BusinessCardModel.fromMap(e))
              .toList();
          return _attachOwnerVerification(cards);
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, cards);
      return cards;
    } catch (_) {
      final stale = _cache.getStale<List<BusinessCardModel>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<BusinessCardModel>> searchNearby({
    required double lat,
    required double lng,
    required int radiusKm,
    String? query,
    String? category,
    bool openNow = false,
    int limit = 30,
  }) async {
    final cacheKey = _key('search_nearby', {
      'lat': lat.toStringAsFixed(4),
      'lng': lng.toStringAsFixed(4),
      'radius': radiusKm,
      'query': query?.trim(),
      'category': category?.trim(),
      'open': openNow,
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<BusinessCardModel>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final cards = await _telemetry.traceRpc<List<BusinessCardModel>>(
        operation: 'search_nearby_businesses',
        run: () async {
          final res = await client.rpc(
            'search_nearby_businesses_v3',
            params: {
              'p_lat': lat,
              'p_lng': lng,
              'p_radius_km': radiusKm,
              'p_query': (query ?? '').trim().isEmpty ? null : query!.trim(),
              'p_category': (category ?? '').trim().isEmpty
                  ? null
                  : category!.trim(),
              'p_open_now': openNow,
              'p_limit': limit,
            },
          );
          final cards = (res as List)
              .map((e) => BusinessCardModel.fromMap(e))
              .toList();
          return _attachOwnerVerification(cards);
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, cards);
      return cards;
    } catch (_) {
      final stale = _cache.getStale<List<BusinessCardModel>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<BusinessCardModel>> getSponsoredBusinesses({
    required String surface,
    String? city,
    String? district,
    String? category,
    int limit = 6,
  }) async {
    final res = await _telemetry.traceRpc<dynamic>(
      operation: 'get_sponsored_businesses',
      run: () => client.rpc(
        'get_sponsored_businesses_v1',
        params: {
          'p_surface': surface,
          'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
          'p_district': (district ?? '').trim().isEmpty
              ? null
              : district!.trim(),
          'p_category': (category ?? '').trim().isEmpty
              ? null
              : category!.trim(),
          'p_limit': limit,
        },
      ),
      sampleRate: 0.3,
    );

    final items = (res as List)
        .map((e) => BusinessCardModel.fromSponsoredMap(e))
        .toList();
    if (items.isEmpty) return items;

    final ids = items.map((e) => e.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return items;

    try {
      final statsRes = await client
          .from('businesses_with_stats')
          .select('id, avg_rating, quality_score, recent_price_verified_count')
          .inFilter('id', ids);
      final statsMap = <String, Map<String, dynamic>>{};
      for (final row in (statsRes as List).whereType<Map>()) {
        final data = row.cast<String, dynamic>();
        statsMap[(data['id'] ?? '').toString()] = data;
      }
      final enriched = items.map((b) {
        final data = statsMap[b.id];
        if (data == null) return b;
        final quality = (data['quality_score'] as num?)?.toDouble() ?? 0;
        final recent =
            ((data['recent_price_verified_count'] as num?)?.toInt() ?? 0).clamp(
              0,
              5,
            );
        final rating = (data['avg_rating'] as num?)?.toDouble() ?? 0;
        final trustScore =
            ((quality.clamp(0, 5) / 5) * 0.7) + ((recent / 5) * 0.3);
        return b.copyWith(
          avgRating: rating,
          qualityScore: quality,
          trustScore: trustScore.clamp(0, 1).toDouble(),
          recentPriceVerifiedCount: recent,
        );
      }).toList();

      final filtered = enriched.where((b) {
        final trust = b.trustScore ?? 0;
        final rating = b.avgRating ?? 0;
        return trust >= _guardrails.minSponsoredTrustScore &&
            rating >= _guardrails.minSponsoredRating;
      }).toList();

      return filtered;
    } catch (_) {
      return items;
    }
  }

  Future<List<NearbyCampaign>> getNearbyCampaigns({
    double? lat,
    double? lng,
    int radiusKm = 10,
    String? city,
    String? district,
    int limit = 20,
  }) async {
    return const <NearbyCampaign>[];
  }

  Future<List<BusinessCardModel>> _attachOwnerVerification(
    List<BusinessCardModel> items,
  ) async {
    if (items.isEmpty) return items;
    final ids = items.map((e) => e.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return items;
    try {
      final res = await client
          .from('owner_claims')
          .select('business_id, is_verified, status')
          .inFilter('business_id', ids)
          .inFilter('status', ['approved', 'accepted']);
      final map = <String, bool>{};
      for (final row in (res as List).whereType<Map>()) {
        final m = row.cast<String, dynamic>();
        final businessId = (m['business_id'] ?? '').toString();
        if (businessId.isEmpty) continue;
        final isVerified = m['is_verified'] == true;
        map[businessId] = (map[businessId] ?? false) || isVerified;
      }
      return items
          .map(
            (item) => item.copyWith(
              ownerVerified: map[item.id] == true ? true : false,
            ),
          )
          .toList();
    } catch (_) {
      return items;
    }
  }

  Future<List<TrendBusiness>> getDistrictTopViews({
    required String city,
    required String district,
    String? neighborhood,
    int limit = 10,
  }) async {
    final cacheKey = _key('district_top_views', {
      'city': city.trim(),
      'district': district.trim(),
      'neighborhood': neighborhood?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<TrendBusiness>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<TrendBusiness>>(
        operation: 'district_top_views',
        run: () async {
          final res = await client.rpc(
            'get_district_top_views_v1',
            params: {
              'p_city': city.trim(),
              'p_district': district.trim(),
              'p_neighborhood': (neighborhood ?? '').trim().isEmpty
                  ? null
                  : neighborhood,
              'p_limit': limit,
            },
          );
          return (res as List).whereType<Map>().map((e) {
            final data = e.cast<String, dynamic>();
            return TrendBusiness(
              business: BusinessCardModel.fromMap(data),
              metric: (data['views_count'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<TrendBusiness>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<TrendBusiness>> getDistrictPriceChanges({
    required String city,
    required String district,
    String? neighborhood,
    int limit = 10,
  }) async {
    final cacheKey = _key('district_price_changes', {
      'city': city.trim(),
      'district': district.trim(),
      'neighborhood': neighborhood?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<TrendBusiness>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<TrendBusiness>>(
        operation: 'district_price_changes',
        run: () async {
          final res = await client.rpc(
            'get_district_price_changes_v1',
            params: {
              'p_city': city.trim(),
              'p_district': district.trim(),
              'p_neighborhood': (neighborhood ?? '').trim().isEmpty
                  ? null
                  : neighborhood,
              'p_limit': limit,
            },
          );
          return (res as List).whereType<Map>().map((e) {
            final data = e.cast<String, dynamic>();
            return TrendBusiness(
              business: BusinessCardModel.fromMap(data),
              metric: (data['price_changes_count'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<TrendBusiness>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<TrendBusiness>> getDistrictNightFavorites({
    required String city,
    required String district,
    String? neighborhood,
    int limit = 10,
  }) async {
    final cacheKey = _key('district_night_favorites', {
      'city': city.trim(),
      'district': district.trim(),
      'neighborhood': neighborhood?.trim(),
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<TrendBusiness>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<TrendBusiness>>(
        operation: 'district_night_favorites',
        run: () async {
          final res = await client.rpc(
            'get_district_night_favorites_v1',
            params: {
              'p_city': city.trim(),
              'p_district': district.trim(),
              'p_neighborhood': (neighborhood ?? '').trim().isEmpty
                  ? null
                  : neighborhood,
              'p_limit': limit,
            },
          );
          return (res as List).whereType<Map>().map((e) {
            final data = e.cast<String, dynamic>();
            return TrendBusiness(
              business: BusinessCardModel.fromMap(data),
              metric: (data['favorites_count'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        },
        sampleRate: 0.2,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<TrendBusiness>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<List<RegionalPriceIndexItem>> getRegionalPriceIndex({
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

  Future<List<PriceAnomalyItem>> getPriceAnomalies({
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

  Future<List<Map<String, dynamic>>> getBusinessPriceHistory({
    required String businessId,
    int days = 60,
    int limit = 120,
  }) async {
    final cacheKey = _key('business_price_history_v1', {
      'business_id': businessId,
      'days': days,
      'limit': limit,
    });
    final fresh = _cache.getFresh<List<Map<String, dynamic>>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) return fresh;

    try {
      final items = await _telemetry.traceRpc<List<Map<String, dynamic>>>(
        operation: 'business_price_history_v1',
        run: () async {
          final res = await client.rpc(
            'get_business_price_history_v1',
            params: {
              'p_business_id': businessId,
              'p_days': days,
              'p_limit': limit,
            },
          );
          return (res as List)
              .whereType<Map>()
              .map((row) => row.cast<String, dynamic>())
              .toList();
        },
        sampleRate: 0.25,
      );
      _cache.set(cacheKey, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<Map<String, dynamic>>>(cacheKey);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<HomeFeedData> getHomeFeed({
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
}

