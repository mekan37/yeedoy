import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminSuspendedClaimsRepositoryProvider =
    Provider<AdminSuspendedClaimsRepository>((ref) {
      return AdminSuspendedClaimsRepository(ref.watch(supabaseProvider));
    });

class AdminSuspendedClaimsRepository {
  AdminSuspendedClaimsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminSuspendedClaimItem>> listClaims({
    required String status,
    required bool slaOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_suspended_claims_v1',
        params: {
          'p_status': status,
          'p_limit': limit,
          'p_offset': offset,
          'p_sla_only': slaOnly,
        },
      );
      return (res as List)
          .map(
            (row) => AdminSuspendedClaimItem.fromMap(
              (row as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approve(String claimId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_approve_suspended_claim_v1',
        params: {'p_claim_id': claimId},
        reason: 'suspended_claim_approved',
        targetType: 'suspended_meal_claims',
        targetId: claimId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> reject({required String claimId, required String note}) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_reject_suspended_claim_v1',
        params: {'p_claim_id': claimId, 'p_note': note.trim()},
        reason: note.trim().isEmpty ? 'suspended_claim_rejected' : note.trim(),
        targetType: 'suspended_meal_claims',
        targetId: claimId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportCsv({
    required String status,
    required bool slaOnly,
  }) async {
    try {
      final res = await client.rpc(
        'admin_export_suspended_claims_csv_v1',
        params: {'p_status': status, 'p_sla_only': slaOnly},
      );
      return (res ?? '').toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
