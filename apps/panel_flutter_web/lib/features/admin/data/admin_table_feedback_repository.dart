import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_table_feedback_models.dart';

final adminTableFeedbackRepositoryProvider = Provider<AdminTableFeedbackRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminTableFeedbackRepository(client);
});

class AdminTableFeedbackRepository {
  AdminTableFeedbackRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminTableFeedbackItem>> listFeedback({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('admin_list_table_feedback_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => AdminTableFeedbackItem.fromMap(m.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
