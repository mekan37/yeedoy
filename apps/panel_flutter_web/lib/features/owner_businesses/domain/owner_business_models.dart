class OwnerBusiness {
  OwnerBusiness({
    required this.businessId,
    required this.businessName,
    required this.city,
    required this.district,
    required this.claimStatus,
    required this.claimedAt,
    this.chainId,
    this.chainName,
    this.branchLabel,
    this.ownerRole = 'owner',
    this.slug,
    this.publicSlug,
  });

  final String businessId;
  final String businessName;
  final String city;
  final String district;
  final String claimStatus;
  final DateTime claimedAt;
  final String? chainId;
  final String? chainName;
  final String? branchLabel;
  final String ownerRole;
  final String? slug;
  final String? publicSlug;

  factory OwnerBusiness.fromMap(Map<String, dynamic> map) {
    return OwnerBusiness(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      claimStatus: (map['claim_status'] ?? '').toString(),
      claimedAt:
          DateTime.tryParse((map['claimed_at'] ?? '').toString()) ??
          DateTime.now(),
      chainId: (map['chain_id'] ?? '').toString().trim().isEmpty
          ? null
          : (map['chain_id'] ?? '').toString(),
      chainName: (map['chain_name'] ?? '').toString().trim().isEmpty
          ? null
          : (map['chain_name'] ?? '').toString(),
      branchLabel: (map['branch_label'] ?? '').toString().trim().isEmpty
          ? null
          : (map['branch_label'] ?? '').toString(),
      ownerRole: (map['owner_role'] ?? 'owner').toString(),
      slug: _nullableString(
        map['slug'] ?? map['business_slug'] ?? map['legacy_slug'],
      ),
      publicSlug: _nullableString(
        map['public_slug'] ?? map['business_public_slug'],
      ),
    );
  }

  OwnerBusiness copyWith({
    String? slug,
    String? publicSlug,
  }) {
    return OwnerBusiness(
      businessId: businessId,
      businessName: businessName,
      city: city,
      district: district,
      claimStatus: claimStatus,
      claimedAt: claimedAt,
      chainId: chainId,
      chainName: chainName,
      branchLabel: branchLabel,
      ownerRole: ownerRole,
      slug: slug ?? this.slug,
      publicSlug: publicSlug ?? this.publicSlug,
    );
  }
}

class BusinessSubmission {
  BusinessSubmission({
    required this.id,
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

  final String id;
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

  factory BusinessSubmission.fromMap(Map<String, dynamic> map) {
    return BusinessSubmission(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      phone: map['phone']?.toString(),
      website: map['website']?.toString(),
      status: (map['status'] ?? '').toString(),
      adminNote: map['admin_note']?.toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

String? _nullableString(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}
