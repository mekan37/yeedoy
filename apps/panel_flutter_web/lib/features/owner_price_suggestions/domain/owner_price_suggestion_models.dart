class OwnerPriceSuggestionItem {
  OwnerPriceSuggestionItem({
    required this.id,
    required this.status,
    required this.menuItemId,
    required this.menuItemName,
    required this.currentPriceCents,
    required this.suggestedPriceCents,
    required this.createdAt,
    required this.ageHours,
    required this.qualityConfidence,
    required this.anomalyScore,
    required this.anomalyFlags,
    required this.conflictState,
    required this.conflictVariants24h,
  });

  final String id;
  final String status;
  final String menuItemId;
  final String menuItemName;
  final int currentPriceCents;
  final int suggestedPriceCents;
  final DateTime createdAt;
  final double ageHours;
  final double qualityConfidence;
  final double anomalyScore;
  final List<String> anomalyFlags;
  final String conflictState;
  final int conflictVariants24h;

  factory OwnerPriceSuggestionItem.fromMap(Map<String, dynamic> map) {
    final createdAt = _asDate(map['created_at']);
    final ageHours =
        _asDoubleNullable(map['age_hours']) ?? _ageHours(createdAt);
    return OwnerPriceSuggestionItem(
      id: (map['suggestion_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      menuItemName: (map['menu_item_name'] ?? map['item_name'] ?? '')
          .toString(),
      currentPriceCents: _asInt(map['current_price_cents']),
      suggestedPriceCents: _asInt(map['suggested_price_cents']),
      createdAt: createdAt,
      ageHours: ageHours,
      qualityConfidence: _asDoubleNullable(map['quality_confidence']) ?? 0,
      anomalyScore: _asDoubleNullable(map['anomaly_score']) ?? 0,
      anomalyFlags: _asStringList(map['anomaly_flags']),
      conflictState: (map['conflict_state'] ?? 'none').toString(),
      conflictVariants24h: _asInt(map['conflict_variants_24h']),
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

List<String> _asStringList(Object? raw) {
  if (raw is List) {
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  final text = (raw ?? '').toString().trim();
  if (text.isEmpty || text == '[]') return const [];
  return text
      .replaceAll('[', '')
      .replaceAll(']', '')
      .split(',')
      .map((e) => e.trim().replaceAll('"', ''))
      .where((e) => e.isNotEmpty)
      .toList();
}
