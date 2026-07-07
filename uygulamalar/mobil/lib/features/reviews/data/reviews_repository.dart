import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/security/critical_action_guard.dart';
import '../../../core/security/edge_rate_limit_guard.dart';
import '../../../core/security/write_gatekeeper_client.dart';
import '../../../core/storage/offline_mutation_idempotency.dart';
import '../../../core/storage/offline_submission_queue.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/my_review_entry.dart';
import '../domain/review.dart';
import '../domain/review_catalog.dart';
import '../domain/review_rating_summary.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(supabaseProvider));
});

class ReviewsRepository {
  ReviewsRepository(this.client);
  final SupabaseClient client;

  Future<List<Review>> listReviews(String businessId) async {
    return fetchBusinessReviews(
      businessId: businessId,
      sort: 'helpful',
      limit: 50,
      offset: 0,
    );
  }

  // Index önerisi: (business_id, status, created_at desc) ve (business_id, status, helpful_count desc)
  Future<List<Review>> fetchBusinessReviews({
    required String businessId,
    required String sort, // 'newest' | 'helpful'
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await client.rpc(
      'get_business_reviews_v4',
      params: {
        'p_business_id': businessId,
        'p_sort': sort,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (res as List).map((e) => Review.fromMap(e)).toList();
  }

  Future<ReviewRatingSummary> fetchRatingSummary(String businessId) async {
    final res = await client.rpc(
      'get_business_rating_summary_v2',
      params: {'p_business_id': businessId},
    );
    final rows = res as List;
    if (rows.isEmpty) return ReviewRatingSummary.empty();
    return ReviewRatingSummary.fromMap(rows.first as Map<String, dynamic>);
  }

  /// Creates a review and returns the review ID on success.
  Future<String?> createReview({
    required String businessId,
    required int rating,
    required String content,
    String? title,
    Map<ReviewRatingCriterion, int?>? criteriaRatings,
  }) async {
    unawaited(flushOfflineSubmissionQueue(client, maxItems: 10));
    ensureCriticalActionAllowed(client, action: 'review');
    final criteriaParams = criteriaRatings != null
        ? ReviewCatalog.buildRpcParams(criteriaRatings)
        : <String, dynamic>{};
    final queuedPayload = await attachOfflineMutationIdempotency(
      action: OfflineSubmissionType.reviewCreate.name,
      payload: {
        'business_id': businessId,
        'p_overall_rating': rating,
        'title': title,
        'content': content,
        ...criteriaParams,
      },
    );
    try {
      await enforceEdgeRateLimit(
        client,
        action: 'review_submit',
        scope: businessId,
      );
      final res = await client.rpc(
        'submit_review_v3',
        params: {
          'p_business_id': businessId,
          'p_overall_rating': rating,
          'p_title': title,
          'p_content': content,
          'p_idempotency_key': queuedPayload['idempotency_key'],
          ...criteriaParams,
        },
      );
      if (res is Map && res['ok'] != true) {
        throw Exception((res['error'] ?? 'review_failed').toString());
      }
      return (res as Map<String, dynamic>)['review_id']?.toString();
    } catch (e) {
      if (isLikelyOfflineError(e)) {
        await OfflineSubmissionQueueStore.enqueue(
          OfflineSubmissionType.reviewCreate,
          queuedPayload,
        );
        throw const OfflineSubmissionQueuedException();
      }
      rethrow;
    }
  }

  /// Uploads review photos to the review_photos table.
  Future<void> uploadReviewPhotos({
    required String reviewId,
    required String businessId,
    required String userId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return;
    final now = DateTime.now();
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final ext = _normalizedExt(file.name);
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path =
          'review-photos/$businessId/${now.millisecondsSinceEpoch}_${_randomHex()}.$ext';
      await client.storage.from('temp').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      await client.from('review_photos').insert({
        'business_id': businessId,
        'user_id': userId,
        'review_id': reviewId,
        'storage_bucket': 'temp',
        'storage_path': path,
        'mime_type': mime,
        'bytes': bytes.length,
        'status': 'pending',
      });
    }
  }

  String _normalizedExt(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase();
    if (ext == 'jpeg') return 'jpg';
    return (ext == 'png' || ext == 'webp') ? ext : 'jpg';
  }

  String _randomHex() {
    final r = DateTime.now().microsecondsSinceEpoch & 0xFFFFFF;
    return r.toRadixString(16).padLeft(6, '0');
  }

  /// Fetches recent review photo URLs for a business (up to [limit] photos).
  Future<List<String>> fetchBusinessReviewPhotos(
    String businessId, {
    int limit = 9,
  }) async {
    final res = await client
        .from('review_photos')
        .select('storage_bucket, storage_path')
        .eq('business_id', businessId)
        .neq('status', 'rejected')
        .order('created_at', ascending: false)
        .limit(limit);
    final rows = res as List;
    return rows.map((r) {
      final bucket = r['storage_bucket'] as String;
      final path = r['storage_path'] as String;
      return client.storage.from(bucket).getPublicUrl(path);
    }).toList();
  }

  /// Fetches approved/pending photo URLs for a review.
  Future<List<String>> fetchReviewPhotos(String reviewId) async {
    final res = await client
        .from('review_photos')
        .select('storage_bucket, storage_path')
        .eq('review_id', reviewId)
        .neq('status', 'rejected')
        .order('created_at')
        .limit(6);
    final rows = res as List;
    return rows.map((r) {
      final bucket = r['storage_bucket'] as String;
      final path = r['storage_path'] as String;
      return client.storage.from(bucket).getPublicUrl(path);
    }).toList();
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

  /// Fetches owner replies for a batch of review IDs.
  /// Returns a map of reviewId → {id, content, created_at}.
  Future<Map<String, Map<String, dynamic>>> fetchReplyBatch(
    List<String> reviewIds,
  ) async {
    if (reviewIds.isEmpty) return {};
    final res = await client.rpc(
      'get_review_replies_batch',
      params: {'p_review_ids': reviewIds},
    );
    final result = <String, Map<String, dynamic>>{};
    for (final row in (res as List)) {
      final map = (row as Map).cast<String, dynamic>();
      result[map['review_id'] as String] = map;
    }
    return result;
  }

  /// Fetches reviews written by [userId], joined with business name + location + image.
  Future<List<MyReviewEntry>> fetchMyReviews(String userId) async {
    final res = await client
        .from('reviews')
        .select(
          'id, business_id, rating, title, content, status, created_at, helpful_count, '
          'businesses(name, district, city, image_url)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List)
        .map((e) => MyReviewEntry.fromMap(e as Map<String, dynamic>))
        .toList();
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
