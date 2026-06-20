import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(supabaseProvider));
});

class CheckInRepository {
  CheckInRepository(this._client);

  final SupabaseClient _client;

  /// Check-in kaydeder. Best-effort: hata durumunda exception fırlatır,
  /// çağıran sessizce görmezden gelebilir.
  Future<void> logCheckin({
    required String businessId,
    String? menuId,
    String? tableNo,
    String? clientId,
  }) async {
    await _client.rpc(
      'log_checkin_v1',
      params: {
        'p_business_id': businessId,
        'p_menu_id': menuId,
        'p_table_no': tableNo,
        'p_client_id': clientId,
      },
    );
  }
}
