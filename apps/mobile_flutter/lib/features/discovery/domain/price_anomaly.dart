class PriceAnomalyItem {
  const PriceAnomalyItem({
    required this.businessId,
    required this.businessName,
    required this.menuItemId,
    required this.menuItemName,
    required this.city,
    required this.district,
    required this.firstPriceCents,
    required this.lastPriceCents,
    required this.changePct,
    this.lastChangedAt,
  });

  final String businessId;
  final String businessName;
  final String menuItemId;
  final String menuItemName;
  final String city;
  final String district;
  final int firstPriceCents;
  final int lastPriceCents;
  final double changePct;
  final DateTime? lastChangedAt;

  factory PriceAnomalyItem.fromMap(Map<String, dynamic> map) {
    return PriceAnomalyItem(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      menuItemName: (map['menu_item_name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      firstPriceCents: ((map['first_price_cents'] as num?) ?? 0).toInt(),
      lastPriceCents: ((map['last_price_cents'] as num?) ?? 0).toInt(),
      changePct: ((map['change_pct'] as num?) ?? 0).toDouble(),
      lastChangedAt: DateTime.tryParse(
        (map['last_changed_at'] ?? '').toString(),
      ),
    );
  }
}
