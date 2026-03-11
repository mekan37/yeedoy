import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/business_rbac.dart';
import '../domain/owner_team_models.dart';

final ownerTeamRepositoryProvider = Provider<OwnerTeamRepository>((ref) {
  return OwnerTeamRepository(ref.watch(supabaseProvider));
});

class OwnerTeamRepository {
  OwnerTeamRepository(this.client);

  final SupabaseClient client;

  Future<List<OwnerTeamMember>> listMembers(String businessId) async {
    try {
      final res = await client.rpc(
        'list_team_members_v1',
        params: {'p_business_id': businessId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => OwnerTeamMember.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> inviteOrAssign({
    required String businessId,
    required String email,
    required OwnerTeamRole role,
    required TeamAccessScope scope,
  }) async {
    try {
      final res = await client.rpc(
        'upsert_team_member_v1',
        params: {
          'p_business_id': businessId,
          'p_email': email.trim(),
          'p_role': role.value,
          'p_scope': scope.value,
        },
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res as Map?)?['code'] ?? 'team_upsert_failed');
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> updateMember({
    required String businessId,
    required String membershipId,
    required OwnerTeamRole role,
    required TeamAccessScope scope,
  }) async {
    try {
      final res = await client.rpc(
        'update_team_member_v1',
        params: {
          'p_business_id': businessId,
          'p_membership_id': membershipId,
          'p_role': role.value,
          'p_scope': scope.value,
        },
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res as Map?)?['code'] ?? 'team_update_failed');
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }

  Future<void> revokeMember({
    required String businessId,
    required String membershipId,
  }) async {
    try {
      final res = await client.rpc(
        'revoke_team_member_v1',
        params: {
          'p_business_id': businessId,
          'p_membership_id': membershipId,
        },
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res as Map?)?['code'] ?? 'team_revoke_failed');
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
