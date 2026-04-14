import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/perk_models.dart';

final perkRepositoryProvider = Provider<PerkRepository>((ref) {
  return PerkRepository(ref.watch(supabaseProvider));
});

class PerkRepository {
  PerkRepository(this.client);

  final SupabaseClient client;

  Future<List<BusinessPerk>> fetchActivePerks(String businessId) async {
    try {
      final res = await client.rpc('get_active_perks_v1', params: {
        'p_business_id': businessId,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => BusinessPerk.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
