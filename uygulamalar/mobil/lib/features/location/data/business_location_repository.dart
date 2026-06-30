import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final businessLocationRepositoryProvider =
    Provider<BusinessLocationRepository>((ref) {
  return BusinessLocationRepository(ref.watch(supabaseProvider));
});

class BusinessLocationRepository {
  BusinessLocationRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Map<String, double>?> fetchLocation(String businessId) async {
    final data = await _supabase
        .from('businesses')
        .select('latitude, longitude')
        .eq('id', businessId)
        .maybeSingle();
    if (data == null) return null;
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat == null || lng == null) return null;
    return {
      'latitude': (lat as num).toDouble(),
      'longitude': (lng as num).toDouble(),
    };
  }

  Future<void> updateLocation(
    String businessId,
    double lat,
    double lng,
  ) async {
    await _supabase
        .from('businesses')
        .update({'latitude': lat, 'longitude': lng})
        .eq('id', businessId);
  }
}
