class SuspendedMeal {
  SuspendedMeal({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.message,
    this.createdAt,
  });

  final String id;
  final int amountCents;
  final String currency;
  final String message;
  final DateTime? createdAt;

  factory SuspendedMeal.fromMap(Map<String, dynamic> map) {
    return SuspendedMeal(
      id: (map['id'] ?? map['meal_id'] ?? '').toString(),
      amountCents: (map['amount_cents'] as num?)?.toInt() ??
          (map['amount'] as num?)?.toInt() ??
          0,
      currency: (map['currency'] ?? 'TRY').toString(),
      message: (map['message'] ?? map['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
