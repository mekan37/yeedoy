class AdminTableFeedbackItem {
  AdminTableFeedbackItem({
    required this.businessId,
    required this.businessName,
    required this.tableNo,
    required this.rating,
    required this.note,
    required this.createdAt,
    required this.clientId,
  });

  final String businessId;
  final String businessName;
  final String tableNo;
  final int rating;
  final String note;
  final DateTime createdAt;
  final String clientId;

  factory AdminTableFeedbackItem.fromMap(Map<String, dynamic> map) {
    return AdminTableFeedbackItem(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      tableNo: (map['table_no'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      note: (map['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      clientId: (map['client_id'] ?? '').toString(),
    );
  }
}
