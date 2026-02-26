import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/smart_feed_models.dart';

final smartFeedRepositoryProvider = Provider<SmartFeedRepository>((ref) {
  return SmartFeedRepository(ref.watch(supabaseProvider));
});

class SmartFeedRepository {
  SmartFeedRepository(this.client);
  final SupabaseClient client;

  Future<SmartFeedPreferences> getPreferences() async {
    return SmartFeedPreferences.empty();
  }

  Future<void> upsertPreferences(SmartFeedPreferences prefs) async {
    // Preferences are currently local-only until a canonical DB table is defined.
    return;
  }

  Future<List<SmartFeedEvent>> getSmartFeed({
    required int limit,
    required int offset,
    SmartFeedPreferences? prefs,
    String? weatherHint,
    String? timeLabel,
    String? dayLabel,
  }) async {
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
    final res = await _callFeedRpc(params);
    final rows = (res as List).map(
      (row) => SmartFeedEvent.fromMap((row as Map).cast<String, dynamic>()),
    );
    return rows.toList();
  }

  Future<dynamic> _callFeedRpc(Map<String, dynamic> params) async {
    try {
      return await client.rpc('get_smart_feed_v2', params: params);
    } catch (_) {
      return await client.rpc('get_smart_feed_v1', params: params);
    }
  }
}
