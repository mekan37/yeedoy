import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/offline_submission_queue.dart' show isLikelyOfflineError;

Future<void> enforceEdgeRateLimit(
  SupabaseClient client, {
  required String action,
  String? scope,
}) async {
  final payload = <String, dynamic>{'action': action};
  if ((scope ?? '').trim().isNotEmpty) {
    payload['scope'] = scope!.trim();
  }

  try {
    final response = await client.functions.invoke(
      'anti-spam-guard',
      body: payload,
    );
    final data = response.data;
    if (data is Map) {
      final map = data.cast<String, dynamic>();
      if (map['ok'] == true) return;
      throw Exception((map['error'] ?? 'rate_limited').toString());
    }
    throw Exception('rate_limited');
  } on FunctionException catch (e) {
    // Yalnızca fonksiyon deploy edilmemişse (404) sessizce geç — bu durumda
    // rate-limit "best-effort" kabul edilir. 401/403/429/500 gibi
    // sunucunun BİLEREK verdiği reddler asla sessizce yutulmamalı; aksi
    // halde istemci "dryRun" davranışını taklit edip gerçek reddi bypass
    // edebilir.
    if (e.status == 404) return;
    if (e.status == 429) {
      throw Exception('rate_limited_user');
    }
    rethrow;
  } catch (e) {
    final raw = e.toString();
    if (raw.contains('rate_limited_')) {
      throw Exception(raw);
    }
    // Gerçek ağ hatası (SocketException, timeout vb.) — fonksiyona hiç
    // ulaşılamadı, sunucudan bir "izin verildi/verilmedi" yanıtı yok.
    // Rate-limit best-effort olduğu için burada geçiyoruz (FunctionException
    // dalının aksine: orada sunucu YANIT VERDİ ve reddi bilinçliydi).
    if (isLikelyOfflineError(e)) return;
    rethrow;
  }
}
