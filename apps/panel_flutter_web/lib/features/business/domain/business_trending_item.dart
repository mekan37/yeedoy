class BusinessTrendingItem {
  BusinessTrendingItem({
    required this.menuItemId,
    required this.itemName,
    required this.priceCents,
    required this.currency,
    required this.score,
  });

  final String menuItemId;
  final String itemName;
  final int priceCents;
  final String currency;
  final int score;

  factory BusinessTrendingItem.fromMap(Map<String, dynamic> map) {
    return BusinessTrendingItem(
      menuItemId: map['menu_item_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
      currency: map['currency']?.toString() ?? 'TRY',
      score: (map['score'] as num?)?.toInt() ?? 0,
    );
  }
}
