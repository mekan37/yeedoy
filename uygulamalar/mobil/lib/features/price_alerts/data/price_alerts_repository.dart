import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/price_alert_models.dart';

final priceAlertsRepositoryProvider = Provider<PriceAlertsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return PriceAlertsRepository(client);
});

class PriceAlertsRepository {
  PriceAlertsRepository(this.client);
  final SupabaseClient client;

  Future<void> createPriceAlert({
    required String query,
    required int maxPriceCents,
    String? city,
    String? district,
    String? category,
  }) async {
    try {
      final trimmedQuery = query.trim();
      final token = await createOfflineMutationIdempotencyToken(
        action: 'create_price_alert',
        payload: {
          'query': trimmedQuery,
          'max_price_cents': maxPriceCents,
          'city': city,
          'district': district,
          'category': category,
          'currency': 'TRY',
        },
      );
      final params = {
        'p_query': trimmedQuery,
        'p_max_price_cents': maxPriceCents,
        'p_city': city,
        'p_district': district,
        'p_currency': 'TRY',
        'p_category': category,
      };
      dynamic res;
      try {
        res = await client.rpc(
          'create_price_alert_v2',
          params: {
            ...params,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'create_price_alert_v2')) rethrow;
        res = await client.rpc('create_price_alert_v1', params: params);
      }
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<PriceAlert>> listMyAlerts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_my_alerts_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => PriceAlert.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AlertEvent>> listMyAlertEvents({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_my_alert_events_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => AlertEvent.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, Map<String, dynamic>>> fetchBusinessesByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final res = await client
        .from('businesses')
        .select('id,name,city,district')
        .inFilter('id', ids);
    final map = <String, Map<String, dynamic>>{};
    for (final row in (res as List?) ?? const []) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = data;
    }
    return map;
  }

  Future<Map<String, String>> fetchMenuItemNames(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final res = await client.from('menu_items').select('id,name').inFilter('id', ids);
    final map = <String, String>{};
    for (final row in (res as List?) ?? const []) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = (data['name'] ?? '').toString();
    }
    return map;
  }

  Future<Map<String, AlertMeta>> fetchAlertMeta(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final res = await client
        .from('price_alerts')
        .select('id,query,max_price_cents,city,district')
        .inFilter('id', ids);
    final map = <String, AlertMeta>{};
    for (final row in (res as List?) ?? const []) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = AlertMeta.fromMap(data);
    }
    return map;
  }
}

bool _isMissingRpcError(Object error, String rpcName) {
  final text = error.toString().toLowerCase();
  final normalized = rpcName.toLowerCase();
  return text.contains(normalized) &&
      (text.contains('could not find') ||
          text.contains('does not exist') ||
          text.contains('not found') ||
          text.contains('undefined function') ||
          text.contains('pgrst202'));
}
