import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../domain/admin_audit_models.dart';

final adminAuditRepositoryProvider = Provider<AdminAuditRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminAuditRepository(client);
});

class AdminAuditRepository {
  AdminAuditRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminAuditLogItem>> fetchLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
    String? targetTypeFilter,
    String? actorFilter,
    String? targetId,
  }) async {
    try {
      final af = (actionFilter ?? '').trim();
      final tf = (targetTypeFilter ?? '').trim();
      final actor = (actorFilter ?? '').trim();
      final tid = (targetId ?? '').trim();

      final dynamic rpcRes = await client.rpc(
        'list_audit_timeline_v1',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          'p_action': af.isEmpty ? null : af,
          'p_target_type': tf.isEmpty ? null : tf,
          'p_target_id': tid.isEmpty ? null : tid,
          'p_actor_id': actor.isEmpty ? null : actor,
        },
      );

      final List<dynamic> res = rpcRes is List ? rpcRes : <dynamic>[];
      return res
          .whereType<Map>()
          .map((m) => AdminAuditLogItem.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
