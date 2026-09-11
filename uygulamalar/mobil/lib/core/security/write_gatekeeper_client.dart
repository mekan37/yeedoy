import 'package:supabase_flutter/supabase_flutter.dart';

import '../monitoring/request_trace.dart';
import '../storage/offline_submission_queue.dart' show isLikelyOfflineError;

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
  } on FunctionException catch (e) {
    // Yalnızca fonksiyon deploy edilmemişse (404) sessizce geç. 401/403/429
    // gibi sunucunun bilinçli reddettiği durumlar asla sessizce
    // yutulmamalı — aksi halde write-gatekeeper'ın yetki/itibar reddi,
    // istemci tarafında "başarılı" gibi görünür (menu_photo_delete,
    // owner_price_suggestion_approve/reject, review_vote_* etkilenir).
    if (e.status == 404) return;
    rethrow;
  } catch (e) {
    // Gerçek ağ hatası (SocketException, timeout vb.) — fonksiyona hiç
    // ulaşılamadı. Gatekeeper best-effort olduğu için geç.
    if (isLikelyOfflineError(e)) return;
    rethrow;
  }
}
