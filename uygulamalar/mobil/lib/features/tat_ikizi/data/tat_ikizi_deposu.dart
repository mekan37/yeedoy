import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/onbellek/istek_onbellegi.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../domain/tat_ikizi_modelleri.dart';

final tasteTwinRepositoryProvider = Provider<TasteTwinRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return TasteTwinRepository(client, ref.watch(requestCacheProvider));
});

class TasteTwinRepository {
  TasteTwinRepository(this.client, RequestCache requestCache)
    : _cache = requestCache.scope(_cacheScope);
  final SupabaseClient client;
  final RequestCacheScope _cache;

  static const String _cacheScope = 'taste_twin';
  static const Duration _readTtl = Duration(minutes: 2);

  void clearReadCache() {
    _cache.invalidatePrefix('');
  }

  String _key(String method, Map<String, Object?> values) {
    return stableRequestCacheKey(method, values);
  }

  Future<List<TasteMatch>> fetchMatches({
    int limit = 20,
    int minOverlap = 3,
    bool force = false,
  }) async {
    final cacheKey = _key('matches', {
      'limit': limit,
      'min_overlap': minOverlap,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<TasteMatch>>(cacheKey, ttl: _readTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_taste_matches_hybrid_v1', params: {
        'p_limit': limit,
        'p_min_overlap': minOverlap,
      });
      final items = (res as List)
          .map((row) => TasteMatch.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<TasteMatch>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteRecommendation>> fetchRecommendations({
    required String matchUserId,
    int limit = 10,
    bool force = false,
  }) async {
    final cacheKey = _key('recommendations', {
      'match_user_id': matchUserId,
      'limit': limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<TasteRecommendation>>(
        cacheKey,
        ttl: _readTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('taste_recommendations_from_match_v2', params: {
        'p_match_user_id': matchUserId,
        'p_limit': limit,
      });
      final items = (res as List)
          .map((row) => TasteRecommendation.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<TasteRecommendation>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteOverlapExample>> fetchOverlapExamples({
    required String otherUserId,
    int limit = 5,
    bool force = false,
  }) async {
    final cacheKey = _key('overlap_examples', {
      'other_user_id': otherUserId,
      'limit': limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<TasteOverlapExample>>(
        cacheKey,
        ttl: _readTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_taste_overlap_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      final items = (res as List)
          .map((row) => TasteOverlapExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<TasteOverlapExample>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteSignalOverlapExample>> fetchSignalOverlapExamples({
    required String otherUserId,
    int limit = 5,
    bool force = false,
  }) async {
    final cacheKey = _key('signal_overlap_examples', {
      'other_user_id': otherUserId,
      'limit': limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<TasteSignalOverlapExample>>(
        cacheKey,
        ttl: _readTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_signal_overlap_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      final items = (res as List)
          .map(
              (row) => TasteSignalOverlapExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<TasteSignalOverlapExample>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteDivergenceExample>> fetchDivergenceExamples({
    required String otherUserId,
    int limit = 3,
    bool force = false,
  }) async {
    final cacheKey = _key('divergence_examples', {
      'other_user_id': otherUserId,
      'limit': limit,
    });
    if (!force) {
      final fresh = _cache.getFresh<List<TasteDivergenceExample>>(
        cacheKey,
        ttl: _readTtl,
      );
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_taste_divergence_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      final items = (res as List)
          .map((row) => TasteDivergenceExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
      _cache.set(cacheKey, items);
      return items;
    } catch (e) {
      final stale = _cache.getStale<List<TasteDivergenceExample>>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<PublicProfile> fetchUserPublicProfile(String userId, {bool force = false}) async {
    final cacheKey = _key('public_profile', {'user_id': userId});
    if (!force) {
      final fresh = _cache.getFresh<PublicProfile>(cacheKey, ttl: _readTtl);
      if (fresh != null) return fresh;
    }
    try {
      final res = await client.rpc('get_user_public_profile_v1', params: {
        'p_user_id': userId,
      });
      final profile = PublicProfile.fromMap((res as Map).cast<String, dynamic>());
      _cache.set(cacheKey, profile);
      return profile;
    } catch (e) {
      final stale = _cache.getStale<PublicProfile>(cacheKey);
      if (stale != null) return stale;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> ensureMyProfile({
    required String displayName,
    required String avatarUrl,
  }) async {
    try {
      await client.rpc('ensure_my_profile_v1', params: {
        'p_display_name': displayName,
        'p_avatar_url': avatarUrl,
      });
    } catch (_) {
      // silent
    }
  }
}

