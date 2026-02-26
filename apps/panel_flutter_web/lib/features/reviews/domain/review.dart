class Review {
  Review({
    required this.id,
    required this.businessId,
    required this.rating,
    required this.content,
    this.title,
    required this.helpfulCount,
    required this.createdAt,
    this.userId,
    required this.status,
    this.qualityScore = 0,
  });

  final String id;
  final String businessId;
  final int rating;
  final String? title;
  final String content;
  final int helpfulCount;
  final DateTime createdAt;
  final String? userId;
  final String status;
  final double qualityScore;

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    rating: m['rating'] as int,
    title: m['title'] as String?,
    content: m['content'] as String,
    helpfulCount: (m['helpful_count'] as int?) ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    userId: m['user_id'] as String?,
    status: m['status'] as String,
    qualityScore: (m['quality_score'] as num?)?.toDouble() ?? 0,
  );
}
