import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_queue_models.dart';

final adminQueueRepositoryProvider = Provider<AdminQueueRepository>((ref) {
  return AdminQueueRepository(ref.watch(supabaseProvider));
});

class AdminQueueRepository {
  AdminQueueRepository(this.client);

  final SupabaseClient client;

  Future<AdminQueuePageResult> listQueue({
    String? type,
    String? status,
    String? city,
    String? query,
    DateTime? from,
    DateTime? to,
    String sortKey = 'created_at',
    bool sortAscending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final dynamic res = await client.rpc(
        'admin_queue_v1',
        params: {
          'p_type': _trimOrNull(type),
          'p_status': _trimOrNull(status),
          'p_city': _trimOrNull(city),
          'p_q': _trimOrNull(query),
          'p_from': from?.toIso8601String(),
          'p_to': to?.toIso8601String(),
          'p_sort_key': sortKey,
          'p_sort_dir': sortAscending ? 'asc' : 'desc',
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      final rows = (res as List?) ?? const [];
      final items = rows
          .whereType<Map>()
          .map((row) => AdminQueueItem.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
      final totalCount = items.isEmpty ? 0 : items.first.totalCount;
      return AdminQueuePageResult(items: items, totalCount: totalCount);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> setAssignment({
    required AdminQueueItemType type,
    required String itemId,
    required bool assignToMe,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_queue_assign_v1',
        params: {
          'p_item_type': type.wireValue,
          'p_item_id': itemId,
          'p_assign_to_me': assignToMe,
        },
        reason: assignToMe ? 'queue_assigned_to_me' : 'queue_unassigned',
        targetType: type.wireValue,
        targetId: itemId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

String? _trimOrNull(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return text;
}
