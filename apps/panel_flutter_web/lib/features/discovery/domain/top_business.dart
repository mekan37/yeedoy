class TopBusiness {
  TopBusiness({
    required this.businessId,
    required this.name,
    required this.category,
    required this.city,
    required this.district,
    required this.avgRating,
    required this.reviewsCount,
  });

  final String businessId;
  final String name;
  final String category;
  final String? city;
  final String? district;
  final double avgRating;
  final int reviewsCount;

  factory TopBusiness.fromMap(Map<String, dynamic> m) => TopBusiness(
        businessId: m['business_id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        city: m['city'] as String?,
        district: m['district'] as String?,
        avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
        reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
      );
}
