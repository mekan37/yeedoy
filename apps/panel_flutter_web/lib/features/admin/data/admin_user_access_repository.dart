import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/business_rbac.dart';
import '../domain/admin_user_access_models.dart';

final adminUserAccessRepositoryProvider = Provider<AdminUserAccessRepository>((ref) {
  return AdminUserAccessRepository(ref.watch(supabaseProvider));
});

class AdminUserAccessRepository {
  AdminUserAccessRepository(this.client);

  final SupabaseClient client;

  Future<List<AdminUserBusinessAccess>> listBusinessAccess({
    required String userId,
    OwnerTeamRole? roleOverride,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_user_business_access_v1',
        params: {
          'p_user_id': userId,
          'p_role_override': roleOverride?.value,
          'p_limit': 100,
          'p_offset': 0,
        },
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) => AdminUserBusinessAccess.fromMap(
              row.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> logImpersonation({
    required String userId,
    required String action,
    OwnerTeamRole? roleOverride,
  }) async {
    try {
      final res = await client.rpc(
        'admin_log_impersonation_v1',
        params: {
          'p_target_user_id': userId,
          'p_action': action,
          'p_role_override': roleOverride?.value,
        },
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res as Map?)?['code'] ?? 'impersonation_log_failed');
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
