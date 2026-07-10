class SmartRecoQuery {
  const SmartRecoQuery({
    required this.city,
    required this.district,
    required this.partySize,
    required this.budgetMaxCents,
    this.lat,
    this.lng,
    this.limit = 10,
  });

  final String city;
  final String district;
  final int partySize;
  final int budgetMaxCents;
  final double? lat;
  final double? lng;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRecoQuery &&
          city == other.city &&
          district == other.district &&
          partySize == other.partySize &&
          budgetMaxCents == other.budgetMaxCents &&
          lat == other.lat &&
          lng == other.lng &&
          limit == other.limit;

  @override
  int get hashCode =>
      Object.hash(city, district, partySize, budgetMaxCents, lat, lng, limit);
}

class SmartRecommendation {
  const SmartRecommendation({
    required this.businessId,
    required this.businessName,
    required this.totalCents,
    this.imageUrl,
    this.cuisine,
    this.rating,
    this.reviewCount,
    this.distanceKm,
    this.estimatedMinutes,
    this.originalTotalCents,
    this.discountPct,
  });

  final String businessId;
  final String businessName;
  final String? imageUrl;
  final String? cuisine;
  final double? rating;
  final int? reviewCount;
  final double? distanceKm;
  final int? estimatedMinutes;
  final int totalCents;
  final int? originalTotalCents;
  final int? discountPct;

  factory SmartRecommendation.fromMap(Map<String, dynamic> map) {
    return SmartRecommendation(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      imageUrl: map['image_url'] as String?,
      cuisine: map['cuisine'] as String?,
      rating: _toDouble(map['rating']),
      reviewCount: (map['review_count'] as num?)?.toInt(),
      distanceKm: _toDouble(map['distance_km']),
      estimatedMinutes: (map['estimated_minutes'] as num?)?.toInt(),
      totalCents: (map['total_cents'] as num?)?.toInt() ?? 0,
      originalTotalCents: (map['original_total_cents'] as num?)?.toInt(),
      discountPct: (map['discount_pct'] as num?)?.toInt(),
    );
  }
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
