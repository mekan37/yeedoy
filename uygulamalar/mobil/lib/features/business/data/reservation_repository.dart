import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(supabaseProvider));
});

class ReservationResult {
  const ReservationResult({
    required this.reservationId,
    required this.reservationNo,
  });

  final String reservationId;
  final String reservationNo;
}

class ReservationRepository {
  ReservationRepository(this._client);

  final SupabaseClient _client;

  Future<ReservationResult> submitReservation({
    required String businessId,
    required String guestName,
    required String guestPhone,
    String? guestEmail,
    required int partySize,
    required DateTime date,
    required String time, // "19:30"
    String? tablePreference,
    String? specialRequest,
  }) async {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final res = await _client.rpc('create_reservation_v1', params: {
      'p_business_id': businessId,
      'p_guest_name': guestName,
      'p_guest_phone': guestPhone,
      'p_guest_email': guestEmail,
      'p_party_size': partySize,
      'p_date': dateStr,
      'p_time': '$time:00',
      'p_channel': 'mobile',
      'p_table_preference': tablePreference,
      'p_special_request': specialRequest,
    });

    if (res == null) {
      throw Exception('Rezervasyon oluşturulamadı.');
    }

    final data = Map<String, dynamic>.from(res as Map);
    return ReservationResult(
      reservationId: data['id'] as String,
      reservationNo: data['reservation_no'] as String,
    );
  }
}
