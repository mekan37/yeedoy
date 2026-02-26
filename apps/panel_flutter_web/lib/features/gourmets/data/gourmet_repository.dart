import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/gourmet_user.dart';

final gourmetRepositoryProvider = Provider<GourmetRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return GourmetRepository(client);
});

class GourmetRepository {
  GourmetRepository(this.client);
  final SupabaseClient client;

  Future<List<GourmetUser>> discover({int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('discover_gourmets_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => GourmetUser.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<List<GourmetUser>> getMyFollowing({int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('get_my_following_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => GourmetUser.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
