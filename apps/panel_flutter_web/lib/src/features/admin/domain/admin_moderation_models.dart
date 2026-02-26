class ModerationDecisionTemplate {
  const ModerationDecisionTemplate({
    required this.id,
    required this.scope,
    required this.decision,
    required this.title,
    required this.body,
    required this.locale,
  });

  final String id;
  final String scope;
  final String decision;
  final String title;
  final String body;
  final String locale;

  factory ModerationDecisionTemplate.fromMap(Map<String, dynamic> map) {
    return ModerationDecisionTemplate(
      id: (map['id'] ?? '').toString(),
      scope: (map['scope'] ?? '').toString(),
      decision: (map['decision'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      locale: (map['locale'] ?? 'tr-TR').toString(),
    );
  }
}

class AdminAppealItem {
  const AdminAppealItem({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.appellantUserId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.details,
    this.decisionNote,
    this.decidedAt,
    this.decidedBy,
  });

  final String id;
  final String sourceType;
  final String sourceId;
  final String appellantUserId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? details;
  final String? decisionNote;
  final DateTime? decidedAt;
  final String? decidedBy;

  factory AdminAppealItem.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(Object? v) =>
        DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
    DateTime? parseDateOrNull(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    String? parseTextOrNull(Object? v) {
      final text = (v ?? '').toString().trim();
      return text.isEmpty ? null : text;
    }

    return AdminAppealItem(
      id: (map['appeal_id'] ?? map['id'] ?? '').toString(),
      sourceType: (map['source_type'] ?? '').toString(),
      sourceId: (map['source_id'] ?? '').toString(),
      appellantUserId: (map['appellant_user_id'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: parseDate(map['created_at']),
      details: parseTextOrNull(map['details']),
      decisionNote: parseTextOrNull(map['decision_note']),
      decidedAt: parseDateOrNull(map['decided_at']),
      decidedBy: parseTextOrNull(map['decided_by']),
    );
  }
}
