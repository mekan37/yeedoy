class BudgetComboQuery {
  const BudgetComboQuery({
    required this.city,
    required this.district,
    required this.partySize,
    required this.budgetTotalCents,
    this.category,
    this.limit = 30,
  });

  final String city;
  final String district;
  final int partySize;
  final int budgetTotalCents;
  final String? category;
  final int limit;
}

class BudgetComboItem {
  const BudgetComboItem({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.currency,
  });

  final String id;
  final String name;
  final int priceCents;
  final String currency;

  factory BudgetComboItem.fromMap(Map<String, dynamic> map) {
    return BudgetComboItem(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      priceCents: (map['price_cents'] ?? 0) as int,
      currency: (map['currency'] ?? 'TRY').toString(),
    );
  }
}

class BudgetCombo {
  const BudgetCombo({
    required this.main,
    this.drink,
  });

  final BudgetComboItem main;
  final BudgetComboItem? drink;

  factory BudgetCombo.fromMap(Map<String, dynamic> map) {
    final mainMap = (map['main'] as Map?)?.cast<String, dynamic>() ?? const {};
    final drinkMap = (map['drink'] as Map?)?.cast<String, dynamic>();
    return BudgetCombo(
      main: BudgetComboItem.fromMap(mainMap),
      drink: drinkMap == null ? null : BudgetComboItem.fromMap(drinkMap.cast<String, dynamic>()),
    );
  }
}

class BudgetComboResult {
  const BudgetComboResult({
    required this.businessId,
    required this.businessName,
    required this.combo,
    required this.totalCents,
    this.distanceKm,
    this.rating,
  });

  final String businessId;
  final String businessName;
  final BudgetCombo combo;
  final int totalCents;
  final double? distanceKm;
  final double? rating;

  factory BudgetComboResult.fromMap(Map<String, dynamic> map) {
    final comboMap = (map['combo'] as Map?)?.cast<String, dynamic>() ?? const {};
    final distanceRaw = map['distance_km'] ?? map['distanceKm'];
    final ratingRaw = map['rating'] ?? map['score'];
    return BudgetComboResult(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      combo: BudgetCombo.fromMap(comboMap),
      totalCents: (map['total_cents'] ?? 0) as int,
      distanceKm: _asDouble(distanceRaw),
      rating: _asDouble(ratingRaw),
    );
  }
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
  return parsed;
}
