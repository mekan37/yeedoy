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
    // Fix 3: Validate time format HH:MM
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) {
      throw ArgumentError('time parametresi "SS:DD" formatında olmalıdır (örn: "19:30")');
    }

    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // Fix 1: Wrap RPC call in try-catch for PostgrestException
    try {
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

      // Fix 2: Type guard before Map cast
      if (res is! Map) {
        throw Exception('Beklenmedik sunucu yanıtı.');
      }

      final data = Map<String, dynamic>.from(res);
      return ReservationResult(
        reservationId: data['id'] as String,
        reservationNo: data['reservation_no'] as String,
      );
    } on PostgrestException catch (e) {
      // Extract user-friendly message from SQLSTATE errors
      final msg = e.message;
      if (msg.contains('validation_error:')) {
        throw Exception(msg.replaceFirst(RegExp(r'^validation_error:\s*'), ''));
      }
      if (msg.contains('not_found:')) {
        throw Exception('İşletme bulunamadı veya rezervasyon kabul etmiyor.');
      }
      throw Exception('Rezervasyon oluşturulamadı. Lütfen tekrar deneyin.');
    }
  }
}
