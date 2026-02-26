import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';

final ownerMonetizationRepositoryProvider =
    Provider<OwnerMonetizationRepository>((ref) {
      final client = ref.watch(supabaseProvider);
      return OwnerMonetizationRepository(client);
    });

class OwnerMonetizationRepository {
  OwnerMonetizationRepository(this._client);

  final SupabaseClient _client;

  Future<void> submitSponsorshipLead({
    required String businessId,
    required String phone,
    required String message,
    required String preferredSurface,
    required Map<String, dynamic> preferredTargeting,
  }) async {
    try {
      final res = await _client.rpc(
        'submit_sponsorship_lead_v1',
        params: {
          'p_business_id': businessId,
          'p_phone': phone.trim(),
          'p_message': message.trim(),
          'p_preferred_surface': preferredSurface,
          'p_preferred_targeting': preferredTargeting,
        },
      );
      if (res is Map) {
        final ok = res['ok'] == true;
        if (!ok) {
          throw Exception(res['error']?.toString() ?? 'Lead kaydi ba?Yarisiz.');
        }
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

