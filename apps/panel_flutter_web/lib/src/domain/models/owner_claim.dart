class OwnerClaim {
  OwnerClaim({
    required this.id,
    required this.businessId,
    required this.status,
    required this.createdAt,
    this.adminNote,
  });

  final String id;
  final String businessId;
  final String status;
  final DateTime createdAt;
  final String? adminNote;

  factory OwnerClaim.fromMap(Map<String, dynamic> m) => OwnerClaim(
        id: m['id'] as String,
        businessId: m['business_id'] as String,
        status: (m['status'] ?? '').toString(),
        createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
        adminNote: m['admin_note'] as String?,
      );
}

class OwnerClaimItem {
  OwnerClaimItem({required this.claim, required this.businessName});
  final OwnerClaim claim;
  final String businessName;
}
