import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/security/admin_api_client.dart';
import '../domain/admin_business_submission.dart';

final adminBusinessSubmissionsRepositoryProvider =
    Provider<AdminBusinessSubmissionsRepository>((ref) {
      return AdminBusinessSubmissionsRepository(ref.watch(supabaseProvider));
    });

class AdminBusinessSubmissionsRepository {
  AdminBusinessSubmissionsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminBusinessSubmission>> listSubmissions({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_business_submissions_v1',
        params: {'p_status': status, 'p_limit': limit, 'p_offset': offset},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                AdminBusinessSubmission.fromMap(row.cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approve(String submissionId) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_approve_business_submission_v1',
        params: {'p_submission_id': submissionId},
        reason: 'business_submission_approved',
        targetType: 'business_submissions',
        targetId: submissionId,
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> reject(String submissionId, {String? note}) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_reject_business_submission_v1',
        params: {'p_submission_id': submissionId, 'p_note': note},
        reason: (note ?? '').trim().isEmpty
            ? 'business_submission_rejected'
            : note!.trim(),
        targetType: 'business_submissions',
        targetId: submissionId,
      );
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
