class FeedItem {
  FeedItem({
    required this.type,
    required this.createdAt,
    required this.businessId,
    required this.businessName,
    required this.actorName,
    this.caption,
    this.reviewId,
    this.rating,
    this.title,
    this.excerpt,
  });

  final String type;
  final DateTime createdAt;
  final String businessId;
  final String businessName;
  final String actorName;
  final String? caption;
  final String? reviewId;
  final int? rating;
  final String? title;
  final String? excerpt;

  factory FeedItem.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now();
    return FeedItem(
      type: (map['type'] ?? '').toString(),
      createdAt: createdAt,
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? map['business'] ?? '').toString(),
      actorName: (map['actor_name'] ?? map['display_name'] ?? map['user_name'] ?? '').toString(),
      caption: (map['caption'] ?? '').toString(),
      reviewId: map['review_id']?.toString(),
      rating: (map['rating'] as num?)?.toInt(),
      title: (map['title'] ?? '').toString(),
      excerpt: (map['excerpt'] ?? map['content'] ?? '').toString(),
    );
  }
}
