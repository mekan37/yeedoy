import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.watch(supabaseProvider));
});

class ReferralStats {
  const ReferralStats({required this.referralCode, required this.invitedCount});

  final String referralCode;
  final int invitedCount;
}

class ReferralRepository {
  ReferralRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<ReferralStats> fetchMyStats() async {
    final res = await _supabase.rpc('get_my_referral_stats_v1');
    final map = (res is Map) ? res.cast<String, dynamic>() : <String, dynamic>{};
    return ReferralStats(
      referralCode: (map['referral_code'] as String?) ?? '',
      invitedCount: ((map['invited_count'] as num?) ?? 0).toInt(),
    );
  }
}
