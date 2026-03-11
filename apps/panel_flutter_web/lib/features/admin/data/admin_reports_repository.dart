import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/memory_ttl_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminReportsRepositoryProvider = Provider<AdminReportsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AdminReportsRepository(client);
});

class AdminReportsRepository {
  AdminReportsRepository(this.client);
  final SupabaseClient client;
  static const _cachePrefix = 'admin_reports:';
  static const _ttl = Duration(seconds: 30);

  Future<List<AdminReportItem>> listReports({
    String? status,
    String? assigned,
    bool? slaOnly,
    int limit = 50,
    int offset = 0,
    String? query,
  }) async {
    try {
      final key =
          '$_cachePrefix$limit:$offset:${(status ?? '').trim()}:${(assigned ?? '').trim()}:${slaOnly == true}:${(query ?? '').trim()}';
      return MemoryTtlCache.instance.getOrLoad<List<AdminReportItem>>(
        key: key,
        ttl: _ttl,
        loader: () async {
          final res = await client.rpc(
            'admin_list_reports_v5',
            params: {
              'p_status': (status ?? '').trim().isEmpty ? null : status,
              'p_assigned': (assigned ?? '').trim().isEmpty ? null : assigned,
              'p_sla_only': slaOnly == true ? true : null,
              'p_limit': limit,
              'p_offset': offset,
              'p_q': (query ?? '').trim().isEmpty ? null : query,
            },
          );
          if (res is List) {
            return res
                .whereType<Map>()
                .map((m) => AdminReportItem.fromMap(m.cast<String, dynamic>()))
                .toList();
          }
          return const <AdminReportItem>[];
        },
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> assignReport(String reportId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_assign_report_v1',
        params: {'p_report_id': reportId},
        reason: 'report_assigned',
        targetType: 'reports',
        targetId: reportId,
      );
      _invalidateReportCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> unassignReport(String reportId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_unassign_report_v1',
        params: {'p_report_id': reportId},
        reason: 'report_unassigned',
        targetType: 'reports',
        targetId: reportId,
      );
      _invalidateReportCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<bool> applyAutoModerationRules(String reportId) async {
    try {
      final res = await invokeAdminRpcWrite(
        client,
        rpcName: 'apply_auto_moderation_rules_v1',
        params: {'p_target': 'report', 'p_id': reportId},
        reason: 'report_auto_moderation_applied',
        targetType: 'reports',
        targetId: reportId,
      );
      _invalidateReportCaches();
      return _appliedFromResult(res);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportCsv({String? status, String? query}) async {
    try {
      final res = await client.rpc(
        'admin_export_reports_csv_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_q': (query ?? '').trim().isEmpty ? null : query,
        },
      );
      return res?.toString() ?? '';
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> updateReport({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_update_report_v2',
        params: {
          'p_report_id': reportId,
          'p_status': status,
          'p_admin_note': (adminNote ?? '').trim().isEmpty
              ? null
              : adminNote!.trim(),
        },
        reason: (adminNote ?? '').trim().isEmpty
            ? 'report_status_updated'
            : adminNote!.trim(),
        targetType: 'reports',
        targetId: reportId,
      );
      _invalidateReportCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> bulkUpdateStatus({
    required List<String> reportIds,
    required String status,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_bulk_update_reports_status_v2',
        params: {
          'p_report_ids': reportIds,
          'p_status': status,
          'p_admin_note': (adminNote ?? '').trim().isNotEmpty
              ? adminNote!.trim()
              : null,
        },
        reason: (adminNote ?? '').trim().isNotEmpty
            ? adminNote!.trim()
            : 'reports_bulk_status_updated',
        targetType: 'reports',
        targetId: reportIds.length == 1 ? reportIds.first : 'bulk',
      );
      _invalidateReportCaches();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  void _invalidateReportCaches() {
    MemoryTtlCache.instance.invalidatePrefix(_cachePrefix);
  }
}

bool _appliedFromResult(dynamic res) {
  if (res is Map) {
    final v = res['applied'];
    return v == true || v == 1 || v == 'true';
  }
  if (res is List && res.isNotEmpty && res.first is Map) {
    final v = (res.first as Map)['applied'];
    return v == true || v == 1 || v == 'true';
  }
  if (res is bool) return res;
  return false;
}
