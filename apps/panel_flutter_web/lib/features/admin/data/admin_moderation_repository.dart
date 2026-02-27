import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_moderation_models.dart';

final adminModerationRepositoryProvider = Provider<AdminModerationRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminModerationRepository(client);
});

class AdminModerationRepository {
  AdminModerationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminAppealItem>> listAppeals({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _client.rpc(
        'admin_list_moderation_appeals_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      if (result is! List) return const [];
      return result
          .whereType<Map>()
          .map((row) => AdminAppealItem.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<List<ModerationDecisionTemplate>> listTemplates({
    String? scope,
  }) async {
    try {
      final result = await _client.rpc(
        'get_moderation_templates_v1',
        params: {'p_scope': (scope ?? '').trim().isEmpty ? null : scope},
      );
      if (result is! List) return const [];
      return result
          .whereType<Map>()
          .map(
            (row) =>
                ModerationDecisionTemplate.fromMap(row.cast<String, dynamic>()),
          )
          .toList();
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> decideAppeal({
    required String appealId,
    required String decision,
    required String note,
  }) async {
    try {
      await invokeAdminRpcWrite(
        _client,
        rpcName: 'admin_decide_moderation_appeal_v1',
        params: {
          'p_appeal_id': appealId,
          'p_decision': decision,
          'p_note': note.trim().isEmpty ? null : note.trim(),
        },
        reason: 'appeal_$decision',
        targetType: 'moderation_appeals',
        targetId: appealId,
      );
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
