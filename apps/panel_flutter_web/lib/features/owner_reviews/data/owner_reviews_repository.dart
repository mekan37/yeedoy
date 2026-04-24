import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/owner_review_models.dart';

final ownerReviewsRepositoryProvider =
    Provider<OwnerReviewsRepository>((ref) {
  return OwnerReviewsRepository(ref.watch(supabaseProvider));
});

class OwnerReviewsRepository {
  OwnerReviewsRepository(this.client);
  final SupabaseClient client;

  Future<List<OwnerReviewItem>> listReviews({
    required String businessId,
    required String sort,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await client.rpc('get_owner_reviews_v1', params: {
        'p_business_id': businessId,
        'p_sort': sort,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((r) =>
              OwnerReviewItem.fromMap((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<String> submitReply({
    required String reviewId,
    required String content,
  }) async {
    try {
      final res = await client.rpc('submit_review_reply', params: {
        'p_review_id': reviewId,
        'p_content': content,
      });
      final map = res as Map;
      if (map['ok'] != true) {
        throw Exception(map['error']?.toString() ?? 'reply_failed');
      }
      return map['reply_id'] as String;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> deleteReply({required String reviewId}) async {
    try {
      final res = await client.rpc('delete_review_reply', params: {
        'p_review_id': reviewId,
      });
      final map = res as Map;
      if (map['ok'] != true) {
        throw Exception(map['error']?.toString() ?? 'delete_failed');
      }
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
