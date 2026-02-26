import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/dev_overrides.dart';
import '../network/supabase_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  final overrides = ref.watch(devOverridesProvider);
  return AnalyticsRepository(client, devUserId: overrides.testUserId);
});

class AnalyticsRepository {
  AnalyticsRepository(this.client, {this.devUserId});
  final SupabaseClient client;
  final String? devUserId;

  Future<bool> logEvent({
    required String eventName,
    String? businessId,
    String? menuId,
    String? source,
    String? clientId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final userId = (devUserId ?? '').trim().isNotEmpty
          ? devUserId
          : client.auth.currentUser?.id;
      final nextMeta = <String, dynamic>{};
      if (meta != null) nextMeta.addAll(meta);
      if (userId != null && userId.isNotEmpty) {
        nextMeta.putIfAbsent('user_id', () => userId);
      }
      if (businessId != null && businessId.isNotEmpty) {
        nextMeta.putIfAbsent('business_id', () => businessId);
      }
      if (menuId != null && menuId.isNotEmpty) {
        nextMeta.putIfAbsent('menu_id', () => menuId);
      }
      final res = await client.rpc(
        'log_event_v1',
        params: {
          'p_event_name': eventName,
          'p_business_id': businessId,
          'p_menu_id': menuId,
          'p_source': source,
          'p_client_id': clientId,
          'p_meta': nextMeta,
        },
      );
      if (res is Map && res['ok'] == true) return true;
      if (res is List && res.isNotEmpty && res.first is Map) {
        final m = res.first as Map;
        return m['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
