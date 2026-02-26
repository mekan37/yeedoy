import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FollowRepository(client);
});

class FollowRepository {
  FollowRepository(this.client);
  final SupabaseClient client;

  Future<void> toggleFollow(String followeeId) async {
    try {
      await client.rpc('toggle_follow_v1', params: {
        'p_followee_id': followeeId,
      });
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
