class BusinessTrendingItem {
  BusinessTrendingItem({
    required this.menuItemId,
    required this.itemName,
    required this.priceCents,
    required this.currency,
    required this.score,
    this.imageUrl,
  });

  final String menuItemId;
  final String itemName;
  final int priceCents;
  final String currency;
  final int score;
  final String? imageUrl;

  factory BusinessTrendingItem.fromMap(Map<String, dynamic> map) {
    return BusinessTrendingItem(
      menuItemId: map['menu_item_id']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
      currency: map['currency']?.toString() ?? 'TRY',
      score: (map['score'] as num?)?.toInt() ?? 0,
      imageUrl: _firstNonEmptyString(map, const [
        'image_url',
        'photo_url',
        'thumb_url',
        'thumbnail_url',
        'cover_url',
      ]),
    );
  }
}

String? _firstNonEmptyString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final raw = map[key];
    if (raw == null) continue;
    final value = raw.toString().trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}
