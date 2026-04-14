import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminRepository(client);
});

class AdminRepository {
  AdminRepository(this.client);
  final SupabaseClient client;

  Future<bool> isAdmin() async {
    try {
      final res = await client.rpc('is_admin');
      if (res is bool) return res;
      if (res is Map && res['is_admin'] is bool) return res['is_admin'] as bool;
      if (res is List && res.isNotEmpty && res.first is Map) {
        final m = res.first as Map;
        final v = m['is_admin'];
        if (v is bool) return v;
      }
      return false;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminQueueCounts> fetchQueueCounts() async {
    try {
      final res = await client.rpc('admin_get_queues_counts_v1');
      if (res is Map) {
        return AdminQueueCounts.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return AdminQueueCounts.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const AdminQueueCounts(
        reportsOpen: 0,
        claimsPending: 0,
        suggestionsPending: 0,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminSlaMetrics> fetchSlaMetrics() async {
    try {
      final res = await client.rpc('admin_sla_metrics_v1');
      if (res is Map) {
        return AdminSlaMetrics.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return AdminSlaMetrics.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const AdminSlaMetrics(
        reportsAvgMinutesToAssign: 0,
        reportsAvgMinutesToClose: 0,
        claimsAvgMinutesToAssign: 0,
        claimsAvgMinutesToDecide: 0,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
