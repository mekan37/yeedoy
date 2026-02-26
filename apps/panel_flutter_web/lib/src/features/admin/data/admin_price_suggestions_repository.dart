import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/network/rpc_names.dart';
import '../../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminPriceSuggestionsRepositoryProvider =
    Provider<AdminPriceSuggestionsRepository>((ref) {
      return AdminPriceSuggestionsRepository(ref.watch(supabaseProvider));
    });

class AdminPriceSuggestionsRepository {
  AdminPriceSuggestionsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminMenuPriceSuggestionItem>> listSuggestions({
    required String status,
    required bool slaOnly,
    String? assigned,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_menu_price_suggestions_v2',
        params: {
          'p_status': status.trim().isEmpty ? null : status,
          'p_limit': limit,
          'p_offset': offset,
          'p_sla_only': slaOnly,
          'p_assigned': (assigned ?? '').trim().isEmpty ? null : assigned,
        },
      );
      return (res as List)
          .map(
            (row) => AdminMenuPriceSuggestionItem.fromMap(
              (row as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportCsv({
    required String status,
    required bool slaOnly,
    String? assigned,
  }) async {
    try {
      final res = await client.rpc(
        'admin_export_menu_price_suggestions_csv_v1',
        params: {
          'p_status': status.trim().isEmpty ? null : status,
          'p_sla_only': slaOnly,
          'p_assigned': (assigned ?? '').trim().isEmpty ? null : assigned,
        },
      );
      return res?.toString() ?? '';
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approve(String suggestionId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: RpcNames.adminApprovePriceSuggestion,
        params: {'p_suggestion_id': suggestionId},
        reason: 'price_suggestion_approved',
        targetType: 'menu_item_price_suggestions',
        targetId: suggestionId,
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
      await invokeAdminRpcWrite(
        client,
        rpcName: RpcNames.adminRejectPriceSuggestion,
        params: {'p_suggestion_id': suggestionId, 'p_reason': note.trim()},
        reason: note.trim().isEmpty ? 'price_suggestion_rejected' : note.trim(),
        targetType: 'menu_item_price_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
