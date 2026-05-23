import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/onbellek/istek_onbellegi.dart';
import '../../../core/izleme/uygulama_telemetrisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/performans/performans_esikleri.dart';
import '../../../core/gizlilik/kisisel_veri_minimizator.dart';
import '../../../core/arama/sorgu_normalizlayici.dart';
import '../../isletme/data/ogun_karti_saglayicilari_deposu.dart';
import '../../isletme/domain/ogun_karti_saglayici_secenegi.dart';
import '../domain/isletme_karti.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  final telemetry = ref.watch(appTelemetryProvider);
  return SearchRepository(
    client,
    telemetry,
    ref.watch(requestCacheProvider),
    ref.watch(mealCardProvidersRepositoryProvider),
  );
});

class SearchRepository {
  SearchRepository(
    this.client,
    this._telemetry,
    RequestCache requestCache,
    this._mealCardProvidersRepository,
  ) : _cache = requestCache.scope(_cacheScope);

  final SupabaseClient client;
  final AppTelemetry _telemetry;
  final RequestCacheScope _cache;
  final MealCardProvidersRepository _mealCardProvidersRepository;

  static const String _cacheScope = 'discovery_search';
  static const Duration _searchTtl = Duration(seconds: 45);

  void clearCache() {
    _cache.invalidatePrefix('');
  }

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  Future<List<BusinessCardModel>> searchBusinesses({
    required String query,
    String? city,
    String? district,
    double? userLat,
    double? userLng,
    List<String> mealCardKeys = const [],
    int limit = 50,
    int offset = 0,
  }) async {
    final watch = Stopwatch()..start();
    final normalizedMealCardKeys = _normalizeMealCardKeys(mealCardKeys);
    final cacheKey = _key('search_businesses', {
      'query': query.trim(),
      'city': city?.trim(),
      'district': district?.trim(),
      'lat': userLat?.toStringAsFixed(2),
      'lng': userLng?.toStringAsFixed(2),
      'meal_card_keys': normalizedMealCardKeys,
      'limit': limit,
      'offset': offset,
    });
    final fresh = _cache.getFresh<List<BusinessCardModel>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) {
      watch.stop();
      unawaited(
        _telemetry.logSearchLatency(
          elapsed: watch.elapsed,
          cacheType: SearchCacheType.hit,
        ),
      );
      return fresh;
    }

    final rows = normalizedMealCardKeys.isEmpty
        ? await _searchBusinessesBase(
            query: query,
            city: city,
            district: district,
            userLat: userLat,
            userLng: userLng,
            limit: limit,
            offset: offset,
          )
        : await _filterPagedByMealCards(
            mealCardKeys: normalizedMealCardKeys,
            limit: limit,
            offset: offset,
            fetchBatch: ({required int batchLimit, required int batchOffset}) {
              return _searchBusinessesBase(
                query: query,
                city: city,
                district: district,
                userLat: userLat,
                userLng: userLng,
                limit: batchLimit,
                offset: batchOffset,
              );
            },
          );

    _cache.set(cacheKey, rows);
    watch.stop();
    unawaited(
      _telemetry.logSearchLatency(
        elapsed: watch.elapsed,
        cacheType: SearchCacheType.miss,
      ),
    );
    return rows;
  }

  Future<List<BusinessCardModel>> _searchBusinessesBase({
    required String query,
    String? city,
    String? district,
    double? userLat,
    double? userLng,
    required int limit,
    required int offset,
  }) async {
    final normalized = normalizeSearchQuery(query);
    final trigramRes = await client.rpc(
      'search_businesses_v1',
      params: {
        'p_query': normalized,
        'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
        'p_district': (district ?? '').trim().isEmpty ? null : district!.trim(),
        'p_lat': userLat,
        'p_lng': userLng,
        'p_radius_km': 50.0,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    final trigramRows = (trigramRes as List)
        .map((e) => BusinessCardModel.fromMap(e))
        .toList(growable: false);
    List<BusinessCardModel> prefixRows = const [];
    try {
      prefixRows = await _searchBusinessesPrefix(
        normalizedQuery: normalized,
        city: city,
        district: district,
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[SearchRepository] prefix fallback failed: $error');
      }
    }
    return _mergeSearchRows(
      prefixRows: prefixRows,
      trigramRows: trigramRows,
      limit: limit,
    );
  }

  Future<List<BusinessCardModel>> searchNearby({
    required double userLat,
    required double userLng,
    double radiusKm = 5,
    String? city,
    String? district,
    String? query,
    List<String> mealCardKeys = const [],
    int limit = 50,
    int offset = 0,
  }) async {
    final watch = Stopwatch()..start();
    final roundedLat = roundCoordinate(userLat, decimals: 3);
    final roundedLng = roundCoordinate(userLng, decimals: 3);
    final normalizedMealCardKeys = _normalizeMealCardKeys(mealCardKeys);
    final cacheKey = _key('search_nearby', {
      'lat': roundedLat.toStringAsFixed(3),
      'lng': roundedLng.toStringAsFixed(3),
      'radius': radiusKm.toStringAsFixed(1),
      'city': city?.trim(),
      'district': district?.trim(),
      'query': query?.trim(),
      'meal_card_keys': normalizedMealCardKeys,
      'limit': limit,
      'offset': offset,
    });
    final fresh = _cache.getFresh<List<BusinessCardModel>>(
      cacheKey,
      ttl: _searchTtl,
    );
    if (fresh != null) {
      watch.stop();
      unawaited(
        _telemetry.logSearchLatency(
          elapsed: watch.elapsed,
          cacheType: SearchCacheType.hit,
          surface: 'discover_nearby',
        ),
      );
      return fresh;
    }

    final rows = normalizedMealCardKeys.isEmpty
        ? await _searchNearbyBase(
            userLat: roundedLat,
            userLng: roundedLng,
            radiusKm: radiusKm,
            city: city,
            district: district,
            query: query,
            limit: limit,
            offset: offset,
          )
        : await _filterPagedByMealCards(
            mealCardKeys: normalizedMealCardKeys,
            limit: limit,
            offset: offset,
            fetchBatch: ({required int batchLimit, required int batchOffset}) {
              return _searchNearbyBase(
                userLat: roundedLat,
                userLng: roundedLng,
                radiusKm: radiusKm,
                city: city,
                district: district,
                query: query,
                limit: batchLimit,
                offset: batchOffset,
              );
            },
          );

    _cache.set(cacheKey, rows);
    watch.stop();
    unawaited(
      _telemetry.logSearchLatency(
        elapsed: watch.elapsed,
        cacheType: SearchCacheType.miss,
        surface: 'discover_nearby',
      ),
    );
    return rows;
  }

  Future<List<BusinessCardModel>> _searchNearbyBase({
    required double userLat,
    required double userLng,
    required double radiusKm,
    String? city,
    String? district,
    String? query,
    required int limit,
    required int offset,
  }) async {
    final normalized = normalizeSearchQuery(query ?? '');
    final response = await client.rpc(
      'search_nearby_businesses_v3',
      params: {
        'p_user_lat': userLat,
        'p_user_lng': userLng,
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
        'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
        'p_district': (district ?? '').trim().isEmpty ? null : district!.trim(),
        'p_query': normalized.isEmpty ? null : normalized,
      },
    );
    return (response as List)
        .map((e) => BusinessCardModel.fromMap(e))
        .toList(growable: false);
  }

  Future<List<BusinessCardModel>> _searchBusinessesPrefix({
    required String normalizedQuery,
    String? city,
    String? district,
    required int limit,
    required int offset,
  }) async {
    if (normalizedQuery.isEmpty) return const [];
    var query = client
        .from('businesses_with_stats')
        .select('id,name,category,city,district,address,lat,lng,avg_rating')
        .ilike('name', '$normalizedQuery%');
    if ((city ?? '').trim().isNotEmpty) {
      query = query.eq('city', city!.trim());
    }
    if ((district ?? '').trim().isNotEmpty) {
      query = query.eq('district', district!.trim());
    }
    final response = await query.range(offset, offset + limit - 1);
    return (response as List)
        .map((e) => BusinessCardModel.fromMap(e))
        .toList(growable: false);
  }

  List<BusinessCardModel> _mergeSearchRows({
    required List<BusinessCardModel> prefixRows,
    required List<BusinessCardModel> trigramRows,
    required int limit,
  }) {
    final map = <String, BusinessCardModel>{};
    for (final row in prefixRows) {
      map[row.id] = row;
    }
    for (final row in trigramRows) {
      map.putIfAbsent(row.id, () => row);
    }
    return map.values.take(limit).toList(growable: false);
  }

  Future<List<BusinessCardModel>> enrichBusinessCards(
    List<BusinessCardModel> cards,
  ) async {
    if (cards.isEmpty) return cards;
    final ids = cards.map((e) => e.id).toList(growable: false);

    final ratings = <String, double>{};
    final qualityScores = <String, double>{};
    final medianPrice = <String, int>{};
    final openNow = <String, bool>{};
    final recentVerified = <String, int>{};
    var mealCardProviders = <String, List<MealCardProviderOption>>{};

    try {
      final rows = await client
          .from('businesses_with_stats')
          .select('id,avg_rating,quality_score')
          .inFilter('id', ids);
      for (final row in (rows as List)) {
        final map = (row as Map<String, dynamic>);
        ratings[map['id'].toString()] = ((map['avg_rating'] as num?) ?? 0)
            .toDouble();
        qualityScores[map['id'].toString()] =
            ((map['quality_score'] as num?) ?? 0).toDouble();
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('business_price_index_v1')
          .select('business_id,median_price_cents')
          .inFilter('business_id', ids);
      for (final row in (rows as List)) {
        final map = (row as Map<String, dynamic>);
        medianPrice[map['business_id'].toString()] =
            ((map['median_price_cents'] as num?) ?? 0).toInt();
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('business_hours')
          .select(
            'business_id,mon_open,mon_close,tue_open,tue_close,wed_open,wed_close,thu_open,thu_close,fri_open,fri_close,sat_open,sat_close,sun_open,sun_close',
          )
          .inFilter('business_id', ids);
      for (final row in (rows as List)) {
        final map = (row as Map<String, dynamic>);
        openNow[map['business_id'].toString()] = _isOpenNow(map);
      }
    } catch (_) {}

    try {
      final fromIso = DateTime.now()
          .subtract(const Duration(days: 7))
          .toUtc()
          .toIso8601String();
      final rows = await client
          .from('feed_events')
          .select('business_id')
          .eq('type', 'price_verified')
          .gte('created_at', fromIso)
          .inFilter('business_id', ids);
      for (final row in (rows as List)) {
        final map = (row as Map<String, dynamic>);
        final businessId = map['business_id'].toString();
        recentVerified[businessId] = (recentVerified[businessId] ?? 0) + 1;
      }
    } catch (_) {}

    try {
      mealCardProviders = await _mealCardProvidersRepository
          .listBusinessProvidersByIds(ids);
    } catch (_) {}

    return cards.map((card) {
      final rating = ratings[card.id] ?? card.avgRating ?? 0;
      final quality = qualityScores[card.id] ?? card.qualityScore ?? 0;
      final verified =
          recentVerified[card.id] ?? card.recentPriceVerifiedCount ?? 0;
      final isOpen = openNow[card.id] ?? card.isOpenNow ?? false;
      final trustScore = _computeTrustScore(
        qualityScore: quality,
        recentVerifiedCount: verified,
        avgRating: rating,
        isOpenNow: isOpen,
      );
      return card.copyWith(
        avgRating: rating,
        qualityScore: quality,
        trustScore: trustScore,
        medianPriceCents: medianPrice[card.id],
        isOpenNow: isOpen,
        recentPriceVerifiedCount: verified,
        mealCardProviders: mealCardProviders[card.id] ?? card.mealCardProviders,
      );
    }).toList(growable: false);
  }

  List<String> _normalizeMealCardKeys(List<String> mealCardKeys) {
    final normalized = mealCardKeys
        .map((key) => key.trim().toLowerCase())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList(growable: false);
    normalized.sort();
    return normalized;
  }

  Future<List<BusinessCardModel>> _filterPagedByMealCards({
    required List<String> mealCardKeys,
    required int limit,
    required int offset,
    required Future<List<BusinessCardModel>> Function({
      required int batchLimit,
      required int batchOffset,
    })
    fetchBatch,
  }) async {
    final targetCount = offset + limit;
    final batchSize = limit <= 20 ? 60 : limit * 3;
    final matches = <BusinessCardModel>[];
    final seenIds = <String>{};
    var batchOffset = 0;
    var rounds = 0;

    while (matches.length < targetCount && rounds < 8) {
      final batch = await fetchBatch(
        batchLimit: batchSize,
        batchOffset: batchOffset,
      );
      if (batch.isEmpty) break;
      batchOffset += batch.length;
      final matchingIds = await _mealCardProvidersRepository
          .matchBusinessIdsByProviderKeys(
            mealCardKeys,
            candidateBusinessIds: batch.map((item) => item.id).toList(),
          );
      for (final item in batch) {
        if (!matchingIds.contains(item.id)) continue;
        if (seenIds.add(item.id)) {
          matches.add(item);
        }
      }
      if (batch.length < batchSize) break;
      rounds += 1;
    }

    return matches.skip(offset).take(limit).toList(growable: false);
  }

  double _computeTrustScore({
    required double qualityScore,
    required int recentVerifiedCount,
    required double avgRating,
    required bool isOpenNow,
  }) {
    final quality = (qualityScore.clamp(0, 5) / 5).toDouble();
    final verified = (recentVerifiedCount.clamp(0, 5) / 5).toDouble();
    final rating = (avgRating.clamp(0, 5) / 5).toDouble();
    final openBoost = isOpenNow ? 1.0 : 0.0;
    return ((quality * 0.45) +
            (verified * 0.25) +
            (rating * 0.20) +
            (openBoost * 0.10))
        .clamp(0, 1)
        .toDouble();
  }

  bool _isOpenNow(Map<String, dynamic> row) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hm = now.hour * 60 + now.minute;

    String? open;
    String? close;
    switch (weekday) {
      case DateTime.monday:
        open = row['mon_open']?.toString();
        close = row['mon_close']?.toString();
        break;
      case DateTime.tuesday:
        open = row['tue_open']?.toString();
        close = row['tue_close']?.toString();
        break;
      case DateTime.wednesday:
        open = row['wed_open']?.toString();
        close = row['wed_close']?.toString();
        break;
      case DateTime.thursday:
        open = row['thu_open']?.toString();
        close = row['thu_close']?.toString();
        break;
      case DateTime.friday:
        open = row['fri_open']?.toString();
        close = row['fri_close']?.toString();
        break;
      case DateTime.saturday:
        open = row['sat_open']?.toString();
        close = row['sat_close']?.toString();
        break;
      case DateTime.sunday:
        open = row['sun_open']?.toString();
        close = row['sun_close']?.toString();
        break;
    }
    if (open == null || close == null || open.isEmpty || close.isEmpty) {
      return false;
    }

    final o = _parseMinutes(open);
    final c = _parseMinutes(close);
    if (o == null || c == null) return false;
    if (o <= c) return hm >= o && hm <= c;
    return hm >= o || hm <= c;
  }

  int? _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h * 60) + m;
  }
}



