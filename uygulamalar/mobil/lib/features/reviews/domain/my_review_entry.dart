class MyReviewEntry {
  const MyReviewEntry({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessDistrict,
    this.businessCity,
    this.businessImageUrl,
    required this.rating,
    this.title,
    required this.content,
    required this.status,
    required this.helpfulCount,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String? businessDistrict;
  final String? businessCity;
  final String? businessImageUrl;
  final int rating;
  final String? title;
  final String content;
  final String status;
  final int helpfulCount;
  final DateTime createdAt;

  factory MyReviewEntry.fromMap(Map<String, dynamic> m) {
    final business = m['businesses'] as Map<String, dynamic>?;
    return MyReviewEntry(
      id: m['id'] as String,
      businessId: m['business_id'] as String,
      businessName: (business?['name'] as String?) ?? '',
      businessDistrict: business?['district'] as String?,
      businessCity: business?['city'] as String?,
      businessImageUrl: business?['image_url'] as String?,
      rating: m['rating'] as int,
      title: m['title'] as String?,
      content: m['content'] as String,
      status: m['status'] as String,
      helpfulCount: (m['helpful_count'] as int?) ?? 0,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
