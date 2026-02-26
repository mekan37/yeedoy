import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repository.dart';
import '../domain/review.dart';

final reviewsProvider = FutureProvider.family<List<Review>, String>((ref, businessId) async {
  return ref.read(reviewsRepositoryProvider).listReviews(businessId);
});

