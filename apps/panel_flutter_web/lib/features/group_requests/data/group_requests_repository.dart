import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/group_request_models.dart';

final groupRequestsRepositoryProvider = Provider<GroupRequestsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return GroupRequestsRepository(client);
});

class GroupRequestsRepository {
  GroupRequestsRepository(this.client);
  final SupabaseClient client;

  Future<String> createGroupRequest({
    required String city,
    required List<String> districts,
    String? category,
    required DateTime dateTime,
    required int partySize,
    required int budgetTotalCents,
    String? notes,
  }) async {
    try {
      final res = await client.rpc('create_group_request_v1', params: {
        'p_city': city.trim(),
        'p_districts': districts.isEmpty ? null : districts,
        'p_category': category,
        'p_date_time': dateTime.toIso8601String(),
        'p_party_size': partySize,
        'p_budget_total_cents': budgetTotalCents,
        'p_notes': notes,
      });
      if (res is Map && res['ok'] == true) {
        return (res['id'] ?? '').toString();
      }
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupRequest>> listMyRequests({
    String? status,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_group_requests_v1', params: {
        'p_status': status,
        'p_city': null,
        'p_limit': limit,
        'p_offset': offset,
        'p_include_open': false,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => GroupRequest.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupRequest>> listOpenRequestsForBusiness({
    required String city,
    List<String> categories = const [],
    required String businessId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('list_open_requests_for_business_v1', params: {
        'p_city': city,
        'p_categories': categories.isEmpty ? null : categories,
        'p_limit': limit,
        'p_offset': offset,
        'p_business_id': businessId,
      });
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => GroupRequest.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupOffer>> listOffersForRequest(String requestId) async {
    try {
      final res = await client.rpc(
        'get_group_offers_v1',
        params: {'p_request_id': requestId},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => GroupOffer.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupOffer>> listOffersForBusiness(String businessId) async {
    try {
      final res = await client
          .from('group_offers')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => GroupOffer.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> submitGroupOffer({
    required String requestId,
    required String businessId,
    required int offeredTotalCents,
    Map<String, dynamic> includes = const {},
    String? message,
  }) async {
    try {
      final res = await client.rpc('submit_group_offer_v1', params: {
        'p_request_id': requestId,
        'p_business_id': businessId,
        'p_offered_total_cents': offeredTotalCents,
        'p_includes': includes,
        'p_message': message,
      });
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> acceptGroupOffer(String offerId) async {
    try {
      final res = await client.rpc('accept_group_offer_v1', params: {
        'p_offer_id': offerId,
      });
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> closeGroupRequest(String requestId) async {
    try {
      final res = await client.rpc('close_group_request_v1', params: {
        'p_request_id': requestId,
      });
      if (res is Map && res['ok'] == true) return;
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, String>> fetchBusinessNames(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final res = await client.from('businesses').select('id,name').inFilter('id', ids);
    final map = <String, String>{};
    for (final row in (res as List?) ?? const []) {
      if (row is! Map) continue;
      final data = row.cast<String, dynamic>();
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty) continue;
      map[id] = (data['name'] ?? '').toString();
    }
    return map;
  }

  Future<String?> fetchBusinessCity(String businessId) async {
    if (businessId.isEmpty) return null;
    final res = await client
        .from('businesses')
        .select('city')
        .eq('id', businessId)
        .maybeSingle();
    if (res == null) return null;
    final city = (res as Map)['city']?.toString();
    return (city ?? '').trim().isEmpty ? null : city;
  }

  Future<int> voteGroupOffer(String offerId) async {
    try {
      final res = await client.rpc(
        'vote_group_offer_v1',
        params: {'p_offer_id': offerId},
      );
      if (res is Map && res['ok'] == true) {
        final vote = res['vote'];
        if (vote is int) return vote;
        if (vote is num) return vote.toInt();
        return int.tryParse((vote ?? '').toString()) ?? 0;
      }
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
