import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_receipt_submission.dart';

final adminReceiptSubmissionsRepositoryProvider =
    Provider<AdminReceiptSubmissionsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminReceiptSubmissionsRepository(client);
});

class AdminReceiptSubmissionsRepository {
  AdminReceiptSubmissionsRepository(this.client);
  final SupabaseClient client;

  Future<AdminReceiptSubmissionSummary?> getSummary({
    String? query,
    String? reviewStatus,
    bool onlyUnmatched = false,
  }) async {
    try {
      final res = await client.rpc(
        'admin_get_receipt_submission_summary_v1',
        params: {
          'p_query': _normalized(query),
          'p_review_status': _normalized(reviewStatus),
          'p_only_unmatched': onlyUnmatched,
        },
      );
      if (res is List && res.isNotEmpty && res.first is Map) {
        return AdminReceiptSubmissionSummary.fromMap(
          (res.first as Map).cast<String, dynamic>(),
        );
      }
      if (res is Map) {
        return AdminReceiptSubmissionSummary.fromMap(
          res.cast<String, dynamic>(),
        );
      }
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminReceiptSubmission>> listSubmissions({
    String? query,
    String? reviewStatus,
    bool onlyUnmatched = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_receipt_submissions_v2',
        params: {
          'p_query': _normalized(query),
          'p_review_status': _normalized(reviewStatus),
          'p_only_unmatched': onlyUnmatched,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                AdminReceiptSubmission.fromMap(row.cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminReceiptSubmissionMatch>> listMatches({
    required String receiptId,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_receipt_submission_matches_v1',
        params: {'p_receipt_id': receiptId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) => AdminReceiptSubmissionMatch.fromMap(
              row.cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<AdminReceiptBatchOpportunity>> listBatchOpportunities({
    int limit = 8,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_receipt_submission_batch_opportunities_v1',
        params: {'p_limit': limit},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) => AdminReceiptBatchOpportunity.fromMap(
              row.cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateReview({
    required String receiptId,
    required String reviewStatus,
    String? reviewNote,
    String? reviewedBy,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_update_receipt_submission_review_v1',
        params: {
          'p_receipt_id': receiptId,
          'p_review_status': reviewStatus,
          'p_review_note': reviewNote,
          'p_reviewed_by': _normalized(reviewedBy),
        },
        reason: 'receipt_submission_review_updated',
        targetType: 'receipt_submissions',
        targetId: receiptId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  String? _normalized(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
