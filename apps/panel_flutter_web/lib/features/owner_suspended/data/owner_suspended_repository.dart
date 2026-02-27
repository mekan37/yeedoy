import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_suspended_models.dart';

final ownerSuspendedRepositoryProvider = Provider<OwnerSuspendedRepository>((ref) {
  return OwnerSuspendedRepository(ref.watch(supabaseProvider));
});

class OwnerSuspendedRepository {
  OwnerSuspendedRepository(this.client);
  final SupabaseClient client;

  Future<List<OwnerSuspendedClaimItem>> listClaims({
    required String businessId,
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('owner_list_suspended_claims_v1', params: {
        'p_business_id': businessId,
        'p_status': status,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => OwnerSuspendedClaimItem.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> approve(String claimId) async {
    try {
      final res = await client.rpc('owner_approve_suspended_claim_v1', params: {
        'p_claim_id': claimId,
      });
      return (res is Map ? res['verify_code'] : res).toString();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> fulfill({required String claimId, required String code}) async {
    try {
      await client.rpc('owner_fulfill_suspended_claim_v1', params: {
        'p_claim_id': claimId,
        'p_code': code,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
