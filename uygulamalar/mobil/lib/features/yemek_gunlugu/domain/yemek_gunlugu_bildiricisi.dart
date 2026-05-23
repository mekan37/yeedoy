import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import 'yemek_gunlugu_modeli.dart';

final yemekGunluguProvider =
    AsyncNotifierProvider<YemekGunluguBildiricisi, List<YemekGunluguKaydi>>(
  YemekGunluguBildiricisi.new,
);

class YemekGunluguBildiricisi
    extends AsyncNotifier<List<YemekGunluguKaydi>> {
  @override
  Future<List<YemekGunluguKaydi>> build() => _fetch();

  Future<List<YemekGunluguKaydi>> _fetch() async {
    final client = ref.read(supabaseProvider);
    if (client.auth.currentUser == null) return const [];
    final res = await client.rpc(
      'get_my_food_journal_v1',
      params: {'p_limit': 50},
    );
    if (res == null) return const [];
    final list = res as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(YemekGunluguKaydi.fromMap)
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> guncelle({
    required String visitId,
    int? amountCents,
    String? note,
    int? rating,
  }) async {
    final client = ref.read(supabaseProvider);
    await client.rpc(
      'update_visit_details_v1',
      params: <String, dynamic>{
        'p_visit_id': visitId,
        'p_amount_cents': ?amountCents,
        'p_personal_note': ?note,
        'p_personal_rating': ?rating,
      },
    );
    // Update local state optimistically
    final current = state.asData?.value ?? const [];
    state = AsyncData(
      current.map((e) {
        if (e.visitId != visitId) return e;
        return e.copyWith(
          amountCents: amountCents ?? e.amountCents,
          personalNote: note ?? e.personalNote,
          personalRating: rating ?? e.personalRating,
        );
      }).toList(),
    );
  }
}
