import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/my_suspended_claim_models.dart';

final mySuspendedClaimRepositoryProvider = Provider<MySuspendedClaimRepository>((ref) {
  return MySuspendedClaimRepository(ref.watch(supabaseProvider));
});

class MySuspendedClaimRepository {
  MySuspendedClaimRepository(this.client);
  final SupabaseClient client;

  Future<List<MySuspendedClaimItem>> listClaims({
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('get_my_suspended_claims_v1', params: {
        'p_status': status,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => MySuspendedClaimItem.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MySuspendedBadge> getBadge() async {
    try {
      final res = await client.rpc('get_my_suspended_claim_badge_v1');
      return MySuspendedBadge.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
