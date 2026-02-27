import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_risk_models.dart';

final adminRiskRepositoryProvider = Provider<AdminRiskRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminRiskRepository(client);
});

class AdminRiskRepository {
  AdminRiskRepository(this.client);

  final SupabaseClient client;

  Future<List<AdminRiskQueueItem>> listRiskyUsers({
    int limit = 50,
    int offset = 0,
    int minScore = 20,
  }) async {
    try {
      final dynamic res = await client.rpc(
        'admin_list_risky_users_v1',
        params: {'p_limit': limit, 'p_offset': offset, 'p_min_score': minScore},
      );
      final List<dynamic> rows = res is List ? res : <dynamic>[];
      return rows
          .whereType<Map>()
          .map((m) => AdminRiskQueueItem.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> applyAction({
    required String userId,
    required String action,
    required int minutes,
    required String reason,
  }) async {
    try {
      await invokeAdminApi(
        client,
        action: 'apply_user_safety_action',
        reason: reason,
        payload: {
          'user_id': userId,
          'safety_action': action,
          'minutes': minutes,
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
