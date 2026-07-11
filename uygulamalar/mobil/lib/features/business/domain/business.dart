class Business {
  Business({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.logoUrl,
    this.coverImageUrl,
    this.heroImageUrl,
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
    this.description,
    this.isVerified = false,
    this.priceLevel,
    this.acceptsReservations = false,
    this.reservationPhone,
    this.reservationMinParty = 1,
    this.reservationMaxParty = 20,
    this.reservationNote,
  });

  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? heroImageUrl;
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
  final String? description;
  final bool isVerified;
  final String? priceLevel;
  final bool acceptsReservations;
  final String? reservationPhone;
  final int reservationMinParty;
  final int reservationMaxParty;
  final String? reservationNote;

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'] as String,
    name: m['name'] as String,
    category: m['category'] as String,
    imageUrl: (m['image_url'] ?? m['photo_url']) as String?,
    logoUrl: m['logo_url'] as String?,
    coverImageUrl: (m['cover_image_url'] ?? m['banner_url']) as String?,
    heroImageUrl: (m['hero_image_url'] ?? m['share_image_url']) as String?,
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
    description: m['description'] as String?,
    isVerified: (m['is_verified'] as bool?) ?? false,
    priceLevel: m['price_level'] as String?,
    acceptsReservations: (m['accepts_reservations'] as bool?) ?? false,
    reservationPhone: m['reservation_phone'] as String?,
    reservationMinParty: (m['reservation_min_party'] as num?)?.toInt() ?? 1,
    reservationMaxParty: (m['reservation_max_party'] as num?)?.toInt() ?? 20,
    reservationNote: m['reservation_note'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'image_url': imageUrl,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'hero_image_url': heroImageUrl,
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
    'description': description,
    'is_verified': isVerified,
    'price_level': priceLevel,
    'accepts_reservations': acceptsReservations,
    'reservation_phone': reservationPhone,
    'reservation_min_party': reservationMinParty,
    'reservation_max_party': reservationMaxParty,
    'reservation_note': reservationNote,
  };
}
