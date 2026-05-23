class MasaSiparisKalemi {
  final String menuItemId;
  final String name;
  final int priceCents;
  int adet;
  String? not;

  MasaSiparisKalemi({
    required this.menuItemId,
    required this.name,
    required this.priceCents,
    this.adet = 1,
    this.not,
  });

  MasaSiparisKalemi copyWith({int? adet, String? not}) {
    return MasaSiparisKalemi(
      menuItemId: menuItemId,
      name: name,
      priceCents: priceCents,
      adet: adet ?? this.adet,
      not: not ?? this.not,
    );
  }
}

class MasaSiparisiOzet {
  final String id;
  final String businessId;
  final String tableNo;
  final String status;
  final DateTime createdAt;

  MasaSiparisiOzet({
    required this.id,
    required this.businessId,
    required this.tableNo,
    required this.status,
    required this.createdAt,
  });

  factory MasaSiparisiOzet.fromMap(Map<String, dynamic> m) {
    return MasaSiparisiOzet(
      id: (m['id'] ?? '').toString(),
      businessId: (m['business_id'] ?? '').toString(),
      tableNo: (m['table_no'] ?? '').toString(),
      status: (m['status'] ?? 'bekliyor').toString(),
      createdAt: _asDate(m['created_at']),
    );
  }
}

DateTime _asDate(Object? v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}
