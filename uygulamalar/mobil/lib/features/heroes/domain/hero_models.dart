class HeroEntry {
  HeroEntry({
    required this.userId,
    required this.donatedCount,
    required this.totalCents,
    required this.currency,
    this.displayName = '',
    this.avatarUrl = '',
  });

  final String userId;
  final int donatedCount;
  final int totalCents;
  final String currency;
  final String displayName;
  final String avatarUrl;

  factory HeroEntry.fromMap(Map<String, dynamic> map) {
    return HeroEntry(
      userId: (map['user_id'] ?? '').toString(),
      donatedCount: (map['donated_count'] as num?)?.toInt() ?? 0,
      totalCents:
          (map['total_cents'] as num?)?.toInt() ??
          (map['total_amount_cents'] as num?)?.toInt() ??
          (map['donated_amount_cents'] as num?)?.toInt() ??
          0,
      currency: (map['currency'] ?? 'TRY').toString(),
      displayName: (map['display_name'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? '').toString(),
    );
  }
}

/// Weekly top-contributor leaderboard entry.
/// Powered by get_weekly_contributor_leaderboard_v1().
class WeeklyLeaderboardEntry {
  WeeklyLeaderboardEntry({
    required this.userId,
    required this.verifyCount,
    required this.reviewCount,
    required this.photoCount,
    required this.weeklyScore,
    this.displayName = '',
    this.avatarUrl = '',
  });

  final String userId;
  final int verifyCount;
  final int reviewCount;
  final int photoCount;
  final int weeklyScore;
  final String displayName;
  final String avatarUrl;

  factory WeeklyLeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return WeeklyLeaderboardEntry(
      userId: (map['user_id'] ?? '').toString(),
      verifyCount: (map['verify_count'] as num?)?.toInt() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      photoCount: (map['photo_count'] as num?)?.toInt() ?? 0,
      weeklyScore: (map['weekly_score'] as num?)?.toInt() ?? 0,
      displayName: (map['display_name'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? '').toString(),
    );
  }
}
