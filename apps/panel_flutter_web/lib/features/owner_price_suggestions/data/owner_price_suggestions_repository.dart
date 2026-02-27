import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/rpc_names.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/write_gatekeeper_client.dart';
import '../domain/owner_price_suggestion_models.dart';

final ownerPriceSuggestionsRepositoryProvider =
    Provider<OwnerPriceSuggestionsRepository>((ref) {
      return OwnerPriceSuggestionsRepository(ref.watch(supabaseProvider));
    });

class OwnerPriceSuggestionsRepository {
  OwnerPriceSuggestionsRepository(this.client);
  final SupabaseClient client;

  Future<List<OwnerPriceSuggestionItem>> listSuggestions({
    required String businessId,
    required String status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        RpcNames.ownerListPriceSuggestions,
        params: {
          'p_business_id': businessId,
          'p_status': status,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (res as List)
          .map(
            (row) => OwnerPriceSuggestionItem.fromMap(
              (row as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approve(String suggestionId) async {
    try {
      await invokeWriteGatekeeper(
        client,
        action: 'owner_price_suggestion_approve',
        payload: {'suggestion_id': suggestionId},
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> reject({
    required String suggestionId,
    required String note,
  }) async {
    try {
      await invokeWriteGatekeeper(
        client,
        action: 'owner_price_suggestion_reject',
        payload: {'suggestion_id': suggestionId, 'reason': note.trim()},
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
