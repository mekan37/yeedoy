import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_receipt_submission.dart';

final adminReceiptSubmissionsRepositoryProvider =
    Provider<AdminReceiptSubmissionsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminReceiptSubmissionsRepository(client);
});

class AdminReceiptSubmissionsRepository {
  AdminReceiptSubmissionsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminReceiptSubmission>> listSubmissions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('admin_list_receipt_submissions_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => AdminReceiptSubmission.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
