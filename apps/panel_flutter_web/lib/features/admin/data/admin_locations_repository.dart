import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';

final adminLocationsRepositoryProvider = Provider<AdminLocationsRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminLocationsRepository(client);
});

class AdminLocationsRepository {
  AdminLocationsRepository(this.client);
  final SupabaseClient client;

  Future<int> previewReplace({
    required String table,
    required String column,
    required String from,
    required bool caseInsensitive,
  }) async {
    try {
      final res = await client.rpc(
        'admin_bulk_replace_preview_v1',
        params: {
          'p_table': table,
          'p_column': column,
          'p_from': from,
          'p_case_insensitive': caseInsensitive,
        },
      );
      return _asCount(res);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> applyReplace({
    required String table,
    required String column,
    required String from,
    required String to,
    required bool caseInsensitive,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_bulk_replace_text_v1',
        params: {
          'p_table': table,
          'p_column': column,
          'p_from': from,
          'p_to': to,
          'p_case_insensitive': caseInsensitive,
        },
        reason: 'bulk_location_replace',
        targetType: table,
        targetId: column,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

int _asCount(dynamic res) {
  if (res is int) return res;
  if (res is num) return res.toInt();
  if (res is Map) {
    final v = res['count'] ?? res['affected'] ?? res['affected_count'];
    if (v is int) return v;
    if (v is num) return v.toInt();
  }
  if (res is List && res.isNotEmpty && res.first is Map) {
    final v =
        (res.first as Map)['count'] ??
        (res.first as Map)['affected'] ??
        (res.first as Map)['affected_count'];
    if (v is int) return v;
    if (v is num) return v.toInt();
  }
  return int.tryParse(res?.toString() ?? '') ?? 0;
}
