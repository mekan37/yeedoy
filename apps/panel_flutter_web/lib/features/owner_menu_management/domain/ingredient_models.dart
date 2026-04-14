enum IngredientConfidence {
  certain,
  likely,
  uncertain;

  String get code => name;

  String get trLabel => switch (this) {
        certain => 'Kesin',
        likely => 'Muhtemelen',
        uncertain => 'Belirsiz',
      };

  static IngredientConfidence fromCode(String code) =>
      switch (code) {
        'likely' => likely,
        'uncertain' => uncertain,
        _ => certain,
      };
}

enum IngredientCategory {
  meat,
  poultry,
  seafood,
  dairy,
  egg,
  vegetable,
  fruit,
  grain,
  legume,
  fatOil,
  spice,
  sauce,
  nut,
  other;

  String get code => switch (this) {
        fatOil => 'fat_oil',
        _ => name,
      };

  String get trName => switch (this) {
        meat => 'Et',
        poultry => 'Kümes Hayvanı',
        seafood => 'Deniz Ürünü',
        dairy => 'Süt Ürünü',
        egg => 'Yumurta',
        vegetable => 'Sebze',
        fruit => 'Meyve',
        grain => 'Tahıl',
        legume => 'Baklagil',
        fatOil => 'Yağ',
        spice => 'Baharat',
        sauce => 'Sos',
        nut => 'Kuruyemiş',
        other => 'Diğer',
      };

  static IngredientCategory fromCode(String code) {
    if (code == 'fat_oil') return fatOil;
    for (final v in values) {
      if (v.name == code) return v;
    }
    return other;
  }
}

class MenuItemIngredient {
  const MenuItemIngredient({
    required this.name,
    required this.confidence,
    required this.category,
  });

  final String name;
  final IngredientConfidence confidence;
  final IngredientCategory category;

  factory MenuItemIngredient.fromMap(Map<String, dynamic> m) =>
      MenuItemIngredient(
        name: m['name'] as String? ?? '',
        confidence: IngredientConfidence.fromCode(
            m['confidence'] as String? ?? 'certain'),
        category: IngredientCategory.fromCode(
            m['category'] as String? ?? 'other'),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'confidence': confidence.code,
        'category': category.code,
      };
}

class MenuItemDietTags {
  const MenuItemDietTags({
    this.isVegan,
    this.isVegetarian,
    this.isGlutenFree,
    this.isDairyFree,
    this.detectedBy = 'ai',
  });

  final bool? isVegan;
  final bool? isVegetarian;
  final bool? isGlutenFree;
  final bool? isDairyFree;
  final String detectedBy;

  factory MenuItemDietTags.fromMap(Map<String, dynamic> m) =>
      MenuItemDietTags(
        isVegan: m['is_vegan'] as bool?,
        isVegetarian: m['is_vegetarian'] as bool?,
        isGlutenFree: m['is_gluten_free'] as bool?,
        isDairyFree: m['is_dairy_free'] as bool?,
        detectedBy: m['detected_by'] as String? ?? 'ai',
      );

  Map<String, dynamic> toDietMap() => {
        'is_vegan': isVegan,
        'is_vegetarian': isVegetarian,
        'is_gluten_free': isGlutenFree,
        'is_dairy_free': isDairyFree,
      };
}

class MenuItemIngredientData {
  const MenuItemIngredientData({
    required this.ingredients,
    required this.diet,
  });

  final List<MenuItemIngredient> ingredients;
  final MenuItemDietTags? diet;
}
