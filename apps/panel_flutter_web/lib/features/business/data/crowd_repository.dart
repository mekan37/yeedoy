import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/crowd_models.dart';

final crowdRepositoryProvider = Provider<CrowdRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return CrowdRepository(client);
});

class CrowdRepository {
  CrowdRepository(this.client);
  final SupabaseClient client;

  Future<BusinessCrowdStatus> getBusinessCrowd(String businessId) async {
    try {
      final res = await client.rpc('get_business_crowd_v1', params: {
        'p_business_id': businessId,
      });
      return BusinessCrowdStatus.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitPresence({
    required String businessId,
    required String crowd,
  }) async {
    try {
      await client.rpc('submit_presence_v1', params: {
        'p_business_id': businessId,
        'p_crowd': crowd,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
