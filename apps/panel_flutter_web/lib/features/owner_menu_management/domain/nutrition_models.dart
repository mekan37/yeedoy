class MenuItemNutrition {
  const MenuItemNutrition({
    required this.calorieMin,
    required this.calorieMax,
    required this.proteinMinG,
    required this.proteinMaxG,
    required this.fatMinG,
    required this.fatMaxG,
    required this.carbsMinG,
    required this.carbsMaxG,
    required this.servingEstG,
    required this.source,
  });

  final int calorieMin;
  final int calorieMax;
  final double proteinMinG;
  final double proteinMaxG;
  final double fatMinG;
  final double fatMaxG;
  final double carbsMinG;
  final double carbsMaxG;
  final int servingEstG;
  final String source;

  factory MenuItemNutrition.fromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num? ?? 0).toDouble();
    int i(String k) => (m[k] as num? ?? 0).toInt();
    return MenuItemNutrition(
      calorieMin: i('calorie_min'),
      calorieMax: i('calorie_max'),
      proteinMinG: d('protein_min_g'),
      proteinMaxG: d('protein_max_g'),
      fatMinG: d('fat_min_g'),
      fatMaxG: d('fat_max_g'),
      carbsMinG: d('carbs_min_g'),
      carbsMaxG: d('carbs_max_g'),
      servingEstG: i('serving_est_g'),
      source: (m['source'] ?? 'ai_estimated').toString(),
    );
  }
}
