class OwnerSuspendedClaimItem {
  OwnerSuspendedClaimItem({
    required this.id,
    required this.status,
    required this.claimantName,
    required this.amountCents,
    required this.currency,
    required this.mealMessage,
    required this.createdAt,
    required this.ageHours,
  });

  final String id;
  final String status;
  final String claimantName;
  final int amountCents;
  final String currency;
  final String mealMessage;
  final DateTime createdAt;
  final double ageHours;

  factory OwnerSuspendedClaimItem.fromMap(Map<String, dynamic> m) {
    final createdAt = _asDate(m['created_at']);
    final ageHours = _asDoubleNullable(m['age_hours']) ?? _ageHours(createdAt);
    return OwnerSuspendedClaimItem(
      id: (m['claim_id'] ?? m['id'] ?? '').toString(),
      status: (m['status'] ?? 'pending').toString(),
      claimantName: (m['claimant_name'] ?? m['name'] ?? '').toString(),
      amountCents: _asInt(m['amount_cents']),
      currency: (m['currency'] ?? 'TRY').toString(),
      mealMessage: (m['meal_message'] ?? m['message'] ?? '').toString(),
      createdAt: createdAt,
      ageHours: ageHours,
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

double? _asDoubleNullable(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

double _ageHours(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  return diff.inMinutes / 60.0;
}
