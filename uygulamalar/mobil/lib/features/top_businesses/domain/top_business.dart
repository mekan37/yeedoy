class TopBusiness {
  TopBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.district,
    required this.avgRating,
    required this.reviewsCount,
    required this.score,
    this.imageUrl,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? category;
  final String? city;
  final String? district;
  final double avgRating;
  final int reviewsCount;
  final double score;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final double? distanceKm;

  factory TopBusiness.fromMap(Map<String, dynamic> m) => TopBusiness(
    id: m['id'] as String,
    name: (m['name'] ?? '').toString(),
    category: m['category'] as String?,
    city: m['city'] as String?,
    district: m['district'] as String?,
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    score: (m['score'] as num?)?.toDouble() ?? 0,
    imageUrl: m['image_url'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    distanceKm: (m['distance_km'] as num?)?.toDouble(),
  );
}
