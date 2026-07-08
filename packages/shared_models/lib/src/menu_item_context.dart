class MenuItemContext {
  MenuItemContext({
    required this.ok,
    required this.menuId,
    required this.businessId,
    this.allergens = const [],
    this.caloriesMin,
    this.portionSize,
    this.ingredients = const [],
  });

  final bool ok;
  final String menuId;
  final String businessId;
  final List<String> allergens;

  /// Kalori değeri (kcal). Girilmemişse null.
  final int? caloriesMin;

  /// Porsiyon miktarı ve birimi birleşik olarak, örn. "350 g". Girilmemişse null.
  final String? portionSize;

  /// Malzeme isimleri listesi. Boş liste girilmemişi temsil eder.
  final List<String> ingredients;

  factory MenuItemContext.fromMap(Map<String, dynamic> map) {
    return MenuItemContext(
      ok: _asBool(map, ['ok']) ?? false,
      menuId: _asString(map, ['menu_id', 'menuId']) ?? '',
      businessId: _asString(map, ['business_id', 'businessId']) ?? '',
      allergens: (map['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      caloriesMin: map['calories_min'] as int?,
      portionSize: _asString(map, ['portion_size']),
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  MenuItemContext copyWith({
    bool? ok,
    String? menuId,
    String? businessId,
    List<String>? allergens,
    int? caloriesMin,
    String? portionSize,
    List<String>? ingredients,
  }) {
    return MenuItemContext(
      ok: ok ?? this.ok,
      menuId: menuId ?? this.menuId,
      businessId: businessId ?? this.businessId,
      allergens: allergens ?? this.allergens,
      caloriesMin: caloriesMin ?? this.caloriesMin,
      portionSize: portionSize ?? this.portionSize,
      ingredients: ingredients ?? this.ingredients,
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
