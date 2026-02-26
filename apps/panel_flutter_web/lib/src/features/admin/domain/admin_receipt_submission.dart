class AdminReceiptSubmission {
  AdminReceiptSubmission({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.userId,
    required this.imageUrl,
    required this.matchesCount,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String userId;
  final String imageUrl;
  final int matchesCount;
  final DateTime createdAt;

  factory AdminReceiptSubmission.fromMap(Map<String, dynamic> map) {
    return AdminReceiptSubmission(
      id: (map['receipt_id'] ?? map['id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      matchesCount: (map['matches_count'] is int)
          ? map['matches_count'] as int
          : int.tryParse('${map['matches_count'] ?? ''}') ?? 0,
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
