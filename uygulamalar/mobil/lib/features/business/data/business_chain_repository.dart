import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/chain_info.dart';

final businessChainRepositoryProvider = Provider<BusinessChainRepository>((
  ref,
) {
  return BusinessChainRepository(ref.watch(supabaseProvider));
});

class BusinessChainRepository {
  BusinessChainRepository(this._client);
  final SupabaseClient _client;

  Future<ChainInfo?> fetchChainInfo(String businessId) async {
    try {
      final res = await _client.rpc(
        'get_business_chain_info_v1',
        params: {'p_business_id': businessId},
      );
      if (res == null) return null;
      final list = res as List;
      if (list.isEmpty) return null;
      final row = (list.first as Map).cast<String, dynamic>();
      return ChainInfo(
        chainId: row['chain_id'].toString(),
        chainName: row['chain_name'].toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
