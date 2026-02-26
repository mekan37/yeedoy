class Business {
  Business({
    required this.id,
    required this.name,
    required this.category,
    this.address,
    this.city,
    this.district,
    this.neighborhood,
    this.lat,
    this.lng,
    this.isActive = true,
    this.lifecycleStatus,
    this.lifecycleNote,
    this.lifecycleUpdatedAt,
    this.reviewsCount = 0,
    this.avgRating = 0,
  });

  final String id;
  final String name;
  final String category;
  final String? address;
  final String? city;
  final String? district;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final bool isActive;
  final String? lifecycleStatus;
  final String? lifecycleNote;
  final DateTime? lifecycleUpdatedAt;

  final int reviewsCount;
  final double avgRating;

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'] as String,
    name: m['name'] as String,
    category: m['category'] as String,
    address: m['address'] as String?,
    city: m['city'] as String?,
    district: m['district'] as String?,
    neighborhood: m['neighborhood'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    isActive: (m['is_active'] as bool?) ?? true,
    lifecycleStatus: (m['lifecycle_status'] ?? m['status']) as String?,
    lifecycleNote: m['lifecycle_note'] as String?,
    lifecycleUpdatedAt: m['lifecycle_updated_at'] == null
        ? null
        : DateTime.tryParse(m['lifecycle_updated_at'].toString()),
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'address': address,
    'city': city,
    'district': district,
    'neighborhood': neighborhood,
    'lat': lat,
    'lng': lng,
    'is_active': isActive,
    'lifecycle_status': lifecycleStatus,
    'lifecycle_note': lifecycleNote,
    'lifecycle_updated_at': lifecycleUpdatedAt?.toIso8601String(),
    'reviews_count': reviewsCount,
    'avg_rating': avgRating,
  };
}
