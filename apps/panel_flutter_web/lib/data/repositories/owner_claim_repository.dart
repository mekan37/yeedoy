import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../core/network/supabase_provider.dart';
import '../../domain/models/owner_claim.dart';

final ownerClaimRepositoryProvider = Provider<OwnerClaimRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return OwnerClaimRepository(client);
});

class OwnerClaimResult {
  const OwnerClaimResult({required this.ok, this.error, this.claimId});

  final bool ok;
  final String? error;
  final String? claimId;

  factory OwnerClaimResult.fromMap(Map<String, dynamic> m) => OwnerClaimResult(
        ok: (m['ok'] as bool?) ?? false,
        error: m['error'] as String?,
        claimId: m['claim_id'] as String?,
      );
}

class OwnerClaimRepository {
  OwnerClaimRepository(this.client);
  final SupabaseClient client;

  Future<OwnerClaimResult> submitClaim({
    required String businessId,
    required String fullName,
    required String phone,
    String? evidenceUrl,
    String? note,
  }) async {
    try {
      final res = await client.rpc('submit_owner_claim_v1', params: {
        'p_business_id': businessId,
        'p_full_name': fullName.trim(),
        'p_phone': phone.trim(),
        'p_evidence_url': (evidenceUrl ?? '').trim().isEmpty ? null : evidenceUrl!.trim(),
        'p_note': (note ?? '').trim(),
      });
      if (res is Map) {
        return OwnerClaimResult.fromMap(res.cast<String, dynamic>());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return OwnerClaimResult.fromMap((res.first as Map).cast<String, dynamic>());
      }
      return const OwnerClaimResult(ok: false, error: 'unknown');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<OwnerClaim>> fetchMyClaims({int? limit, int? offset}) async {
    try {
      var query = client
          .from('owner_claims')
          .select('id,business_id,status,created_at,admin_note')
          .order('created_at', ascending: false);
      if (limit != null) {
        final start = offset ?? 0;
        final end = start + limit - 1;
        query = query.range(start, end);
      }
      final List<dynamic> res = await query;
      return res
          .whereType<Map>()
          .map((m) => OwnerClaim.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, String>> fetchBusinessNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final List<dynamic> res = await client
          .from('businesses')
          .select('id,name')
          .inFilter('id', ids);
      final map = <String, String>{};
      for (final row in res.whereType<Map>()) {
        final id = row['id'] as String?;
        final name = row['name'] as String?;
        if (id != null && name != null) {
          map[id] = name;
        }
      }
      return map;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
