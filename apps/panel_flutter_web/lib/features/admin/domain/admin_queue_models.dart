class AdminQueuePageResult {
  const AdminQueuePageResult({
    required this.items,
    required this.totalCount,
  });

  final List<AdminQueueItem> items;
  final int totalCount;
}

enum AdminQueueItemType {
  businessSubmission,
  report,
  priceSuggestion,
  claim,
  mediaFlag;

  String get wireValue => switch (this) {
    AdminQueueItemType.businessSubmission => 'business_submission',
    AdminQueueItemType.report => 'report',
    AdminQueueItemType.priceSuggestion => 'price_suggestion',
    AdminQueueItemType.claim => 'claim',
    AdminQueueItemType.mediaFlag => 'media_flag',
  };

  static AdminQueueItemType fromWire(String value) => switch (value) {
    'business_submission' => AdminQueueItemType.businessSubmission,
    'price_suggestion' => AdminQueueItemType.priceSuggestion,
    'claim' => AdminQueueItemType.claim,
    'media_flag' => AdminQueueItemType.mediaFlag,
    _ => AdminQueueItemType.report,
  };
}

class AdminQueueItem {
  const AdminQueueItem({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.ageHours,
    required this.slaHours,
    required this.slaBreached,
    required this.title,
    required this.subtitle,
    this.city,
    this.district,
    this.businessId,
    this.businessName,
    this.assignedTo,
    this.assignedAt,
    required this.detail,
    required this.totalCount,
  });

  final String id;
  final AdminQueueItemType type;
  final String status;
  final DateTime createdAt;
  final double ageHours;
  final int slaHours;
  final bool slaBreached;
  final String title;
  final String subtitle;
  final String? city;
  final String? district;
  final String? businessId;
  final String? businessName;
  final String? assignedTo;
  final DateTime? assignedAt;
  final Map<String, dynamic> detail;
  final int totalCount;

  factory AdminQueueItem.fromMap(Map<String, dynamic> map) {
    return AdminQueueItem(
      id: (map['id'] ?? '').toString(),
      type: AdminQueueItemType.fromWire((map['item_type'] ?? '').toString()),
      status: (map['status'] ?? '').toString(),
      createdAt: _asDate(map['created_at']),
      ageHours: _asDouble(map['age_hours']),
      slaHours: _asInt(map['sla_hours']),
      slaBreached: _asBool(map['sla_breached']),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      city: _nullableString(map['city']),
      district: _nullableString(map['district']),
      businessId: _nullableString(map['business_id']),
      businessName: _nullableString(map['business_name']),
      assignedTo: _nullableString(map['assigned_to']),
      assignedAt: _asDateNullable(map['assigned_at']),
      detail: (map['detail'] as Map?)?.cast<String, dynamic>() ?? const {},
      totalCount: _asInt(map['total_count']),
    );
  }

  bool get canApprove => switch (type) {
    AdminQueueItemType.businessSubmission => status == 'new',
    AdminQueueItemType.priceSuggestion => status == 'pending',
    AdminQueueItemType.claim => status == 'pending',
    AdminQueueItemType.report => false,
    AdminQueueItemType.mediaFlag => false,
  };

  bool get canReject => canApprove;
}

DateTime _asDate(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse((value ?? '').toString()) ?? DateTime.now();
}

DateTime? _asDateNullable(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final raw = (value ?? '').toString().toLowerCase();
  return raw == 'true' || raw == '1';
}

String? _nullableString(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}
