/// 14 EU-mandated allergens (TR names + icon asset mapping).
enum AllergenType {
  gluten,
  crustaceans,
  egg,
  fish,
  peanuts,
  soy,
  milk,
  treenuts,
  celery,
  mustard,
  sesame,
  sulfurDioxide,
  lupin,
  molluscs;

  String get code => switch (this) {
        gluten => 'gluten',
        crustaceans => 'crustaceans',
        egg => 'egg',
        fish => 'fish',
        peanuts => 'peanuts',
        soy => 'soy',
        milk => 'milk',
        treenuts => 'treenuts',
        celery => 'celery',
        mustard => 'mustard',
        sesame => 'sesame',
        sulfurDioxide => 'sulfur_dioxide',
        lupin => 'lupin',
        molluscs => 'molluscs',
      };

  String get trName => switch (this) {
        gluten => 'Gluten',
        crustaceans => 'Kabuklu Deniz Ürünleri',
        egg => 'Yumurta',
        fish => 'Balık',
        peanuts => 'Yer Fıstığı',
        soy => 'Soya',
        milk => 'Süt',
        treenuts => 'Sert Kabuklu Yemişler',
        celery => 'Kereviz',
        mustard => 'Hardal',
        sesame => 'Susam',
        sulfurDioxide => 'Kükürt Dioksit',
        lupin => 'Acı Bakla',
        molluscs => 'Yumuşakçalar',
      };

  String get iconAsset => switch (this) {
        gluten => 'assets/alerjen/Gluten.png',
        crustaceans => 'assets/alerjen/Crustaceans.png',
        egg => 'assets/alerjen/egg.png',
        fish => 'assets/alerjen/Fish.png',
        peanuts => 'assets/alerjen/Peanuts.png',
        soy => 'assets/alerjen/Soyabeans.png',
        milk => 'assets/alerjen/milk.png',
        treenuts => 'assets/alerjen/Treenuts.png',
        celery => 'assets/alerjen/Celery.png',
        mustard => 'assets/alerjen/Mustard.png',
        sesame => 'assets/alerjen/Sesame.png',
        sulfurDioxide => 'assets/alerjen/So2.png',
        lupin => 'assets/alerjen/Lupin.png',
        molluscs => 'assets/alerjen/Molluscs.png',
      };

  static AllergenType? fromCode(String code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

enum AllergenRisk {
  contains,   // kesinlikle içeriyor
  mayContain; // içerebilir (çapraz bulaşma)

  String get code => switch (this) {
        contains => 'contains',
        mayContain => 'may_contain',
      };

  String get trLabel => switch (this) {
        contains => 'İçeriyor',
        mayContain => 'İçerebilir',
      };

  static AllergenRisk fromCode(String code) =>
      code == 'may_contain' ? mayContain : contains;
}

class MenuItemAllergen {
  const MenuItemAllergen({required this.type, required this.risk});

  final AllergenType type;
  final AllergenRisk risk;

  factory MenuItemAllergen.fromMap(Map<String, dynamic> m) =>
      MenuItemAllergen(
        type: AllergenType.fromCode(m['allergen'] as String? ?? '') ??
            AllergenType.gluten,
        risk: AllergenRisk.fromCode(m['risk_level'] as String? ?? 'contains'),
      );

  Map<String, dynamic> toMap() => {
        'allergen': type.code,
        'risk_level': risk.code,
      };
}
