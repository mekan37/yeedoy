import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_search_models.dart';

final adminSearchRepositoryProvider = Provider<AdminSearchRepository>((ref) {
  return AdminSearchRepository(ref.watch(supabaseProvider));
});

class AdminSearchRepository {
  AdminSearchRepository(this.client);

  final SupabaseClient client;

  Future<List<AdminSearchResult>> search({
    required String query,
    int limitPerCategory = 6,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const [];
    }
    try {
      final res = await client.rpc(
        'search_admin_v1',
        params: {
          'p_q': normalized,
          'p_limit': limitPerCategory,
        },
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) => AdminSearchResult.fromMap(row.cast<String, dynamic>()),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception(AppErrorMapper.message(error));
    }
  }
}
