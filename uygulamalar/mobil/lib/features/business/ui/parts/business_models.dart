part of '../business_page.dart';

class _MenuItemVariant {
  const _MenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.label,
    required this.priceCents,
    required this.currency,
    required this.isDefault,
    required this.sortOrder,
  });

  final String id;
  final String menuItemId;
  final String label;
  final int priceCents;
  final String currency;
  final bool isDefault;
  final int sortOrder;

  factory _MenuItemVariant.fromMap(Map<String, dynamic> map) {
    return _MenuItemVariant(
      id: (map['id'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      priceCents: ((map['price_cents'] as num?) ?? 0).toInt(),
      currency: (map['currency'] ?? 'TRY').toString(),
      isDefault: map['is_default'] == true,
      sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
    );
  }
}

class _BusinessTrustSnapshot {
  const _BusinessTrustSnapshot({
    required this.menuUpdatedAt,
    required this.menuVersion,
    required this.menuSource,
    required this.menuConfidenceScore,
    required this.lastPriceVerifiedAt,
    required this.lastPriceVerifiedPeople,
    required this.trustScore,
    required this.priceChanges3m,
  });

  final DateTime? menuUpdatedAt;
  final int menuVersion;
  final String menuSource;
  final double menuConfidenceScore;
  final DateTime? lastPriceVerifiedAt;
  final int lastPriceVerifiedPeople;
  final int trustScore;
  final List<int> priceChanges3m;
}
