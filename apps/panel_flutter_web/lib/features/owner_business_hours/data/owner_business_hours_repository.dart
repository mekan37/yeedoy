import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_business_hours_models.dart';

final ownerBusinessHoursRepositoryProvider =
    Provider<OwnerBusinessHoursRepository>((ref) {
  return OwnerBusinessHoursRepository(ref.watch(supabaseProvider));
});

class OwnerBusinessHoursRepository {
  OwnerBusinessHoursRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> fetchHours(String businessId) async {
    try {
      final res = await _client.rpc('get_business_hours_v1', params: {
        'p_business_id': businessId,
      });
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> upsertWeeklyHours({
    required String businessId,
    required List<BusinessHourRow> hours,
  }) async {
    try {
      await _client.rpc('upsert_business_hours_v1', params: {
        'p_business_id': businessId,
        'p_hours': hours.map((h) => h.toJson()).toList(),
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> upsertSpecialHour({
    required String businessId,
    required String date,
    String? openTime,
    String? closeTime,
    required bool isClosed,
    String? note,
  }) async {
    try {
      await _client.rpc('upsert_business_special_hour_v1', params: {
        'p_business_id': businessId,
        'p_date': date,
        'p_open_time': openTime,
        'p_close_time': closeTime,
        'p_is_closed': isClosed,
        'p_note': note,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> deleteSpecialHour({
    required String businessId,
    required String date,
  }) async {
    try {
      await _client.rpc('delete_business_special_hour_v1', params: {
        'p_business_id': businessId,
        'p_date': date,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
