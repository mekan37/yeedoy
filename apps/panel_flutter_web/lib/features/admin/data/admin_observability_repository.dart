import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/admin_edge_maintenance_action.dart';
import '../domain/admin_edge_maintenance_result.dart';
import '../domain/admin_offline_mutation_alert_settings.dart';
import '../domain/admin_observability_models.dart';

final adminObservabilityRepositoryProvider =
    Provider<AdminObservabilityRepository>((ref) {
      return AdminObservabilityRepository(ref.watch(supabaseProvider));
    });

class AdminObservabilityRepository {
  AdminObservabilityRepository(this.client);

  final SupabaseClient client;

  Future<List<AdminOfflineMutationOutcome>> listOfflineMutationOutcomes({
    int hours = 24,
    int limit = 100,
  }) async {
    try {
      final dynamic res = await client.rpc(
        'admin_list_offline_mutation_outcomes_v1',
        params: {'p_hours': hours, 'p_limit': limit},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map(
            (row) => AdminOfflineMutationOutcome.fromMap(
              row.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminOfflineMutationAlertSettings>
  getOfflineMutationAlertSettings() async {
    try {
      final dynamic res = await client.rpc(
        'admin_get_offline_mutation_alert_settings_v1',
      );
      if (res is Map) {
        return AdminOfflineMutationAlertSettings.fromMap(
          res.cast<String, dynamic>(),
        );
      }
      return AdminOfflineMutationAlertSettings.defaults();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminOfflineMutationAlertSettings> saveOfflineMutationAlertSettings(
    AdminOfflineMutationAlertSettings settings,
  ) async {
    try {
      final dynamic res = await client.rpc(
        'admin_set_offline_mutation_alert_settings_v1',
        params: {'p_settings': settings.toMap()},
      );
      if (res is Map) {
        return AdminOfflineMutationAlertSettings.fromMap(
          res.cast<String, dynamic>(),
        );
      }
      return settings;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<AdminEdgeMaintenanceResult> runEdgeMaintenance(
    AdminEdgeMaintenanceAction action, {
    int? limit,
  }) async {
    try {
      final response = await client.functions.invoke(
        action.functionName,
        body: limit == null ? null : <String, Object?>{'limit': limit},
      );
      final data = response.data;
      if (data is! Map) {
        throw Exception('edge_function_failed');
      }
      final map = data.cast<String, dynamic>();
      if (map['ok'] != true) {
        throw Exception((map['error'] ?? 'edge_function_failed').toString());
      }
      return AdminEdgeMaintenanceResult(
        ok: true,
        label: action.functionName,
        summary: _buildMaintenanceSummary(action, map),
        raw: map,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  String _buildMaintenanceSummary(
    AdminEdgeMaintenanceAction action,
    Map<String, dynamic> data,
  ) {
    switch (action) {
      case AdminEdgeMaintenanceAction.pushDispatch:
        final notificationCount = _asInt(data['notification_count']);
        final sentCount = _asInt(data['sent_count']);
        final skippedCount = _asInt(data['skipped_count']);
        return 'Notifications $notificationCount | Sent $sentCount | Skipped $skippedCount';
      case AdminEdgeMaintenanceAction.purgeTempUploads:
        final fetched = _asInt(data['fetched']);
        final processed = _asInt(data['processed']);
        final failed = _asInt(data['failed']);
        final skipped = _asInt(data['skipped']);
        return 'Queue $fetched | Processed $processed | Failed $failed | Skipped $skipped';
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }
}
