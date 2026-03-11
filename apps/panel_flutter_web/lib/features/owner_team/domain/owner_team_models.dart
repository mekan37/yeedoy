import '../../../core/security/business_rbac.dart';

class OwnerTeamMember {
  const OwnerTeamMember({
    required this.membershipId,
    required this.userId,
    required this.email,
    required this.role,
    required this.scope,
    required this.status,
    required this.source,
    required this.createdAt,
    this.acceptedAt,
  });

  final String? membershipId;
  final String? userId;
  final String email;
  final OwnerTeamRole role;
  final TeamAccessScope scope;
  final String status;
  final String source;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  bool get isPending => status == 'pending';
  bool get isReadOnly => source == 'owner_claim' || source == 'chain_membership';

  factory OwnerTeamMember.fromMap(Map<String, dynamic> map) {
    return OwnerTeamMember(
      membershipId: _nullable(map['membership_id']),
      userId: _nullable(map['user_id']),
      email: (_nullable(map['email']) ?? '-').trim(),
      role: OwnerTeamRole.fromValue((map['role'] ?? '').toString()),
      scope: TeamAccessScope.fromValue((map['scope'] ?? '').toString()),
      status: (map['status'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      acceptedAt: DateTime.tryParse((map['accepted_at'] ?? '').toString()),
    );
  }
}

String? _nullable(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}
