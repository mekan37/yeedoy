class ProfileProgress {
  const ProfileProgress({
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
    required this.nextLevelXp,
    required this.unlockedCount,
  });

  final int totalXp;
  final int level;
  final int xpInLevel;
  final int nextLevelXp;
  final int unlockedCount;

  factory ProfileProgress.fromMap(Map<String, dynamic> map) {
    return ProfileProgress(
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      xpInLevel: (map['xp_in_level'] as num?)?.toInt() ?? 0,
      nextLevelXp: (map['next_level_xp'] as num?)?.toInt() ?? 100,
      unlockedCount: (map['unlocked_count'] as num?)?.toInt() ?? 0,
    );
  }
}
