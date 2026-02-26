import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/taste_twin_models.dart';

final tasteTwinRepositoryProvider = Provider<TasteTwinRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return TasteTwinRepository(client);
});

class TasteTwinRepository {
  TasteTwinRepository(this.client);
  final SupabaseClient client;

  Future<List<TasteMatch>> getMatches({int limit = 20, int minOverlap = 3}) async {
    try {
      final res = await client.rpc('get_taste_matches_hybrid_v1', params: {
        'p_limit': limit,
        'p_min_overlap': minOverlap,
      });
      return (res as List)
          .map((row) => TasteMatch.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteRecommendation>> getRecommendations({
    required String matchUserId,
    int limit = 10,
  }) async {
    try {
      final res = await client.rpc('taste_recommendations_from_match_v2', params: {
        'p_match_user_id': matchUserId,
        'p_limit': limit,
      });
      return (res as List)
          .map((row) => TasteRecommendation.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteOverlapExample>> getOverlapExamples({
    required String otherUserId,
    int limit = 5,
  }) async {
    try {
      final res = await client.rpc('get_taste_overlap_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      return (res as List)
          .map((row) => TasteOverlapExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteSignalOverlapExample>> getSignalOverlapExamples({
    required String otherUserId,
    int limit = 5,
  }) async {
    try {
      final res = await client.rpc('get_signal_overlap_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      return (res as List)
          .map(
              (row) => TasteSignalOverlapExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<TasteDivergenceExample>> getDivergenceExamples({
    required String otherUserId,
    int limit = 3,
  }) async {
    try {
      final res = await client.rpc('get_taste_divergence_examples_v1', params: {
        'p_other_user_id': otherUserId,
        'p_limit': limit,
      });
      return (res as List)
          .map((row) => TasteDivergenceExample.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<PublicProfile> getUserPublicProfile(String userId) async {
    try {
      final res = await client.rpc('get_user_public_profile_v1', params: {
        'p_user_id': userId,
      });
      return PublicProfile.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
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
