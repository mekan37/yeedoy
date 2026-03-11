import '../../../core/security/business_rbac.dart';

class AdminUserBusinessAccess {
  const AdminUserBusinessAccess({
    required this.businessId,
    required this.businessName,
    required this.city,
    required this.district,
    required this.claimStatus,
    required this.claimedAt,
    this.chainId,
    this.chainName,
    this.branchLabel,
    required this.role,
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
  final OwnerTeamRole role;

  factory AdminUserBusinessAccess.fromMap(Map<String, dynamic> map) {
    return AdminUserBusinessAccess(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      claimStatus: (map['claim_status'] ?? '').toString(),
      claimedAt:
          DateTime.tryParse((map['claimed_at'] ?? '').toString()) ?? DateTime.now(),
      chainId: _nullable(map['chain_id']),
      chainName: _nullable(map['chain_name']),
      branchLabel: _nullable(map['branch_label']),
      role: OwnerTeamRole.fromValue((map['owner_role'] ?? '').toString()),
    );
  }
}

String? _nullable(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
