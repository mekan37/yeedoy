import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';
import '../domain/review_rating_summary.dart';

final reviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  return ref.read(reviewsRepositoryProvider).listReviews(businessId);
});

final reviewRatingSummaryProvider =
    FutureProvider.family<ReviewRatingSummary, String>((ref, businessId) async {
  return ref.read(reviewsRepositoryProvider).fetchRatingSummary(businessId);
});

final reviewPhotosProvider =
    FutureProvider.family<List<String>, String>((ref, reviewId) async {
  return ref.read(reviewsRepositoryProvider).fetchReviewPhotos(reviewId);
});

final businessReviewPhotosProvider =
    FutureProvider.family<List<String>, String>((ref, businessId) async {
  return ref
      .read(reviewsRepositoryProvider)
      .fetchBusinessReviewPhotos(businessId);
});

/// Fetches owner replies for a list of review IDs.
/// Key: reviewId, value: {id, content, created_at}.
final reviewRepliesBatchProvider = FutureProvider.family<
    Map<String, Map<String, dynamic>>, List<String>>((ref, reviewIds) async {
  return ref.read(reviewsRepositoryProvider).fetchReplyBatch(reviewIds);
});

