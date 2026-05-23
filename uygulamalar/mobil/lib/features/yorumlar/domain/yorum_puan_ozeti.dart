import 'yorum_katalogu.dart';

class ReviewRatingSummary {
  const ReviewRatingSummary({
    required this.ratingCount,
    required this.avgOverallRating,
    required this.criteriaAverages,
    this.rating5 = 0,
    this.rating4 = 0,
    this.rating3 = 0,
    this.rating2 = 0,
    this.rating1 = 0,
  });

  final int ratingCount;
  final double? avgOverallRating;
  final Map<ReviewRatingCriterion, double?> criteriaAverages;

  /// Per-star counts from business_stats (0 when unavailable).
  final int rating5;
  final int rating4;
  final int rating3;
  final int rating2;
  final int rating1;

  bool get hasCriteriaAverages =>
      criteriaAverages.values.any((v) => v != null);

  bool get hasDistribution =>
      rating5 + rating4 + rating3 + rating2 + rating1 > 0;

  /// Returns star counts in descending order [5,4,3,2,1].
  List<int> get distributionDesc =>
      [rating5, rating4, rating3, rating2, rating1];

  factory ReviewRatingSummary.fromMap(Map<String, dynamic> m) {
    return ReviewRatingSummary(
      ratingCount: (m['rating_count'] as int?) ?? 0,
      avgOverallRating: _asDouble(m['avg_overall_rating']),
      criteriaAverages: ReviewCatalog.parseSummaryAverages(m),
      rating5: (m['rating_5'] as int?) ?? 0,
      rating4: (m['rating_4'] as int?) ?? 0,
      rating3: (m['rating_3'] as int?) ?? 0,
      rating2: (m['rating_2'] as int?) ?? 0,
      rating1: (m['rating_1'] as int?) ?? 0,
    );
  }

  factory ReviewRatingSummary.empty() => ReviewRatingSummary(
        ratingCount: 0,
        avgOverallRating: null,
        criteriaAverages: ReviewCatalog.emptyAverageSelection(),
      );

  static double? _asDouble(Object? v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString());
  }
}

