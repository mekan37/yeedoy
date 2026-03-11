import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/smart_feed_models.dart';

final smartFeedRepositoryProvider = Provider<SmartFeedRepository>((ref) {
  return SmartFeedRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider),
  );
});

class SmartFeedRepository {
  SmartFeedRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'smart_feed';
  static const Duration _feedTtl = Duration(seconds: 90);

  Future<SmartFeedPreferences> getPreferences() async {
    return SmartFeedPreferences.empty();
  }

  Future<void> upsertPreferences(SmartFeedPreferences prefs) async {
    // Preferences are currently local-only until a canonical DB table is defined.
    _cache.invalidatePrefix('feed|');
    return;
  }

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  Future<List<SmartFeedEvent>> getSmartFeed({
    required int limit,
    required int offset,
    SmartFeedPreferences? prefs,
    String? weatherHint,
    String? timeLabel,
    String? dayLabel,
    bool force = false,
  }) async {
    final key = stableRequestCacheKey('smart_feed', {
      'limit': limit,
      'offset': offset,
      'city': prefs?.city?.trim(),
      'districts': (prefs?.districts ?? const <String>[]).join(','),
      'categories': (prefs?.categories ?? const <String>[]).join(','),
      'bundles': (prefs?.bundles ?? const <String>[]).join(','),
      'price_max_cents': prefs?.priceMaxCents,
      'weather_hint': weatherHint?.trim(),
      'time_label': timeLabel?.trim(),
      'day_label': dayLabel?.trim(),
    });
    if (!force) {
      final fresh = _cache.getFresh<List<SmartFeedEvent>>(key, ttl: _feedTtl);
      if (fresh != null) return fresh;
    }

    final params = <String, dynamic>{
      'p_limit': limit,
      'p_offset': offset,
      'p_city': prefs?.city,
      'p_districts': prefs?.districts.isNotEmpty == true
          ? prefs!.districts
          : null,
      'p_categories': prefs?.categories.isNotEmpty == true
          ? prefs!.categories
          : null,
      'p_bundles': prefs?.bundles.isNotEmpty == true ? prefs!.bundles : null,
      'p_price_max_cents': prefs?.priceMaxCents,
      'p_weather_hint': weatherHint,
      'p_time_label': timeLabel,
      'p_day_label': dayLabel,
    };
    try {
      final res = await _callFeedRpc(params);
      final rows = (res as List).map(
        (row) => SmartFeedEvent.fromMap((row as Map).cast<String, dynamic>()),
      );
      final items = rows.toList();
      _cache.set(key, items);
      return items;
    } catch (_) {
      final stale = _cache.getStale<List<SmartFeedEvent>>(key);
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<dynamic> _callFeedRpc(Map<String, dynamic> params) async {
    try {
      return await client.rpc('get_smart_feed_v2', params: params);
    } catch (_) {
      return await client.rpc('get_smart_feed_v1', params: params);
    }
  }
}
