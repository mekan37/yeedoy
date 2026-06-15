class MenuItemSearchResult {
  MenuItemSearchResult({
    required this.menuItemId,
    required this.menuId,
    required this.businessId,
    required this.name,
    required this.businessName,
    this.distanceKm,
    this.priceCents,
    this.priceStatus = 'unknown',
    this.total30d,
    this.calories,
    this.district,
    this.city,
    this.isVegan = false,
    this.isVegetarian = false,
    this.isGlutenFree = false,
    this.isLactoseFree = false,
    this.description,
    this.imageUrl,
    this.isTodaySpecial = false,
    this.specialNote,
  });

  final String menuItemId;
  final String menuId;
  final String businessId;
  final String name;
  final String businessName;
  final String? description;
  final String? imageUrl;
  final bool isTodaySpecial;
  final String? specialNote;
  final double? distanceKm;
  final int? priceCents;
  final String priceStatus;
  final int? total30d;
  final int? calories;
  final String? district;
  final String? city;
  final bool isVegan;
  final bool isVegetarian;
  final bool isGlutenFree;
  final bool isLactoseFree;

  factory MenuItemSearchResult.fromMap(Map<String, dynamic> map) {
    return MenuItemSearchResult(
      menuItemId: _asString(map, ['menu_item_id', 'item_id', 'id']) ?? '',
      menuId: _asString(map, ['menu_id', 'menuId']) ?? '',
      businessId: _asString(map, ['business_id', 'businessId']) ?? '',
      name: _asString(map, ['item_name', 'name', 'title']) ?? 'Ürün',
      businessName: _asString(map, ['business_name', 'place_name', 'business']) ?? 'İşletme',
      distanceKm: _asDouble(map, ['distance_km', 'distanceKm', 'distance']),
      priceCents: _asInt(map, ['price_cents', 'priceCents', 'price']),
      priceStatus: _asString(map, ['price_status', 'status']) ?? 'unknown',
      total30d: _asInt(map, ['total_30d', 'total30d', 'votes_30d']),
      calories: _asInt(map, ['calories', 'kcal']),
      district: _asString(map, ['district', 'business_district']),
      city: _asString(map, ['city', 'business_city']),
      isVegan: _asBool(map, ['is_vegan', 'vegan']) ?? false,
      isVegetarian: _asBool(map, ['is_vegetarian', 'vegetarian']) ?? false,
      isGlutenFree: _asBool(map, ['is_gluten_free', 'gluten_free']) ?? false,
      isLactoseFree: _asBool(map, ['is_lactose_free', 'lactose_free']) ?? false,
      description: _asString(map, ['item_description', 'description']),
      imageUrl: _asString(map, ['image_url', 'imageUrl']),
      isTodaySpecial: _asBool(map, ['is_today_special', 'isTodaySpecial']) ?? false,
      specialNote: _asString(map, ['special_note', 'specialNote']),
    );
  }
}

String? _asString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

int? _asInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double? _asDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '.');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool? _asBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }
  return null;
}



