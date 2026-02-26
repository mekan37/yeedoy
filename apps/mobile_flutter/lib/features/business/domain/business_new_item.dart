class BusinessNewItem {
  BusinessNewItem({
    required this.menuItemId,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.createdAt,
  });

  final String menuItemId;
  final String name;
  final int? priceCents;
  final String currency;
  final DateTime createdAt;

  factory BusinessNewItem.fromMap(Map<String, dynamic> map) {
    return BusinessNewItem(
      menuItemId: (map['menu_item_id'] ?? map['id'] ?? '').toString(),
      name: (map['item_name'] ?? map['name'] ?? '').toString(),
      priceCents: map['price_cents'] as int?,
      currency: (map['currency'] ?? 'TRY').toString(),
      createdAt: DateTime.parse((map['created_at'] ?? DateTime.now().toIso8601String()).toString()),
    );
  }
}
