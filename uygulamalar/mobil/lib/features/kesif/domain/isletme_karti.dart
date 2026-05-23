import '../../isletme/domain/ogun_karti_saglayici_secenegi.dart';

class BusinessCardModel {
  BusinessCardModel({
    required this.id,
    required this.name,
    required this.category,
    this.city,
    this.district,
    this.address,
    this.lat,
    this.lng,
    this.distanceKm,
    this.qualityScore,
    this.avgRating,
    this.trustScore,
    this.medianPriceCents,
    this.isOpenNow,
    this.recentPriceVerifiedCount,
    this.ownerVerified,
    this.mealCardProviders = const [],
    this.reviewCount,
  });

  final String id;
  final String name;
  final String category;
  final String? city;
  final String? district;
  final String? address;
  final double? lat;
  final double? lng;

  final double? distanceKm;
  final double? qualityScore;
  final double? avgRating;
  final double? trustScore;
  final int? medianPriceCents;
  final bool? isOpenNow;
  final int? recentPriceVerifiedCount;
  final bool? ownerVerified;
  final List<MealCardProviderOption> mealCardProviders;
  final int? reviewCount;

  factory BusinessCardModel.fromMap(Map<String, dynamic> m) =>
      BusinessCardModel(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        city: m['city'] as String?,
        district: m['district'] as String?,
        address: m['address'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        qualityScore: (m['quality_score'] as num?)?.toDouble(),
        avgRating: (m['avg_rating'] as num?)?.toDouble(),
        trustScore:
            (m['trust_score'] as num?)?.toDouble() ??
            (m['moat_score'] as num?)?.toDouble(),
        medianPriceCents: (m['median_price_cents'] as num?)?.toInt(),
        isOpenNow: m['is_open_now'] as bool?,
        recentPriceVerifiedCount: (m['recent_price_verified_count'] as num?)
            ?.toInt(),
        ownerVerified: m['owner_verified'] as bool?,
        reviewCount: (m['review_count'] as num?)?.toInt(),
        mealCardProviders: ((m['meal_card_providers'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (row) => MealCardProviderOption.fromMap(
                row.cast<String, dynamic>(),
              ),
            )
            .toList(growable: false),
      );

  factory BusinessCardModel.fromSponsoredMap(Map<String, dynamic> m) =>
      BusinessCardModel(
        id: (m['business_id'] ?? m['id']) as String,
        name: (m['business_name'] ?? m['name']) as String,
        category: (m['category'] ?? '') as String,
        city: m['city'] as String?,
        district: m['district'] as String?,
      );

  BusinessCardModel copyWith({
    String? id,
    String? name,
    String? category,
    String? city,
    String? district,
    String? address,
    double? lat,
    double? lng,
    double? distanceKm,
    double? qualityScore,
    double? avgRating,
    double? trustScore,
    int? medianPriceCents,
    bool? isOpenNow,
    int? recentPriceVerifiedCount,
    bool? ownerVerified,
    List<MealCardProviderOption>? mealCardProviders,
    int? reviewCount,
  }) {
    return BusinessCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceKm: distanceKm ?? this.distanceKm,
      qualityScore: qualityScore ?? this.qualityScore,
      avgRating: avgRating ?? this.avgRating,
      trustScore: trustScore ?? this.trustScore,
      medianPriceCents: medianPriceCents ?? this.medianPriceCents,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      recentPriceVerifiedCount:
          recentPriceVerifiedCount ?? this.recentPriceVerifiedCount,
      ownerVerified: ownerVerified ?? this.ownerVerified,
      mealCardProviders: mealCardProviders ?? this.mealCardProviders,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'city': city,
    'district': district,
    'address': address,
    'lat': lat,
    'lng': lng,
    'distance_km': distanceKm,
    'quality_score': qualityScore,
    'avg_rating': avgRating,
    'trust_score': trustScore,
    'median_price_cents': medianPriceCents,
    'is_open_now': isOpenNow,
    'recent_price_verified_count': recentPriceVerifiedCount,
    'owner_verified': ownerVerified,
    'meal_card_providers': mealCardProviders.map((item) => item.toMap()).toList(),
    'review_count': reviewCount,
  };
}


