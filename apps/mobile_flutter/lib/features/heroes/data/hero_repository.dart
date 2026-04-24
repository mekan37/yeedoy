import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/hero_models.dart';

final heroRepositoryProvider = Provider<HeroRepository>((ref) {
  return HeroRepository(ref.watch(supabaseProvider));
});

class HeroRepository {
  HeroRepository(this.client);
  final SupabaseClient client;

  Future<List<HeroEntry>> listHeroes({int limit = 20}) async {
    try {
      final res = await client.rpc('get_heroes_v1', params: {
        'p_limit': limit,
      });
      return (res as List)
          .map((row) => HeroEntry.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<WeeklyLeaderboardEntry>> listWeeklyLeaderboard({
    int limit = 10,
  }) async {
    try {
      final res = await client.rpc(
        'get_weekly_contributor_leaderboard_v1',
        params: {'p_limit': limit},
      );
      return (res as List)
          .map((row) => WeeklyLeaderboardEntry.fromMap(
                (row as Map).cast<String, dynamic>(),
              ))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
