import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/diyet_profil.dart';

final dietProfileRepositoryProvider = Provider<DietProfileRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return DietProfileRepository(client);
});

class DietProfileRepository {
  DietProfileRepository(this.client);
  final SupabaseClient client;

  Future<DietProfile?> fetchMyDietProfile() async {
    try {
      final res = await client.rpc('get_my_diet_profile_v1');
      if (res == null) return null;
      return DietProfile.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<DietProfile> upsertMyDietProfile(DietProfile profile) async {
    try {
      final res = await client.rpc('upsert_my_diet_profile_v1', params: {
        'p_vegan': profile.vegan,
        'p_vegetarian': profile.vegetarian,
        'p_gluten_free': profile.glutenFree,
        'p_lactose_free': profile.lactoseFree,
        'p_halal': profile.halal,
        'p_max_calories': profile.maxCalories,
      });
      if (res == null) return profile;
      return DietProfile.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

