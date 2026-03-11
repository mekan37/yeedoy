class AdminBusinessSubmission {
  AdminBusinessSubmission({
    required this.totalCount,
    required this.id,
    required this.submittedBy,
    required this.name,
    required this.city,
    required this.district,
    required this.category,
    required this.address,
    required this.phone,
    required this.website,
    required this.status,
    required this.adminNote,
    required this.createdAt,
  });

  final int totalCount;
  final String id;
  final String submittedBy;
  final String name;
  final String city;
  final String district;
  final String category;
  final String address;
  final String? phone;
  final String? website;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  factory AdminBusinessSubmission.fromMap(Map<String, dynamic> map) {
    return AdminBusinessSubmission(
      totalCount: _asInt(map['total_count']),
      id: (map['id'] ?? '').toString(),
      submittedBy: (map['submitted_by'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      phone: map['phone']?.toString(),
      website: map['website']?.toString(),
      status: (map['status'] ?? '').toString(),
      adminNote: map['admin_note']?.toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
