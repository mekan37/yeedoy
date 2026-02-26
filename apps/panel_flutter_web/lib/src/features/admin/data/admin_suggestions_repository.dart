import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/security/admin_api_client.dart';
import '../domain/admin_models.dart';

final adminSuggestionsRepositoryProvider = Provider<AdminSuggestionsRepository>(
  (ref) {
    final client = ref.watch(supabaseProvider);
    return AdminSuggestionsRepository(client);
  },
);

class AdminSuggestionsRepository {
  AdminSuggestionsRepository(this.client);
  final SupabaseClient client;

  Future<List<AdminSuggestionItem>> listSuggestions({
    String? status,
    String? assigned,
    bool? slaOnly,
    int limit = 50,
    int offset = 0,
    String? query,
  }) async {
    try {
      final res = await client.rpc(
        'admin_list_business_suggestions_v3',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_assigned': (assigned ?? '').trim().isEmpty ? null : assigned,
          'p_sla_only': slaOnly == true ? true : null,
          'p_limit': limit,
          'p_offset': offset,
          'p_q': (query ?? '').trim().isEmpty ? null : query,
        },
      );
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => AdminSuggestionItem.fromMap(m.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> assignSuggestion(String suggestionId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_assign_business_suggestion_v1',
        params: {'p_suggestion_id': suggestionId},
        reason: 'business_suggestion_assigned',
        targetType: 'business_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> unassignSuggestion(String suggestionId) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_unassign_business_suggestion_v1',
        params: {'p_suggestion_id': suggestionId},
        reason: 'business_suggestion_unassigned',
        targetType: 'business_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> exportCsv({String? status, String? query}) async {
    try {
      final res = await client.rpc(
        'admin_export_business_suggestions_csv_v1',
        params: {
          'p_status': (status ?? '').trim().isEmpty ? null : status,
          'p_q': (query ?? '').trim().isEmpty ? null : query,
        },
      );
      return res?.toString() ?? '';
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> approveSuggestion({
    required String suggestionId,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_approve_business_suggestion_v1',
        params: {
          'p_suggestion_id': suggestionId,
          'p_admin_note': (adminNote ?? '').trim().isEmpty
              ? null
              : adminNote!.trim(),
        },
        reason: (adminNote ?? '').trim().isEmpty
            ? 'business_suggestion_approved'
            : adminNote!.trim(),
        targetType: 'business_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> rejectSuggestion({
    required String suggestionId,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_reject_business_suggestion_v1',
        params: {
          'p_suggestion_id': suggestionId,
          'p_admin_note': (adminNote ?? '').trim().isEmpty
              ? null
              : adminNote!.trim(),
        },
        reason: (adminNote ?? '').trim().isEmpty
            ? 'business_suggestion_rejected'
            : adminNote!.trim(),
        targetType: 'business_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> bulkRejectSuggestions({
    required List<String> suggestionIds,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_bulk_reject_business_suggestions_v1',
        params: {
          'p_suggestion_ids': suggestionIds,
          'p_admin_note': (adminNote ?? '').trim().isNotEmpty
              ? adminNote!.trim()
              : null,
        },
        reason: (adminNote ?? '').trim().isNotEmpty
            ? adminNote!.trim()
            : 'business_suggestions_bulk_rejected',
        targetType: 'business_suggestions',
        targetId: suggestionIds.length == 1 ? suggestionIds.first : 'bulk',
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<DuplicateBusiness>> findDuplicates({
    required String suggestionId,
    double threshold = 0.7,
  }) async {
    try {
      final res = await client.rpc(
        'admin_find_duplicate_businesses_v1',
        params: {'p_suggestion_id': suggestionId, 'p_threshold': threshold},
      );
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => DuplicateBusiness.fromMap(m.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> linkToExisting({
    required String suggestionId,
    required String businessId,
    String? adminNote,
  }) async {
    try {
      await invokeAdminRpcWrite(
        client,
        rpcName: 'admin_link_suggestion_to_business_v1',
        params: {
          'p_suggestion_id': suggestionId,
          'p_business_id': businessId,
          'p_admin_note': (adminNote ?? '').trim().isEmpty
              ? null
              : adminNote!.trim(),
        },
        reason: (adminNote ?? '').trim().isEmpty
            ? 'business_suggestion_linked'
            : adminNote!.trim(),
        targetType: 'business_suggestions',
        targetId: suggestionId,
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
