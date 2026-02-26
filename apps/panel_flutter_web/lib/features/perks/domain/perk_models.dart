class BusinessPerk {
  BusinessPerk({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    this.startsAt,
    this.endsAt,
    required this.requiresCheckin,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String title;
  final String? description;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool requiresCheckin;
  final String status;
  final DateTime createdAt;

  factory BusinessPerk.fromMap(Map<String, dynamic> map) {
    return BusinessPerk(
      id: (map['id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString().trim().isEmpty
          ? null
          : (map['description'] ?? '').toString(),
      startsAt: _asDate(map['starts_at']),
      endsAt: _asDate(map['ends_at']),
      requiresCheckin: map['requires_checkin'] == true,
      status: (map['status'] ?? 'active').toString(),
      createdAt: _asDate(map['created_at']) ?? DateTime.now(),
    );
  }
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
