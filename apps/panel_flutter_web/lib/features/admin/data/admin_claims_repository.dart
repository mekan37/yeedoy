import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminClaimsRepositoryProvider = Provider<AdminClaimsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminClaimsRepository(client);
});

class AdminClaimsRepository {
  AdminClaimsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminOwnerClaimItem>> listClaims({
    String? status,
    String? assigned,
    bool? slaOnly,
    int limit = 50,
    int offset = 0,
    String? query,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_owner_claims_v3',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_assigned': (assigned ?? '').trim().isEmpty ? null : assigned,
          'p_sla_only': slaOnly == true ? true : null,
          'p_limit': limit,
          'p_offset': offset,
          'p_q': (query ?? '').trim().isEmpty ? null : query,
        },
      );
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => AdminOwnerClaimItem.fromMap(m.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> assignClaim(String claimId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_assign_owner_claim_v1',
        params: {'p_claim_id': claimId},
        reason: 'owner_claim_assigned',
        targetType: 'owner_claims',
        targetId: claimId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> unassignClaim(String claimId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_unassign_owner_claim_v1',
        params: {'p_claim_id': claimId},
        reason: 'owner_claim_unassigned',
        targetType: 'owner_claims',
        targetId: claimId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<bool> applyAutoModerationRules(String claimId) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'apply_auto_moderation_rules_v1',
        params: {'p_target': 'claim', 'p_id': claimId},
        reason: 'owner_claim_auto_moderation_applied',
        targetType: 'owner_claims',
        targetId: claimId,
      );
      return _appliedFromResult(res);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportCsv({String? status, String? query}) async {
    try {
      final res = await client.rpc(
        'admin_export_owner_claims_csv_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_q': (query ?? '').trim().isEmpty ? null : query,
        },
      );
      return res?.toString() ?? '';
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> decideClaim({
    required String claimId,
    required String decision,
    String? note,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_decide_owner_claim_v1',
        params: {
          'p_claim_id': claimId,
          'p_decision': decision,
          'p_note': (note ?? '').trim(),
        },
        reason: (note ?? '').trim().isEmpty
            ? 'owner_claim_decided'
            : note!.trim(),
        targetType: 'owner_claims',
        targetId: claimId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> bulkDecideClaims({
    required List<String> claimIds,
    required String decision,
    String? note,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_bulk_decide_owner_claims_v1',
        params: {
          'p_claim_ids': claimIds,
          'p_decision': decision,
          'p_note': (note ?? '').trim(),
        },
        reason: (note ?? '').trim().isEmpty
            ? 'owner_claims_bulk_decided'
            : note!.trim(),
        targetType: 'owner_claims',
        targetId: claimIds.length == 1 ? claimIds.first : 'bulk',
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

bool _appliedFromResult(dynamic res) {
  if (res is Map) {
    final v = res['applied'];
    return v == true || v == 1 || v == 'true';
  }
  if (res is List && res.isNotEmpty && res.first is Map) {
    final v = (res.first as Map)['applied'];
    return v == true || v == 1 || v == 'true';
  }
  if (res is bool) return res;
  return false;
}
