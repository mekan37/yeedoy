import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/regional_recommendation_models.dart';

final regionalRecommendationRepositoryProvider =
    Provider<RegionalRecommendationRepository>((ref) {
  return RegionalRecommendationRepository(ref.watch(supabaseProvider));
});

class RegionalRecommendationRepository {
  RegionalRecommendationRepository(this._supabase);
  final dynamic _supabase;

  Future<List<RegionalBusiness>> check(String currentCity) async {
    final res = await _supabase.rpc(
      'check_regional_recommendation_v1',
      params: {'p_current_city': currentCity},
    );
    if (res is! List) return const [];
    return res
        .whereType<Map>()
        .map((row) => RegionalBusiness.fromMap(row.cast<String, dynamic>()))
        .toList();
  }
}
