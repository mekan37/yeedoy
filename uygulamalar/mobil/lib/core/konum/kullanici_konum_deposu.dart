import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ag/supabase_saglayicisi.dart';
import '../gizlilik/kisisel_veri_minimizator.dart';

final userLocationRepositoryProvider = Provider<UserLocationRepository>((ref) {
  return UserLocationRepository(ref.watch(supabaseProvider));
});

class UserLocationRepository {
  UserLocationRepository(this.client);
  final SupabaseClient client;

  Future<Map<String, dynamic>?> getPrefs() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;
    final res = await client.rpc('get_user_location_prefs_v1');
    if (res is Map && res['ok'] == true) {
      final data = res['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return null;
    }
    return null;
  }

  Future<void> upsertPrefs({
    required String city,
    required String district,
    String? neighborhood,
    required String mode,
    double? lat,
    double? lng,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final roundedLat = lat == null ? null : roundCoordinate(lat, decimals: 3);
    final roundedLng = lng == null ? null : roundCoordinate(lng, decimals: 3);
    await client.rpc(
      'upsert_user_location_prefs_v1',
      params: {
        'p_city': city,
        'p_district': district,
        'p_neighborhood': neighborhood,
        'p_mode': mode,
        'p_lat': roundedLat,
        'p_lng': roundedLng,
      },
    );
  }
}
