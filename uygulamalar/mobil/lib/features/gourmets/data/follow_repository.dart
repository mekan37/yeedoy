import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/request_cache.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FollowRepository(client, ref.watch(requestCacheProvider));
});

class FollowRepository {
  FollowRepository(this.client, this._requestCache);
  final SupabaseClient client;
  final RequestCache _requestCache;

  Future<bool> toggleFollow(String followeeId) async {
    final current = await isFollowing(followeeId);
    return setFollow(followeeId, following: !current);
  }

  Future<bool> isFollowing(String followeeId) async {
    final res = await client
        .from('user_follows')
        .select('followee_id')
        .eq('followee_id', followeeId)
        .maybeSingle();
    return res != null;
  }

  Future<bool> setFollow(
    String followeeId, {
    required bool following,
  }) async {
    try {
      final token = await createOfflineMutationIdempotencyToken(
        action: 'set_follow',
        payload: {
          'followee_id': followeeId,
          'following': following,
        },
      );
      dynamic res;
      try {
        res = await client.rpc(
          'set_follow_v2',
          params: {
            'p_followee_id': followeeId,
            'p_following': following,
            'p_idempotency_key': token.idempotencyKey,
          },
        );
      } catch (e) {
        if (!_isMissingRpcError(e, 'set_follow_v2')) rethrow;
        final current = await isFollowing(followeeId);
        if (current == following) {
          _invalidateCaches();
          return following;
        }
        res = await client.rpc('toggle_follow_v1', params: {
          'p_followee_id': followeeId,
        });
      }
      final actual = _parseFollowStateResponse(
        res,
        fallbackError: 'Takip islemi basarisiz.',
      );
      _invalidateCaches();
      return actual;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  void _invalidateCaches() {
    _requestCache.scope('gourmets').invalidatePrefix('discover|');
    _requestCache.scope('gourmets').invalidatePrefix('following|');
    _requestCache.scope('gourmets_feed').invalidatePrefix('my_feed|');
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

bool _parseFollowStateResponse(
  dynamic res, {
  required String fallbackError,
}) {
  if (res is Map) {
    final data = res.cast<String, dynamic>();
    final error = (data['error'] ?? '').toString().trim();
    if (error.isNotEmpty) {
      throw Exception(error);
    }
    if (data['following'] is bool) {
      return data['following'] as bool;
    }
  }
  if (res is List && res.isNotEmpty) {
    final first = res.first;
    if (first is Map) {
      return _parseFollowStateResponse(
        first.cast<String, dynamic>(),
        fallbackError: fallbackError,
      );
    }
  }
  throw Exception(fallbackError);
}
