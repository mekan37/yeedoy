class BusinessActivityItem {
  BusinessActivityItem({
    required this.id,
    required this.type,
    required this.meta,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> meta;
  final DateTime createdAt;

  factory BusinessActivityItem.fromMap(Map<String, dynamic> m) => BusinessActivityItem(
        id: (m['activity_id'] ?? m['id'] ?? '').toString(),
        type: (m['activity_type'] ?? m['type'] ?? '').toString(),
        meta: (m['meta'] as Map?)?.cast<String, dynamic>() ?? {},
        createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
      );
}
