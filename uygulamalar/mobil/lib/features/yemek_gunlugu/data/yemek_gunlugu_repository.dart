import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/yemek_gunlugu_modeli.dart';

final yemekGunluguRepositoryProvider = Provider<YemekGunluguRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return YemekGunluguRepository(client);
});

class YemekGunluguRepository {
  YemekGunluguRepository(this.client);
  final SupabaseClient client;

  Future<List<YemekGunluguKaydi>> getMyFoodJournal({int limit = 50}) async {
    if (client.auth.currentUser == null) return const [];
    final res = await client.rpc(
      'get_my_food_journal_v1',
      params: {'p_limit': limit},
    );
    if (res == null) return const [];
    final list = res as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(YemekGunluguKaydi.fromMap)
        .toList();
  }

  Future<void> updateVisitDetails({
    required String visitId,
    int? amountCents,
    String? note,
    int? rating,
  }) async {
    await client.rpc(
      'update_visit_details_v1',
      params: <String, dynamic>{
        'p_visit_id': visitId,
        'p_amount_cents': ?amountCents,
        'p_personal_note': ?note,
        'p_personal_rating': ?rating,
      },
    );
  }
}
