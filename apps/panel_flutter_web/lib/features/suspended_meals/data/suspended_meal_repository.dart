import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/suspended_meal_models.dart';

final suspendedMealRepositoryProvider = Provider<SuspendedMealRepository>((ref) {
  return SuspendedMealRepository(ref.watch(supabaseProvider));
});

class SuspendedMealRepository {
  SuspendedMealRepository(this.client);
  final SupabaseClient client;

  Future<List<SuspendedMeal>> listActive(String businessId, {int limit = 10}) async {
    try {
      final res = await client.rpc('list_active_suspended_meals_v1', params: {
        'p_business_id': businessId,
        'p_limit': limit,
      });
      return (res as List)
          .map((row) => SuspendedMeal.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> create({
    required String businessId,
    required int amountCents,
    required String currency,
    required String message,
  }) async {
    try {
      await client.rpc('create_suspended_meal_v1', params: {
        'p_business_id': businessId,
        'p_amount_cents': amountCents,
        'p_currency': currency,
        'p_message': message,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> claim({
    required String mealId,
    required String note,
  }) async {
    try {
      await client.rpc('submit_suspended_meal_claim_v1', params: {
        'p_suspended_meal_id': mealId,
        'p_note': note,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
