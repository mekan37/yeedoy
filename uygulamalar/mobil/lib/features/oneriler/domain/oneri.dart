class BusinessSuggestion {
  BusinessSuggestion({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.createdAt,
    this.city,
    this.district,
    this.adminNote, this.approvedBusinessId,
  });

  final String id;
  final String name;
  final String category;
  final String status; // pending | approved | rejected
  final DateTime createdAt;

  final String? city;
  final String? district;
  final String? adminNote;
  final String? approvedBusinessId;

  factory BusinessSuggestion.fromMap(Map<String, dynamic> m) => BusinessSuggestion(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        status: (m['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(m['created_at'].toString()),
        city: m['city'] as String?,
        district: m['district'] as String?,
        adminNote: m['admin_note'] as String?,
        approvedBusinessId: m['approved_business_id'] as String?,
      );
}
