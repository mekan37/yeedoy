import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/business_badge.dart';

final businessBadgesRepositoryProvider = Provider<BusinessBadgesRepository>(
  (ref) => BusinessBadgesRepository(ref.watch(supabaseProvider)),
);

final businessBadgesProvider =
    FutureProvider.autoDispose.family<List<BusinessBadge>, String>(
  (ref, businessId) async {
    final repo = ref.watch(businessBadgesRepositoryProvider);
    return repo.fetchBadges(businessId);
  },
);

class BusinessBadgesRepository {
  const BusinessBadgesRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<List<BusinessBadge>> fetchBadges(String businessId) async {
    final response = await _supabase.rpc(
      'get_business_badges_v1',
      params: {'p_business_id': businessId},
    ) as List;
    return response
        .cast<Map<String, dynamic>>()
        .map(BusinessBadge.fromMap)
        .toList();
  }
}
