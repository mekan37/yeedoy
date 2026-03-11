import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../domain/group_request_models.dart';

final groupRequestsRepositoryProvider = Provider<GroupRequestsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return GroupRequestsRepository(client, ref.watch(requestCacheProvider));
});

class GroupRequestsRepository {
  GroupRequestsRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'group_requests';
  static const Duration _listTtl = Duration(seconds: 60);
  static const Duration _offersTtl = Duration(seconds: 45);
  static const Duration _lookupTtl = Duration(minutes: 5);

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  void invalidateRequest(String requestId) {
    _cache.invalidatePrefix('my_requests|');
    _cache.invalidatePrefix('open_requests|');
    _cache.invalidatePrefix('offers_request|');
    _cache.invalidatePrefix('offers_business|');
    if (requestId.trim().isNotEmpty) {
      _cache.invalidatePrefix('business_names|');
    }
  }

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
        final id = (res['id'] ?? '').toString();
        invalidateRequest(id);
        return id;
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
    bool force = false,
  }) async {
    final cacheKey = _key('my_requests', {
      'status': status?.trim(),
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<GroupRequest>>(cacheKey, ttl: _listTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('list_group_requests_v1', params: {
        'p_status': status,
        'p_city': null,
        'p_limit': limit,
        'p_offset': offset,
        'p_include_open': false,
      });
      final rows = (res as List?) ?? const [];
      final items = rows
          .whereType<Map>()
          .map((row) => GroupRequest.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GroupRequest>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupRequest>> listOpenRequestsForBusiness({
    required String city,
    List<String> categories = const [],
    required String businessId,
    int limit = 30,
    int offset = 0,
    bool force = false,
  }) async {
    final normalizedCategories = [...categories]..sort();
    final cacheKey = _key('open_requests', {
      'city': city.trim(),
      'categories': normalizedCategories.join(','),
      'business_id': businessId.trim(),
      'limit': limit,
      'offset': offset,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<GroupRequest>>(cacheKey, ttl: _listTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('list_open_requests_for_business_v1', params: {
        'p_city': city,
        'p_categories': normalizedCategories.isEmpty ? null : normalizedCategories,
        'p_limit': limit,
        'p_offset': offset,
        'p_business_id': businessId,
      });
      final rows = (res as List?) ?? const [];
      final items = rows
          .whereType<Map>()
          .map((row) => GroupRequest.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GroupRequest>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupOffer>> listOffersForRequest(
    String requestId, {
    bool force = false,
  }) async {
    final cacheKey = _key('offers_request', {'request_id': requestId.trim()});
    if (!force) {
      final fresh = _cache.getFresh<List<GroupOffer>>(cacheKey, ttl: _offersTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc(
        'get_group_offers_v1',
        params: {'p_request_id': requestId},
      );
      final rows = (res as List?) ?? const [];
      final items = rows
          .whereType<Map>()
          .map((row) => GroupOffer.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GroupOffer>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GroupOffer>> listOffersForBusiness(
    String businessId, {
    bool force = false,
  }) async {
    final cacheKey = _key('offers_business', {'business_id': businessId.trim()});
    if (!force) {
      final fresh = _cache.getFresh<List<GroupOffer>>(cacheKey, ttl: _offersTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client
          .from('group_offers')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final rows = (res as List?) ?? const [];
      final items = rows
          .whereType<Map>()
          .map((row) => GroupOffer.fromMap(row.cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<GroupOffer>>(cacheKey);
      if (stale != null) return stale;
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
      if (res is Map && res['ok'] == true) {
        invalidateRequest(requestId);
        return;
      }
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
      if (res is Map && res['ok'] == true) {
        final requestId = (res['request_id'] ?? '').toString();
        if (requestId.isNotEmpty) {
          invalidateRequest(requestId);
        } else {
          clearReadCache();
        }
        return;
      }
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
      if (res is Map && res['ok'] == true) {
        invalidateRequest(requestId);
        return;
      }
      throw Exception((res is Map ? res['code'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<Map<String, String>> fetchBusinessNames(
    List<String> ids, {
    bool force = false,
  }) async {
    if (ids.isEmpty) return const {};
    final normalizedIds = [...ids]..sort();
    final cacheKey = _key('business_names', {'ids': normalizedIds.join(',')});
    if (!force) {
      final fresh = _cache.getFresh<Map<String, String>>(cacheKey, ttl: _lookupTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client
          .from('businesses')
          .select('id,name')
          .inFilter('id', normalizedIds);
      final map = <String, String>{};
      for (final row in (res as List?) ?? const []) {
        if (row is! Map) continue;
        final data = row.cast<String, dynamic>();
        final id = (data['id'] ?? '').toString();
        if (id.isEmpty) continue;
        map[id] = (data['name'] ?? '').toString();
      }
      _cache.set(cacheKey, map);
      return map;
    } catch (e) {
      final stale = _cache.getStale<Map<String, String>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String?> fetchBusinessCity(String businessId, {bool force = false}) async {
    if (businessId.isEmpty) return null;
    final cacheKey = _key('business_city', {'business_id': businessId.trim()});
    if (!force) {
      final fresh = _cache.getFresh<String>(cacheKey, ttl: _lookupTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client
          .from('businesses')
          .select('city')
          .eq('id', businessId)
          .maybeSingle();
      if (res == null) return null;
      final city = (res as Map)['city']?.toString();
      final value = (city ?? '').trim().isEmpty ? null : city;
      if (value != null) {
        _cache.set(cacheKey, value);
      }
      return value;
    } catch (e) {
      final stale = _cache.getStale<String>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<int> voteGroupOffer(
    String offerId, {
    bool? voted,
  }) async {
    try {
      final currentVote = await _readCurrentUserGroupOfferVote(offerId);
      final desiredVoted = voted ?? currentVote != 1;
      final token = await createOfflineMutationIdempotencyToken(
        action: 'set_group_offer_vote',
        payload: {
          'offer_id': offerId,
          'voted': desiredVoted,
        },
      );
      dynamic res;
      try {
        res = await client.rpc(
          'set_group_offer_vote_v2',
          params: {
            'p_offer_id': offerId,
            'p_voted': desiredVoted,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'set_group_offer_vote_v2')) rethrow;
        if ((currentVote == 1) == desiredVoted) {
          clearReadCache();
          return desiredVoted ? 1 : 0;
        }
        res = await client.rpc(
          'vote_group_offer_v1',
          params: {'p_offer_id': offerId},
        );
      }
      if (res is Map && res['ok'] == true) {
        final vote = res['vote'];
        clearReadCache();
        if (vote is int) return vote;
        if (vote is num) return vote.toInt();
        return int.tryParse((vote ?? '').toString()) ?? 0;
      }
      throw Exception((res is Map ? res['error'] : null) ?? 'unknown_error');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<int?> _readCurrentUserGroupOfferVote(String offerId) async {
    final res = await client
        .from('group_offer_votes')
        .select('vote')
        .eq('offer_id', offerId)
        .maybeSingle();
    if (res == null) return null;
    final vote = (res as Map)['vote'];
    if (vote is int) return vote;
    if (vote is num) return vote.toInt();
    return int.tryParse((vote ?? '').toString());
  }
}

bool _isMissingRpcError(Object error, String rpcName) {
  final text = error.toString().toLowerCase();
  final normalized = rpcName.toLowerCase();
  return text.contains(normalized) &&
      (text.contains('could not find') ||
          text.contains('does not exist') ||
          text.contains('not found') ||
          text.contains('undefined function') ||
          text.contains('pgrst202'));
}
