import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/isletme/domain/isletme_detay.dart';
import 'package:yeedoy/features/yorumlar/domain/yorum_katalogu.dart';

void main() {
  test('review catalog only serializes selected criteria', () {
    final payload = ReviewCatalog.buildRpcParams({
      ReviewRatingCriterion.taste: 5,
      ReviewRatingCriterion.serviceSpeed: null,
      ReviewRatingCriterion.pricePerformance: 4,
      ReviewRatingCriterion.cleanliness: null,
      ReviewRatingCriterion.atmosphere: 3,
    });

    expect(payload, {
      'p_taste_rating': 5,
      'p_price_performance_rating': 4,
      'p_atmosphere_rating': 3,
    });
  });

  test('business detail falls back to legacy overall stats when summary is absent', () {
    final detail = BusinessDetail.fromJson({
      'stats': {
        'id': 'business-1',
        'name': 'Yeedoy Bistro',
        'avg_rating': 4.4,
        'reviews_count': 18,
      },
      'rating_breakdown': const <String, dynamic>{},
      'latest_reviews': const <Map<String, dynamic>>[],
    });

    expect(detail.stats.id, 'business-1');
    expect(detail.stats.reviewsCount, 18);
    expect(detail.stats.avgRating, 4.4);
    expect(detail.breakdown.total, 0);
  });
}


