import 'package:supabase_flutter/supabase_flutter.dart';

import '../monitoring/request_trace.dart';

Future<Map<String, dynamic>> invokeAdminApi(
  SupabaseClient client, {
  required String action,
  required String reason,
  required Map<String, Object?> payload,
  String? requestId,
}) async {
  final trimmedReason = reason.trim();
  if (trimmedReason.isEmpty) {
    throw Exception('reason_required');
  }
  final reqId = requestId ?? createRequestId(prefix: 'admin');

  final response = await client.functions.invoke(
    'admin-api',
    headers: traceHeaders(reqId),
    body: {
      'action': action,
      'reason': trimmedReason,
      'payload': withRequestTrace(payload, requestId: reqId),
      'request_id': reqId,
    },
  );
  final data = response.data;
  if (data is Map) {
    final map = data.cast<String, dynamic>();
    if (map['ok'] == true) return map;
    throw Exception((map['error'] ?? 'admin_api_failed').toString());
  }
  throw Exception('admin_api_failed');
}

Future<dynamic> invokeAdminRpcWrite(
  SupabaseClient client, {
  required String rpcName,
  required Map<String, Object?> params,
  required String reason,
  String? targetType,
  String? targetId,
  String? requestId,
}) async {
  final res = await invokeAdminApi(
    client,
    action: 'rpc_write',
    reason: reason,
    requestId: requestId,
    payload: {
      'rpc': rpcName,
      'params': params,
      'target_type': targetType,
      'target_id': targetId,
    },
  );
  return res['data'];
}
