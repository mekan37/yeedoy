class TasteMatch {
  TasteMatch({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.similarity,
    required this.overlapCount,
    this.reviewSimilarity,
    this.signalSimilarity,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final double similarity;
  final int overlapCount;
  final double? reviewSimilarity;
  final double? signalSimilarity;

  int get similarityPercent => (similarity * 100).round().clamp(0, 100);

  factory TasteMatch.fromMap(Map<String, dynamic> map) {
    return TasteMatch(
      userId: (map['user_id'] ?? map['id'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['name'] ?? 'Kullanıcı').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatar'] ?? '').toString(),
      similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
      overlapCount: (map['overlap'] as num?)?.toInt() ?? 0,
      reviewSimilarity: (map['review_similarity'] as num?)?.toDouble(),
      signalSimilarity: (map['signal_similarity'] as num?)?.toDouble(),
    );
  }
}

class TasteRecommendation {
  TasteRecommendation({
    required this.businessId,
    required this.businessName,
    required this.district,
    required this.city,
    required this.rating,
    required this.excerpt,
    this.matchReviewCreatedAt,
  });

  final String businessId;
  final String businessName;
  final String district;
  final String city;
  final int rating;
  final String excerpt;
  final DateTime? matchReviewCreatedAt;

  factory TasteRecommendation.fromMap(Map<String, dynamic> map) {
    return TasteRecommendation(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      excerpt: (map['excerpt'] ?? map['content'] ?? '').toString(),
      matchReviewCreatedAt:
          DateTime.tryParse((map['match_review_created_at'] ?? '').toString()),
    );
  }
}

class PublicProfile {
  PublicProfile({
    required this.displayName,
    required this.avatarUrl,
  });

  final String displayName;
  final String avatarUrl;

  factory PublicProfile.fromMap(Map<String, dynamic> map) {
    return PublicProfile(
      displayName: (map['display_name'] ?? map['name'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatar'] ?? '').toString(),
    );
  }
}

class TasteOverlapExample {
  TasteOverlapExample({
    required this.businessId,
    required this.businessName,
    required this.myRating,
    required this.otherRating,
    required this.myReviewCreatedAt,
  });

  final String businessId;
  final String businessName;
  final int myRating;
  final int otherRating;
  final DateTime myReviewCreatedAt;

  factory TasteOverlapExample.fromMap(Map<String, dynamic> map) {
    return TasteOverlapExample(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      myRating: (map['my_rating'] as num?)?.toInt() ?? 0,
      otherRating: (map['other_rating'] as num?)?.toInt() ?? 0,
      myReviewCreatedAt:
          DateTime.tryParse((map['my_review_created_at'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}

class TasteDivergenceExample {
  TasteDivergenceExample({
    required this.businessId,
    required this.businessName,
    required this.myRating,
    required this.otherRating,
  });

  final String businessId;
  final String businessName;
  final int myRating;
  final int otherRating;

  factory TasteDivergenceExample.fromMap(Map<String, dynamic> map) {
    return TasteDivergenceExample(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      myRating: (map['my_rating'] as num?)?.toInt() ?? 0,
      otherRating: (map['other_rating'] as num?)?.toInt() ?? 0,
    );
  }
}

class TasteSignalOverlapExample {
  TasteSignalOverlapExample({
    required this.businessId,
    required this.businessName,
    required this.mySignal,
    required this.otherSignal,
  });

  final String businessId;
  final String businessName;
  final int mySignal;
  final int otherSignal;

  factory TasteSignalOverlapExample.fromMap(Map<String, dynamic> map) {
    return TasteSignalOverlapExample(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      mySignal: (map['my_signal'] as num?)?.toInt() ?? 0,
      otherSignal: (map['other_signal'] as num?)?.toInt() ?? 0,
    );
  }
}




