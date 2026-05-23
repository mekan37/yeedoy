class PriceAlert {
  PriceAlert({
    required this.id,
    required this.query,
    required this.maxPriceCents,
    required this.currency,
    required this.city,
    required this.district,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String query;
  final int maxPriceCents;
  final String currency;
  final String? city;
  final String? district;
  final String? category;
  final bool isActive;
  final DateTime createdAt;

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      id: (map['id'] ?? '').toString(),
      query: (map['query'] ?? '').toString(),
      maxPriceCents: _asInt(map['max_price_cents']) ?? 0,
      currency: (map['currency'] ?? 'TRY').toString(),
      city: _asString(map['city']),
      district: _asString(map['district']),
      category: _asString(map['category']),
      isActive: map['is_active'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class AlertEvent {
  AlertEvent({
    required this.id,
    required this.alertId,
    required this.businessId,
    required this.menuItemId,
    required this.matchedPriceCents,
    required this.previousPriceCents,
    required this.districtAvgPriceCents,
    required this.createdAt,
  });

  final String id;
  final String alertId;
  final String businessId;
  final String? menuItemId;
  final int matchedPriceCents;
  final int? previousPriceCents;
  final int? districtAvgPriceCents;
  final DateTime createdAt;

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    return AlertEvent(
      id: (map['id'] ?? '').toString(),
      alertId: (map['alert_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      menuItemId: _asString(map['menu_item_id']),
      matchedPriceCents: _asInt(map['matched_price_cents']) ?? 0,
      previousPriceCents: _asInt(map['previous_price_cents']) ??
          _asInt(map['old_price_cents']),
      districtAvgPriceCents: _asInt(map['district_avg_price_cents']) ??
          _asInt(map['avg_price_cents']),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class AlertEventItem {
  AlertEventItem({
    required this.event,
    required this.businessName,
    required this.businessCity,
    required this.businessDistrict,
    required this.menuItemName,
    required this.alertQuery,
    required this.alertMaxPriceCents,
    required this.alertCity,
    required this.alertDistrict,
  });

  final AlertEvent event;
  final String businessName;
  final String? businessCity;
  final String? businessDistrict;
  final String? menuItemName;
  final String? alertQuery;
  final int? alertMaxPriceCents;
  final String? alertCity;
  final String? alertDistrict;
}

class AlertMeta {
  AlertMeta({
    required this.query,
    required this.maxPriceCents,
    required this.city,
    required this.district,
  });

  final String? query;
  final int? maxPriceCents;
  final String? city;
  final String? district;

  factory AlertMeta.fromMap(Map<String, dynamic> map) {
    return AlertMeta(
      query: _asString(map['query']),
      maxPriceCents: _asInt(map['max_price_cents']),
      city: _asString(map['city']),
      district: _asString(map['district']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
