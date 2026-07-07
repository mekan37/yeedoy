import 'review_catalog.dart';

class Review {
  Review({
    required this.id,
    required this.businessId,
    required this.rating,
    required this.content,
    this.title,
    required this.helpfulCount,
    required this.createdAt,
    this.userId,
    required this.status,
    this.qualityScore = 0,
    this.verifiedVisit = false,
    Map<ReviewRatingCriterion, int?>? criteriaRatings,
    this.authorBadgeId,
    this.authorBadgeTitle,
    this.authorBadgeColor,
    this.authorBadgeTier,
  }) : criteriaRatings = criteriaRatings ?? ReviewCatalog.emptySelection();

  final String id;
  final String businessId;
  final int rating;
  final String? title;
  final String content;
  final int helpfulCount;
  final DateTime createdAt;
  final String? userId;
  final String status;
  final double qualityScore;
  /// True when the reviewer checked in at this business on the same UTC day
  /// as writing the review. Computed server-side by _review_verified_visit().
  final bool verifiedVisit;
  final Map<ReviewRatingCriterion, int?> criteriaRatings;

  /// Author's highest XP badge fields (nullable — badge may not exist).
  final String? authorBadgeId;
  final String? authorBadgeTitle;
  final String? authorBadgeColor;
  final String? authorBadgeTier;

  bool get hasCriteriaRatings =>
      criteriaRatings.values.any((v) => v != null);

  /// Quality score threshold for showing the "Kaliteli Yorum" badge.
  static const double qualityBadgeThreshold = 0.75;

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    rating: m['rating'] as int,
    title: m['title'] as String?,
    content: m['content'] as String,
    helpfulCount: (m['helpful_count'] as int?) ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    userId: m['user_id'] as String?,
    status: m['status'] as String,
    qualityScore: (m['quality_score'] as num?)?.toDouble() ?? 0,
    verifiedVisit: (m['verified_visit'] as bool?) ?? false,
    criteriaRatings: ReviewCatalog.parseReviewRatings(m),
    authorBadgeId: m['author_badge_id'] as String?,
    authorBadgeTitle: m['author_badge_title'] as String?,
    authorBadgeColor: m['author_badge_color'] as String?,
    authorBadgeTier: m['author_badge_tier'] as String?,
  );
}
