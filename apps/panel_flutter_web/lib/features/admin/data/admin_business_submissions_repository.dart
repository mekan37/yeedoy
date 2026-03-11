import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/memory_ttl_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_business_submission.dart';

final adminBusinessSubmissionsRepositoryProvider =
    Provider<AdminBusinessSubmissionsRepository>((ref) {
      return AdminBusinessSubmissionsRepository(ref.watch(supabaseProvider));
    });

class AdminBusinessSubmissionsRepository {
  AdminBusinessSubmissionsRepository(this.client);
  final SupabaseClient client;
  static const _cachePrefix = 'admin_business_submissions:';
  static const _ttl = Duration(seconds: 30);

  Future<List<AdminBusinessSubmission>> listSubmissions({
    String? status,
    int limit = 50,
    int offset = 0,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortKey = 'created_at',
    bool sortAscending = false,
  }) async {
    try {
      final key =
          '$_cachePrefix${(status ?? '').trim()}:$limit:$offset:${(query ?? '').trim()}:${dateFrom?.toIso8601String() ?? ''}:${dateTo?.toIso8601String() ?? ''}:$sortKey:$sortAscending';
      return MemoryTtlCache.instance.getOrLoad<List<AdminBusinessSubmission>>(
        key: key,
        ttl: _ttl,
        loader: () async {
          final res = await client.rpc(
            'admin_list_business_submissions_v2',
            params: {
              'p_status': status,
              'p_limit': limit,
              'p_offset': offset,
              'p_q': (query ?? '').trim().isEmpty ? null : query!.trim(),
              'p_date_from': dateFrom?.toIso8601String(),
              'p_date_to': dateTo?.toIso8601String(),
              'p_sort_key': sortKey,
              'p_sort_ascending': sortAscending,
            },
          );
          final rows = (res as List?) ?? const [];
          return rows
              .whereType<Map>()
              .map(
                (row) => AdminBusinessSubmission.fromMap(
                  row.cast<String, dynamic>(),
                ),
              )
              .toList();
        },
      );
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
      if (res is Map && res['ok'] == true) {
        _invalidateCache();
        return;
      }
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
      if (res is Map && res['ok'] == true) {
        _invalidateCache();
        return;
      }
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  void _invalidateCache() {
    MemoryTtlCache.instance.invalidatePrefix(_cachePrefix);
  }
}
