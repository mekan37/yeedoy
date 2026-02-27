class BusinessStats {
  BusinessStats({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.lat,
    required this.lng,
    required this.avgRating,
    required this.reviewsCount,
  });

  final String id;
  final String name;
  final String? category;
  final String? address;
  final String? city;
  final String? district;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final double avgRating;
  final int reviewsCount;

  factory BusinessStats.fromMap(Map<String, dynamic> m) => BusinessStats(
    id: m['id'] as String,
    name: (m['name'] ?? '').toString(),
    category: m['category'] as String?,
    address: m['address'] as String?,
    city: m['city'] as String?,
    district: m['district'] as String?,
    neighborhood: m['neighborhood'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0,
    reviewsCount: (m['reviews_count'] as num?)?.toInt() ?? 0,
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
    'avg_rating': avgRating,
    'reviews_count': reviewsCount,
  };
}

class RatingBreakdown {
  RatingBreakdown(this.counts);

  final Map<int, int> counts;

  int countFor(int stars) => counts[stars] ?? 0;

  int get total => counts.values.fold(0, (a, b) => a + b);

  factory RatingBreakdown.fromMap(Map<String, dynamic>? m) {
    if (m == null) return RatingBreakdown({});
    final counts = <int, int>{};
    for (final entry in m.entries) {
      final key = int.tryParse(entry.key);
      if (key == null) continue;
      final value = (entry.value as num?)?.toInt() ?? 0;
      counts[key] = value;
    }
    return RatingBreakdown(counts);
  }

  Map<String, dynamic> toMap() => {
    for (final entry in counts.entries) '${entry.key}': entry.value,
  };
}

class ReviewPreview {
  ReviewPreview({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.rating,
    required this.title,
    required this.content,
    required this.helpfulCount,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String userId;
  final int rating;
  final String? title;
  final String content;
  final int helpfulCount;
  final DateTime createdAt;

  factory ReviewPreview.fromMap(Map<String, dynamic> m) => ReviewPreview(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    userId: m['user_id'] as String,
    rating: (m['rating'] as num?)?.toInt() ?? 0,
    title: m['title'] as String?,
    content: (m['content'] ?? '').toString(),
    helpfulCount: (m['helpful_count'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'business_id': businessId,
    'user_id': userId,
    'rating': rating,
    'title': title,
    'content': content,
    'helpful_count': helpfulCount,
    'created_at': createdAt.toIso8601String(),
  };
}

class BusinessDetail {
  BusinessDetail({
    required this.stats,
    required this.breakdown,
    required this.latestReviews,
  });

  final BusinessStats stats;
  final RatingBreakdown breakdown;
  final List<ReviewPreview> latestReviews;

  factory BusinessDetail.fromJson(Map<String, dynamic> json) => BusinessDetail(
    stats: BusinessStats.fromMap(
      (json['stats'] as Map).cast<String, dynamic>(),
    ),
    breakdown: RatingBreakdown.fromMap(
      (json['rating_breakdown'] as Map?)?.cast<String, dynamic>(),
    ),
    latestReviews: ((json['latest_reviews'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ReviewPreview.fromMap)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'stats': stats.toMap(),
    'rating_breakdown': breakdown.toMap(),
    'latest_reviews': latestReviews.map((e) => e.toMap()).toList(),
  };
}
