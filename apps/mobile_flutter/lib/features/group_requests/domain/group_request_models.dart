class GroupRequest {
  GroupRequest({
    required this.id,
    required this.createdBy,
    required this.city,
    required this.districts,
    required this.category,
    required this.dateTime,
    required this.partySize,
    required this.budgetTotalCents,
    required this.currency,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String createdBy;
  final String city;
  final List<String> districts;
  final String? category;
  final DateTime dateTime;
  final int partySize;
  final int budgetTotalCents;
  final String currency;
  final String? notes;
  final String status;
  final DateTime createdAt;

  factory GroupRequest.fromMap(Map<String, dynamic> map) {
    return GroupRequest(
      id: (map['id'] ?? '').toString(),
      createdBy: (map['created_by'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      districts: _asStringList(map['districts']),
      category: _asString(map['category']),
      dateTime: _asDate(map['date_time']),
      partySize: _asInt(map['party_size']),
      budgetTotalCents: _asInt(map['budget_total_cents']),
      currency: (map['currency'] ?? 'TRY').toString(),
      notes: _asString(map['notes']),
      status: (map['status'] ?? 'open').toString(),
      createdAt: _asDate(map['created_at']),
    );
  }
}

class GroupOffer {
  GroupOffer({
    required this.id,
    required this.requestId,
    required this.businessId,
    required this.offeredTotalCents,
    required this.includes,
    required this.message,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.votesCount = 0,
    this.myVote,
  });

  final String id;
  final String requestId;
  final String businessId;
  final int offeredTotalCents;
  final Map<String, dynamic> includes;
  final String? message;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final int votesCount;
  final int? myVote;

  factory GroupOffer.fromMap(Map<String, dynamic> map) {
    return GroupOffer(
      id: (map['id'] ?? '').toString(),
      requestId: (map['request_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      offeredTotalCents: _asInt(map['offered_total_cents']),
      includes: (map['includes'] as Map?)?.cast<String, dynamic>() ?? const {},
      message: _asString(map['message']),
      status: (map['status'] ?? 'submitted').toString(),
      createdBy: (map['created_by'] ?? '').toString(),
      createdAt: _asDate(map['created_at']),
      votesCount: _asInt(map['votes_count'] ?? map['votes'] ?? 0),
      myVote: _asIntOrNull(map['my_vote']),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String? _asString(dynamic v) {
  if (v == null) return null;
  final text = v.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime _asDate(dynamic v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
