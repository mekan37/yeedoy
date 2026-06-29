class MyReviewEntry {
  const MyReviewEntry({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.rating,
    this.title,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final int rating;
  final String? title;
  final String content;
  final String status;
  final DateTime createdAt;

  factory MyReviewEntry.fromMap(Map<String, dynamic> m) {
    final business = m['businesses'] as Map<String, dynamic>?;
    return MyReviewEntry(
      id: m['id'] as String,
      businessId: m['business_id'] as String,
      businessName: (business?['name'] as String?) ?? '',
      rating: m['rating'] as int,
      title: m['title'] as String?,
      content: m['content'] as String,
      status: m['status'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
