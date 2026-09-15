import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/critical_action_guard.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/cache/request_cache.dart';
import '../domain/menu_models.dart';
import 'menu_rpc_utils.dart';

// MenuRepository'nin bölünmesiyle (B42) ayrılan sorumluluk: menü ürünü
// fotoğrafları — listeleme, ekleme, oylama. Menü okuma/fiyat akışlarından
// bağımsız; tek paylaşılan yan etki `menu_items|` cache prefix'inin
// invalidasyonu (fotoğraf eklenince ürün listesi yeniden çekilmeli).

final menuItemPhotoRepositoryProvider = Provider<MenuItemPhotoRepository>((
  ref,
) {
  return MenuItemPhotoRepository(
    ref.watch(supabaseProvider),
    ref.watch(requestCacheProvider).scope('menus'),
  );
});

class MenuItemPhotoRepository {
  MenuItemPhotoRepository(this.client, this._cache);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  Future<List<MenuItemPhoto>> fetchMenuItemPhotos(
    String menuItemId, {
    int limit = 30,
  }) async {
    try {
      final res = await client.rpc(
        'get_menu_item_photos_v1',
        params: {'p_menu_item_id': menuItemId, 'p_limit': limit},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) => MenuItemPhoto.fromMap(row.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String?> addMenuItemPhoto({
    required String menuItemId,
    required String url,
    required String urlLarge,
    required String urlThumb,
    required String provider,
  }) async {
    try {
      ensureCriticalActionAllowed(client, action: 'menu_photo_upload');
      final res = await client.rpc(
        'add_menu_item_photo_v1',
        params: {
          'p_menu_item_id': menuItemId,
          'p_url': url,
          'p_url_large': urlLarge,
          'p_url_thumb': urlThumb,
          'p_provider': provider,
        },
      );
      _cache.invalidatePrefix('menu_items|');
      if (res is Map) {
        final data = res.cast<String, dynamic>();
        if (data['ok'] == true) {
          return (data['photo_id'] ?? '').toString();
        }
        final error = data['error'];
        if (error != null) throw Exception(error.toString());
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        final data = (res.first as Map).cast<String, dynamic>();
        if (data['ok'] == true) {
          return (data['photo_id'] ?? '').toString();
        }
        final error = data['error'];
        if (error != null) throw Exception(error.toString());
      }
      return null;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> voteMenuItemPhoto({
    required String photoId,
    required int vote,
  }) async {
    try {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'menu_item_photo_vote',
        payload: {'photo_id': photoId, 'vote': vote},
      );
      try {
        final res = await client.rpc(
          'set_menu_item_photo_vote_v2',
          params: {
            'p_photo_id': photoId,
            'p_vote': vote,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
        ensureOkResponse(res, fallbackError: 'photo_vote_failed');
      } catch (e) {
        if (!isMissingRpcError(e, 'set_menu_item_photo_vote_v2')) {
          rethrow;
        }
        await _submitDesiredPhotoVoteLegacy(
          client: client,
          photoId: photoId,
          desiredVote: vote,
        );
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}

Future<void> _submitDesiredPhotoVoteLegacy({
  required SupabaseClient client,
  required String photoId,
  required int desiredVote,
}) async {
  final currentVote = await _readCurrentUserMenuItemPhotoVote(
    client,
    photoId: photoId,
  );
  if (currentVote == desiredVote) return;
  if (desiredVote == 0) {
    if (currentVote == null || currentVote == 0) return;
    final res = await client.rpc(
      'vote_menu_item_photo_v1',
      params: {'p_photo_id': photoId, 'p_vote': currentVote},
    );
    ensureOkResponse(res, fallbackError: 'photo_vote_failed');
    return;
  }
  final res = await client.rpc(
    'vote_menu_item_photo_v1',
    params: {'p_photo_id': photoId, 'p_vote': desiredVote},
  );
  ensureOkResponse(res, fallbackError: 'photo_vote_failed');
}

Future<int?> _readCurrentUserMenuItemPhotoVote(
  SupabaseClient client, {
  required String photoId,
}) async {
  final res = await client
      .from('menu_item_photo_votes')
      .select('vote')
      .eq('photo_id', photoId)
      .maybeSingle();
  if (res == null) return null;
  return asInt((res as Map)['vote']);
}
