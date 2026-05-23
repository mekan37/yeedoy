class DietProfile {
  DietProfile({
    required this.vegan,
    required this.vegetarian,
    required this.glutenFree,
    required this.lactoseFree,
    required this.halal,
    this.maxCalories,
  });

  final bool vegan;
  final bool vegetarian;
  final bool glutenFree;
  final bool lactoseFree;
  final bool halal;
  final int? maxCalories;

  factory DietProfile.fromMap(Map<String, dynamic> map) {
    return DietProfile(
      vegan: _asBool(map, ['vegan', 'is_vegan']) ?? false,
      vegetarian: _asBool(map, ['vegetarian', 'is_vegetarian']) ?? false,
      glutenFree: _asBool(map, ['gluten_free', 'is_gluten_free']) ?? false,
      lactoseFree: _asBool(map, ['lactose_free', 'is_lactose_free']) ?? false,
      halal: _asBool(map, ['halal', 'is_halal']) ?? false,
      maxCalories: _asInt(map, ['max_calories', 'maxCalories']),
    );
  }

  DietProfile copyWith({
    bool? vegan,
    bool? vegetarian,
    bool? glutenFree,
    bool? lactoseFree,
    bool? halal,
    int? maxCalories,
  }) {
    return DietProfile(
      vegan: vegan ?? this.vegan,
      vegetarian: vegetarian ?? this.vegetarian,
      glutenFree: glutenFree ?? this.glutenFree,
      lactoseFree: lactoseFree ?? this.lactoseFree,
      halal: halal ?? this.halal,
      maxCalories: maxCalories ?? this.maxCalories,
    );
  }
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
