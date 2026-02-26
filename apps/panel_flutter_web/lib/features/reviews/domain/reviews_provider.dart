import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repo.dart';
import '../domain/review.dart';

final reviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  return ref.read(reviewsRepoProvider).listReviews(businessId);
});
