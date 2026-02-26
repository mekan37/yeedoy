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

  Future<List<BusinessPerk>> getActivePerks(String businessId) async {
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

  Future<List<BusinessPerk>> listOwnerPerks(String businessId) async {
    try {
      final res = await client.rpc('owner_list_perks_v1', params: {
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

  Future<Map<String, dynamic>> createPerk({
    required String businessId,
    required String title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    required bool requiresCheckin,
  }) async {
    final res = await client.rpc('owner_create_perk_v1', params: {
      'p_business_id': businessId,
      'p_title': title,
      'p_description': description,
      'p_starts_at': startsAt?.toIso8601String(),
      'p_ends_at': endsAt?.toIso8601String(),
      'p_requires_checkin': requiresCheckin,
    });
    return (res as Map?)?.cast<String, dynamic>() ?? const {};
  }

  Future<Map<String, dynamic>> setPerkStatus({
    required String perkId,
    required String status,
  }) async {
    final res = await client.rpc('owner_set_perk_status_v1', params: {
      'p_perk_id': perkId,
      'p_status': status,
    });
    return (res as Map?)?.cast<String, dynamic>() ?? const {};
  }
}
