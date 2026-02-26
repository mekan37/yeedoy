class FoodCatalogHit {
  FoodCatalogHit({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryId,
  });

  final int id;
  final String name;
  final String categoryName;
  final String categoryId;

  factory FoodCatalogHit.fromMap(Map<String, dynamic> map) {
    return FoodCatalogHit(
      id: _asInt(map, ['id', 'catalog_item_id']) ?? 0,
      name: _asString(map, ['name', 'title']) ?? '?or?n',
      categoryName: _asString(map, ['category_name', 'category']) ?? '',
      categoryId: _asString(map, ['category_id', 'categoryId']) ?? '',
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



