import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

final legalComplianceRepositoryProvider = Provider<LegalComplianceRepository>((
  ref,
) {
  return LegalComplianceRepository(ref.watch(supabaseProvider));
});

class LegalComplianceRepository {
  LegalComplianceRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<void> acceptActiveBusinessPolicy({required String businessId}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('auth_required');
    }

    final rows = await _supabase
        .from('policy_versions')
        .select('id')
        .eq('policy_type', 'business')
        .eq('is_active', true)
        .limit(1);
    Map? row;
    for (final item in (rows as List?) ?? const []) {
      if (item is Map) {
        row = item;
        break;
      }
    }
    final policyVersionId = (row?['id'] ?? '').toString();
    if (policyVersionId.isEmpty) {
      throw Exception('active_business_policy_missing');
    }

    await _supabase
        .from('business_policy_acceptances')
        .upsert(
          <String, dynamic>{
            'business_id': businessId,
            'user_id': uid,
            'policy_version_id': policyVersionId,
            'accepted_at': DateTime.now().toUtc().toIso8601String(),
            'user_agent': kIsWeb
                ? 'panel_flutter_web/web'
                : 'panel_flutter_web',
          },
          onConflict: 'business_id,user_id,policy_version_id',
          ignoreDuplicates: true,
        );
  }
}
