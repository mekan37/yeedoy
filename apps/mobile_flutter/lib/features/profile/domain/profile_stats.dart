class ProfileStats {
  ProfileStats({
    required this.reviewsCount,
    required this.helpfulReceived,
    required this.favoritesCount,
    required this.contributionScore,
    required this.visitsCount,
  });

  final int reviewsCount;
  final int helpfulReceived;
  final int favoritesCount;
  final int contributionScore;
  final int visitsCount;

  factory ProfileStats.fromMap(Map<String, dynamic> m) => ProfileStats(
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    helpfulReceived: (m['helpful_received'] as num?)?.toInt() ?? 0,
    favoritesCount: (m['favorites_count'] as num?)?.toInt() ?? 0,
    contributionScore: (m['contribution_score'] as num?)?.toInt() ?? 0,
    visitsCount: (m['visits_count'] as num?)?.toInt() ?? 0,
  );
}
