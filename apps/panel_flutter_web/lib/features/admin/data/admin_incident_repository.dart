import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/admin_api_client.dart';

class IncidentUpdate {
  const IncidentUpdate({
    required this.id,
    required this.incidentKey,
    required this.title,
    required this.summary,
    required this.actionTaken,
    required this.status,
    required this.visibility,
    required this.createdAt,
  });

  final String id;
  final String incidentKey;
  final String title;
  final String summary;
  final String actionTaken;
  final String status;
  final String visibility;
  final DateTime createdAt;

  factory IncidentUpdate.fromMap(Map<String, dynamic> map) {
    return IncidentUpdate(
      id: (map['id'] ?? '').toString(),
      incidentKey: (map['incident_key'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      actionTaken: (map['action_taken'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      visibility: (map['visibility'] ?? 'public').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

final adminIncidentRepositoryProvider = Provider<AdminIncidentRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return AdminIncidentRepository(client);
});

class AdminIncidentRepository {
  AdminIncidentRepository(this.client);

  final SupabaseClient client;

  Future<List<IncidentUpdate>> listAdmin({int limit = 100}) async {
    try {
      final res = await client.rpc(
        'admin_list_incident_updates_v1',
        params: {'p_limit': limit},
      );
      return (res as List)
          .whereType<Map>()
          .map((e) => IncidentUpdate.fromMap(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> create({
    required String incidentKey,
    required String title,
    required String summary,
    required String actionTaken,
    required String status,
    required String visibility,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_create_incident_update_v1',
        params: {
          'p_incident_key': incidentKey,
          'p_title': title,
          'p_summary': summary,
          'p_action_taken': actionTaken,
          'p_status': status,
          'p_visibility': visibility,
        },
        reason: 'incident_update_created',
        targetType: 'incident_updates',
        targetId: incidentKey,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<IncidentUpdate>> listPublic({int limit = 100}) async {
    try {
      final res = await client.rpc(
        'public_list_incident_updates_v1',
        params: {'p_limit': limit},
      );
      return (res as List)
          .whereType<Map>()
          .map((e) => IncidentUpdate.fromMap(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
