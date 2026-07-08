import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  return CheckInRepository(ref.watch(supabaseProvider));
});

enum CheckInResult { success, alreadyCheckedIn, notAuthenticated, error }

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

  /// Bugün bu işletmeye check-in yapılmış mı kontrol eder.
  Future<bool> hasCheckedInToday(String businessId) async {
    final res = await _client.rpc(
      'get_my_checkin_today_v1',
      params: {'p_business_id': businessId},
    );
    return (res as Map<String, dynamic>)['checked_in'] as bool? ?? false;
  }

  /// "Gerçekten Buradayım" check-in'i kaydet.
  Future<CheckInResult> submitCheckIn(String businessId) async {
    final res = await _client.rpc(
      'submit_checkin_v1',
      params: {'p_business_id': businessId},
    );
    final map = res as Map<String, dynamic>;
    if (map['ok'] == true) return CheckInResult.success;
    final err = (map['error'] as String? ?? '').trim();
    if (err == 'already_checked_in_today') return CheckInResult.alreadyCheckedIn;
    if (err == 'not_authenticated') return CheckInResult.notAuthenticated;
    return CheckInResult.error;
  }
}
