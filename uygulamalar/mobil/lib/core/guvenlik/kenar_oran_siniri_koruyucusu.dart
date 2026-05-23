import 'package:supabase_flutter/supabase_flutter.dart';

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
  } catch (e) {
    final raw = e.toString();
    if (raw.contains('rate_limited_')) {
      throw Exception(raw);
    }
    if (raw.contains('429')) {
      throw Exception('rate_limited_user');
    }
    rethrow;
  }
}
