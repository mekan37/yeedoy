class BusinessBadge {
  const BusinessBadge({
    required this.id,
    required this.title,
    required this.color,
    required this.tier,
  });

  final String id;
  final String title;
  final String color;
  final String tier;

  factory BusinessBadge.fromMap(Map<String, dynamic> map) => BusinessBadge(
    id: (map['badge_id'] ?? '').toString(),
    title: (map['title'] ?? '').toString(),
    color: (map['color'] ?? '#9CA3AF').toString(),
    tier: (map['tier'] ?? 'bronze').toString(),
  );
}
