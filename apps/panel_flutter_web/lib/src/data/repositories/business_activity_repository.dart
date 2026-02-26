import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../features/business/domain/business_activity.dart';

final businessActivityRepositoryProvider = Provider<BusinessActivityRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BusinessActivityRepository(client);
});

class BusinessActivityRepository {
  BusinessActivityRepository(this.client);
  final SupabaseClient client;

  Future<List<BusinessActivityItem>> listBusinessActivity({
    required String businessId,
    int limit = 10,
  }) async {
    try {
      final res = await client.rpc('get_business_activity_v1', params: {
        'p_business_id': businessId,
        'p_limit': limit,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => BusinessActivityItem.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
