import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/write_gatekeeper_client.dart';

final visitsRepoProvider = Provider<VisitsRepo>((ref) {
  return VisitsRepo(ref.watch(supabaseProvider));
});

class VisitsRepo {
  VisitsRepo(this.client);
  final SupabaseClient client;

  Future<Set<String>> listMyVisitedBusinessIds(String userId) async {
    final res = await client
        .from('visits')
        .select('business_id')
        .eq('user_id', userId);
    final ids = <String>{};
    for (final row in (res as List)) {
      ids.add(row['business_id'] as String);
    }
    return ids;
  }

  Future<bool> hasVisited({
    required String userId,
    required String businessId,
  }) async {
    final res = await client
        .from('visits')
        .select('id')
        .eq('user_id', userId)
        .eq('business_id', businessId)
        .maybeSingle();
    return res != null;
  }

  Future<void> addVisit({
    required String userId,
    required String businessId,
  }) async {
    await invokeWriteGatekeeper(
      client,
      action: 'visit_add',
      payload: {'business_id': businessId},
    );
  }

  Future<void> removeVisit({
    required String userId,
    required String businessId,
  }) async {
    await invokeWriteGatekeeper(
      client,
      action: 'visit_remove',
      payload: {'business_id': businessId},
    );
  }
}
