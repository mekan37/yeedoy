import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/feed_item.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FeedRepository(client);
});

class FeedRepository {
  FeedRepository(this.client);
  final SupabaseClient client;

  Future<List<FeedItem>> getMyFeed({int limit = 20, int offset = 0}) async {
    try {
      final res = await client.rpc('get_my_feed_v1', params: {
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => FeedItem.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
