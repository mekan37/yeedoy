import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

final businessRecentCheckinsProvider =
    FutureProvider.family<int, String>((ref, businessId) async {
  if (businessId.trim().isEmpty) return 0;
  final client = ref.watch(supabaseProvider);
  try {
    final res = await client.rpc('get_business_recent_checkins_v1', params: {
      'p_business_id': businessId,
      'p_hours': 2,
    });
    if (res is Map) {
      final data = res.cast<String, dynamic>();
      final value = data['count'];
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }
    return 0;
  } catch (e) {
    throw Exception(AppErrorMapper.message(e));
  }
});
