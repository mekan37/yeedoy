import 'package:supabase_flutter/supabase_flutter.dart';

import '../monitoring/request_trace.dart';

Future<void> invokeWriteGatekeeper(
  SupabaseClient client, {
  required String action,
  required Map<String, Object?> payload,
  String? requestId,
}) async {
  final reqId = requestId ?? createRequestId(prefix: 'wg');
  try {
    final response = await client.functions.invoke(
      'write-gatekeeper',
      headers: traceHeaders(reqId),
      body: {
        'action': action,
        'payload': withRequestTrace(payload, requestId: reqId),
        'request_id': reqId,
      },
    );
    final data = response.data;
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      if (map['ok'] == true) return;
      throw Exception((map['error'] ?? 'write_gatekeeper_failed').toString());
    }
    throw Exception('write_gatekeeper_failed');
  } catch (e) {
    final raw = e.toString();
    // Edge function not deployed (404) or unreachable → pass through.
    // Gatekeeper is best-effort; missing function must not block writes.
    if (raw.contains('404') || raw.contains('FunctionException')) {
      return;
    }
    rethrow;
  }
}
