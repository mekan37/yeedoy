class YemekGunluguKaydi {
  final String visitId;
  final String businessId;
  final String businessName;
  final String? businessSlug;
  final String city;
  final String category;
  final DateTime checkedInAt;
  final int? amountCents;
  final String currency;
  final String? personalNote;
  final int? personalRating;

  const YemekGunluguKaydi({
    required this.visitId,
    required this.businessId,
    required this.businessName,
    this.businessSlug,
    required this.city,
    required this.category,
    required this.checkedInAt,
    this.amountCents,
    required this.currency,
    this.personalNote,
    this.personalRating,
  });

  factory YemekGunluguKaydi.fromMap(Map<String, dynamic> m) {
    return YemekGunluguKaydi(
      visitId: m['visit_id'] ?? '',
      businessId: m['business_id'] ?? '',
      businessName: m['business_name'] ?? '',
      businessSlug: m['business_slug'] as String?,
      city: m['city'] ?? '',
      category: m['category'] ?? '',
      checkedInAt: DateTime.parse(
        m['checked_in_at'] ?? DateTime.now().toIso8601String(),
      ),
      amountCents: m['amount_cents'] as int?,
      currency: m['currency'] ?? 'TRY',
      personalNote: m['personal_note'] as String?,
      personalRating: m['personal_rating'] as int?,
    );
  }

  YemekGunluguKaydi copyWith({
    int? amountCents,
    String? personalNote,
    int? personalRating,
  }) {
    return YemekGunluguKaydi(
      visitId: visitId,
      businessId: businessId,
      businessName: businessName,
      businessSlug: businessSlug,
      city: city,
      category: category,
      checkedInAt: checkedInAt,
      amountCents: amountCents ?? this.amountCents,
      currency: currency,
      personalNote: personalNote ?? this.personalNote,
      personalRating: personalRating ?? this.personalRating,
    );
  }
}
