class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorHex,
    required this.xp,
    required this.isHidden,
    required this.unlocked,
    required this.unlockedAt,
    required this.condition,
    required this.currentValue,
    required this.targetValue,
    required this.tier,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String colorHex;
  final int xp;
  final bool isHidden;
  final bool unlocked;
  final DateTime? unlockedAt;
  final Map<String, dynamic> condition;
  final int? currentValue;
  final int? targetValue;
  final String tier; // 'bronze' | 'silver' | 'gold' | 'special'

  factory Achievement.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString();
    const hiddenIds = {
      'silent_follower_20',
      'night_gourmet_5',
      'menu_archivist_1',
      'chance_hunter_10',
      'weekend_wanderer_8',
      'deep_menu_diver_30',
      'chance_hunter_3',
      'silent_quality_10',
    };
    final condition =
        (map['condition'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Achievement(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      icon: (map['icon'] ?? 'trophy').toString(),
      colorHex: (map['color'] ?? '#9CA3AF').toString(),
      xp: (map['xp'] as num?)?.toInt() ?? 20,
      isHidden: map['is_hidden'] == true || hiddenIds.contains(id),
      unlocked: map['unlocked'] == true,
      unlockedAt: DateTime.tryParse((map['unlocked_at'] ?? '').toString()),
      condition: condition,
      currentValue: (map['current_value'] as num?)?.toInt(),
      targetValue: (map['target_value'] as num?)?.toInt(),
      tier: (condition['tier'] as String?) ?? 'bronze',
    );
  }
}
