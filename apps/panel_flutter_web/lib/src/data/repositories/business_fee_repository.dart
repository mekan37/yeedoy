import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../features/business/domain/business_fee_summary.dart';

final businessFeeRepositoryProvider = Provider<BusinessFeeRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BusinessFeeRepository(client);
});

class BusinessFeeRepository {
  BusinessFeeRepository(this.client);
  final SupabaseClient client;

  Future<BusinessFeeSummary> getFeeSummary(String businessId) async {
    try {
      final res = await client.rpc('get_business_fee_summary_v1', params: {
        'p_business_id': businessId,
      });
      return BusinessFeeSummary.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, dynamic>> voteFee({
    required String businessId,
    required String field,
    required bool value,
    String? note,
  }) async {
    try {
      final res = await client.rpc('vote_business_fee_v1', params: {
        'p_business_id': businessId,
        'p_field': field,
        'p_value': value,
        'p_note': note,
      });
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
