class MySuspendedClaimItem {
  MySuspendedClaimItem({
    required this.id,
    required this.status,
    required this.businessName,
    required this.district,
    required this.city,
    required this.amountCents,
    required this.currency,
    required this.createdAt,
    this.fulfilledAt,
    this.verifyCode,
  });

  final String id;
  final String status;
  final String businessName;
  final String district;
  final String city;
  final int amountCents;
  final String currency;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final String? verifyCode;

  factory MySuspendedClaimItem.fromMap(Map<String, dynamic> map) {
    return MySuspendedClaimItem(
      id: (map['claim_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      amountCents: _asInt(map['amount_cents']),
      currency: (map['currency'] ?? 'TRY').toString(),
      createdAt: _asDate(map['created_at']),
      fulfilledAt: _asDateNullable(map['fulfilled_at']),
      verifyCode: _asStringNullable(map['verify_code']),
    );
  }
}

class MySuspendedBadge {
  MySuspendedBadge({required this.approvedCount});
  final int approvedCount;

  factory MySuspendedBadge.fromMap(Map<String, dynamic> map) {
    return MySuspendedBadge(
      approvedCount: _asInt(map['approved_count']),
    );
  }
}

int _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

DateTime _asDate(Object? v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}

DateTime? _asDateNullable(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

String? _asStringNullable(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
