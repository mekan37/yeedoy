import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/collab_list_models.dart';

final collabListRepositoryProvider = Provider<CollabListRepository>((ref) {
  return CollabListRepository(ref.watch(supabaseProvider));
});

class CollabListRepository {
  CollabListRepository(this._client);

  final SupabaseClient _client;

  static const _businessSelect =
      'id,name,category,city,district';

  // ── My lists ──────────────────────────────────────────────────────────────

  Future<List<CollabList>> fetchMyLists() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    // Lists I own
    final owned = await _client
        .from('collab_lists')
        .select()
        .eq('owner_id', userId)
        .order('updated_at', ascending: false);

    // Lists I'm a member of (not owner)
    final memberRows = await _client
        .from('collab_list_members')
        .select('list_id')
        .eq('user_id', userId);

    final memberListIds = (memberRows as List)
        .map((r) => (r as Map<String, dynamic>)['list_id'] as String)
        .toSet();

    final ownedIds =
        (owned as List).map((r) => (r as Map<String, dynamic>)['id'] as String).toSet();
    final foreignIds = memberListIds.difference(ownedIds).toList();

    List<Map<String, dynamic>> memberLists = const [];
    if (foreignIds.isNotEmpty) {
      final res = await _client
          .from('collab_lists')
          .select()
          .inFilter('id', foreignIds)
          .order('updated_at', ascending: false);
      memberLists = (res as List).cast<Map<String, dynamic>>();
    }

    final all = [
      ...(owned as List).cast<Map<String, dynamic>>(),
      ...memberLists,
    ];

    return all.map(CollabList.fromMap).toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<CollabList> createList({
    required String name,
    String? description,
  }) async {
    final row = await _client
        .from('collab_lists')
        .insert({'name': name, 'description': description})
        .select()
        .single();
    return CollabList.fromMap((row as Map).cast<String, dynamic>());
  }

  // ── Detail ─────────────────────────────────────────────────────────────────

  Future<CollabListDetail> fetchDetail(String listId) async {
    final res = await _client.rpc(
      'get_collab_list_detail_v1',
      params: {'p_list_id': listId},
    );
    final data = (res as Map<String, dynamic>);
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    final list = CollabList.fromMap(
      (data['list'] as Map<String, dynamic>),
    );
    final rawItems =
        (data['items'] as List).cast<Map<String, dynamic>>();

    // Enrich with business names in one batch query
    final businessIds = rawItems.map((i) => i['business_id'] as String).toList();
    final businessMap = <String, Map<String, dynamic>>{};
    if (businessIds.isNotEmpty) {
      final businesses = await _client
          .from('businesses_with_stats')
          .select(_businessSelect)
          .inFilter('id', businessIds);
      for (final b in (businesses as List).cast<Map<String, dynamic>>()) {
        businessMap[b['id'] as String] = b;
      }
    }

    final items = rawItems.map((i) {
      final biz = businessMap[i['business_id'] as String];
      return CollabListItem.fromMap({
        ...i,
        'list_id': listId,
        if (biz != null) 'business_name': biz['name'],
        if (biz != null) 'business_category': biz['category'],
        if (biz != null) 'business_city': biz['city'],
        if (biz != null) 'business_district': biz['district'],
      });
    }).toList();

    return CollabListDetail(list: list, items: items);
  }

  // ── Add item ───────────────────────────────────────────────────────────────

  Future<void> addItem(String listId, String businessId, {String? note}) async {
    await _client.from('collab_list_items').insert({
      'list_id': listId,
      'business_id': businessId,
      'added_by': _client.auth.currentUser!.id,
      'note': note,
    });
  }

  // ── Remove item ────────────────────────────────────────────────────────────

  Future<void> removeItem(String itemId) async {
    await _client.from('collab_list_items').delete().eq('id', itemId);
  }

  // ── Vote ───────────────────────────────────────────────────────────────────

  Future<void> upsertVote(String itemId, int vote) async {
    await _client.rpc(
      'upsert_collab_vote_v1',
      params: {'p_item_id': itemId, 'p_vote': vote},
    );
  }

  // ── Join via token ─────────────────────────────────────────────────────────

  Future<String> joinViaToken(String token) async {
    final res = await _client.rpc(
      'join_collab_list_v1',
      params: {'p_token': token},
    );
    final data = (res as Map<String, dynamic>);
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return data['list_id'] as String;
  }

  // ── Delete list ────────────────────────────────────────────────────────────

  Future<void> deleteList(String listId) async {
    await _client.from('collab_lists').delete().eq('id', listId);
  }

  // ── Leave list (member only) ───────────────────────────────────────────────

  Future<void> leaveList(String listId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('collab_list_members')
        .delete()
        .eq('list_id', listId)
        .eq('user_id', userId);
  }
}
