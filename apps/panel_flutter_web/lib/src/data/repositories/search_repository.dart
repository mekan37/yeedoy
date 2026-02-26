import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/ttl_memory_cache.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/perf/perf_slo.dart';
import '../../../core/privacy/pii_minimizer.dart';
import '../../../core/search/query_normalizer.dart';
import '../../../features/discovery/domain/business_card.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  final telemetry = ref.watch(appTelemetryProvider);
  return SearchRepository(client, telemetry);
});

class SearchRepository {
  SearchRepository(this.client, this._telemetry);
  final SupabaseClient client;
  final AppTelemetry _telemetry;
  static final TtlMemoryCache _cache = TtlMemoryCache();
  static const Duration _searchTtl = Duration(seconds: 45);

  String _key(String method, Map<String, Object?> values) {
    final ordered = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final payload = ordered
        .map((entry) => '${entry.key}=${entry.value ?? ''}')
        .join('&');
    return '$method|$payload';
  }

  Future<List<BusinessCardModel>> searchBusinesses({
    required String query,
    String? city,
    String? district,
    int limit = 50,
    int offset = 0,
  }) async {
    final watch = Stopwatch()..start();
    final cacheKey = _key('search_businesses', {
      'query': query.trim(),
      'city': city?.trim(),
      'district': district?.trim(),
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

    final normalized = normalizeSearchQuery(query);
    final trigramRes = await client.rpc(
      'search_businesses_v1',
      params: {
        'p_query': normalized,
        'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
        'p_district': (district ?? '').trim().isEmpty ? null : district!.trim(),
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    final trigramRows = (trigramRes as List)
        .map((e) => BusinessCardModel.fromMap(e))
        .toList();
    final prefixRows = await _searchBusinessesPrefix(
      normalizedQuery: normalized,
      city: city,
      district: district,
      limit: limit,
      offset: offset,
    );
    final rows = _mergeSearchRows(
      prefixRows: prefixRows,
      trigramRows: trigramRows,
      limit: limit,
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

  Future<List<BusinessCardModel>> searchNearby({
    required double userLat,
    required double userLng,
    double radiusKm = 5,
    String? city,
    String? district,
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final watch = Stopwatch()..start();
    final roundedLat = roundCoordinate(userLat, decimals: 3);
    final roundedLng = roundCoordinate(userLng, decimals: 3);
    final cacheKey = _key('search_nearby', {
      'lat': roundedLat.toStringAsFixed(3),
      'lng': roundedLng.toStringAsFixed(3),
      'radius': radiusKm.toStringAsFixed(1),
      'city': city?.trim(),
      'district': district?.trim(),
      'query': query?.trim(),
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

    final normalized = normalizeSearchQuery(query ?? '');
    final res = await client.rpc(
      'search_nearby_businesses_v3',
      params: {
        'p_user_lat': roundedLat,
        'p_user_lng': roundedLng,
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
        'p_city': (city ?? '').trim().isEmpty ? null : city!.trim(),
        'p_district': (district ?? '').trim().isEmpty ? null : district!.trim(),
        'p_query': normalized.isEmpty ? null : normalized,
      },
    );

    final rows = (res as List)
        .map((e) => BusinessCardModel.fromMap(e))
        .toList();
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

  Future<List<BusinessCardModel>> _searchBusinessesPrefix({
    required String normalizedQuery,
    String? city,
    String? district,
    required int limit,
    required int offset,
  }) async {
    if (normalizedQuery.isEmpty) return const [];
    var q = client
        .from('businesses_with_stats')
        .select(
          'id,name,category,city,district,address,lat,lng,avg_rating,quality_score,recent_price_verified_count',
        )
        .ilike('name', '$normalizedQuery%');
    if ((city ?? '').trim().isNotEmpty) {
      q = q.eq('city', city!.trim());
    }
    if ((district ?? '').trim().isNotEmpty) {
      q = q.eq('district', district!.trim());
    }
    final res = await q.range(offset, offset + limit - 1);
    return (res as List).map((e) => BusinessCardModel.fromMap(e)).toList();
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
    return map.values.take(limit).toList();
  }

  Future<List<BusinessCardModel>> enrichBusinessCards(
    List<BusinessCardModel> cards,
  ) async {
    if (cards.isEmpty) return cards;
    final ids = cards.map((e) => e.id).toList();

    final ratings = <String, double>{};
    final qualityScores = <String, double>{};
    final medianPrice = <String, int>{};
    final openNow = <String, bool>{};
    final recentVerified = <String, int>{};

    try {
      final rows = await client
          .from('businesses_with_stats')
          .select('id,avg_rating,quality_score')
          .inFilter('id', ids);
      for (final row in (rows as List)) {
        final m = (row as Map<String, dynamic>);
        ratings[m['id'].toString()] = ((m['avg_rating'] as num?) ?? 0)
            .toDouble();
        qualityScores[m['id'].toString()] = ((m['quality_score'] as num?) ?? 0)
            .toDouble();
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('business_price_index_v1')
          .select('business_id,median_price_cents')
          .inFilter('business_id', ids);
      for (final row in (rows as List)) {
        final m = (row as Map<String, dynamic>);
        medianPrice[m['business_id'].toString()] =
            ((m['median_price_cents'] as num?) ?? 0).toInt();
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
        final m = (row as Map<String, dynamic>);
        openNow[m['business_id'].toString()] = _isOpenNow(m);
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
        final m = (row as Map<String, dynamic>);
        final bid = m['business_id'].toString();
        recentVerified[bid] = (recentVerified[bid] ?? 0) + 1;
      }
    } catch (_) {}

    return cards.map((c) {
      final rating = ratings[c.id] ?? c.avgRating ?? 0;
      final quality = qualityScores[c.id] ?? c.qualityScore ?? 0;
      final verified = recentVerified[c.id] ?? c.recentPriceVerifiedCount ?? 0;
      final isOpen = openNow[c.id] ?? c.isOpenNow ?? false;
      final trustScore = _computeTrustScore(
        qualityScore: quality,
        recentVerifiedCount: verified,
        avgRating: rating,
        isOpenNow: isOpen,
      );
      return c.copyWith(
        avgRating: rating,
        qualityScore: quality,
        trustScore: trustScore,
        medianPriceCents: medianPrice[c.id],
        isOpenNow: isOpen,
        recentPriceVerifiedCount: verified,
      );
    }).toList();
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
