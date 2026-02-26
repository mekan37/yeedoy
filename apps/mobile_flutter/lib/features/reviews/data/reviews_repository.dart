import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/critical_action_guard.dart';
import '../../../core/security/edge_rate_limit_guard.dart';
import '../../../core/security/write_gatekeeper_client.dart';
import '../domain/review.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(supabaseProvider));
});

class ReviewsRepository {
  ReviewsRepository(this.client);
  final SupabaseClient client;

  Future<List<Review>> listReviews(String businessId) async {
    return getBusinessReviews(
      businessId: businessId,
      sort: 'helpful',
      limit: 50,
      offset: 0,
    );
  }

  // Index önerisi: (business_id, status, created_at desc) ve (business_id, status, helpful_count desc)
  Future<List<Review>> getBusinessReviews({
    required String businessId,
    required String sort, // 'newest' | 'helpful'
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client.rpc(
      'get_business_reviews_v2',
      params: {
        'p_business_id': businessId,
        'p_sort': sort,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (res as List).map((e) => Review.fromMap(e)).toList();
  }

  Future<void> createReview({
    required String businessId,
    required int rating,
    required String content,
    String? title,
  }) async {
    ensureCriticalActionAllowed(client, action: 'review');
    await enforceEdgeRateLimit(
      client,
      action: 'review_submit',
      scope: businessId,
    );
    final res = await client.rpc(
      'submit_review_v1',
      params: {
        'p_business_id': businessId,
        'p_rating': rating,
        'p_title': title,
        'p_content': content,
      },
    );
    if (res is Map && res['ok'] != true) {
      throw Exception((res['error'] ?? 'review_failed').toString());
    }
  }

  Future<void> voteHelpful({
    required String reviewId,
    required String userId,
  }) async {
    await invokeWriteGatekeeper(
      client,
      action: 'review_vote_set',
      payload: {'review_id': reviewId},
    );
  }

  Future<void> unvoteHelpful({
    required String reviewId,
    required String userId,
  }) async {
    await invokeWriteGatekeeper(
      client,
      action: 'review_vote_remove',
      payload: {'review_id': reviewId},
    );
  }

  Future<Set<String>> listMyVotedReviewIds({
    required String userId,
    required List<String> reviewIds,
  }) async {
    if (reviewIds.isEmpty) return <String>{};

    final res = await client
        .from('review_votes')
        .select('review_id')
        .eq('user_id', userId)
        .inFilter('review_id', reviewIds);

    final ids = <String>{};
    for (final row in (res as List)) {
      ids.add(row['review_id'] as String);
    }
    return ids;
  }
}


