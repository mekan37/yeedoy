class AdminAuditLogItem {
  AdminAuditLogItem({
    required this.createdAt,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.beforeData,
    this.afterData,
    this.ip,
    this.userAgent,
    this.meta,
  });

  final DateTime createdAt;
  final String actorId;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final Object? beforeData;
  final Object? afterData;
  final String? ip;
  final String? userAgent;
  final Object? meta;

  factory AdminAuditLogItem.fromMap(Map<String, dynamic> m) =>
      AdminAuditLogItem(
        createdAt: _asDate(m['created_at']),
        actorId: (m['actor_id'] ?? m['admin_user_id'] ?? '').toString(),
        actorRole: (m['actor_role'] ?? '').toString(),
        action: (m['action'] ?? '').toString(),
        targetType: (m['target_type'] ?? m['target_table'] ?? '').toString(),
        targetId: (m['target_id'] ?? '').toString(),
        beforeData: m['before_data'],
        afterData: m['after_data'],
        ip: (m['ip'] as String?)?.trim().isEmpty ?? true
            ? null
            : m['ip'] as String?,
        userAgent: (m['user_agent'] as String?)?.trim().isEmpty ?? true
            ? null
            : m['user_agent'] as String?,
        meta: m['meta'],
      );
}

DateTime _asDate(Object? v) {
  if (v is DateTime) return v;
  return DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
}
