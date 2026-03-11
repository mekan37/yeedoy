class AdminOfflineMutationOutcome {
  const AdminOfflineMutationOutcome({
    required this.createdAt,
    required this.source,
    required this.kind,
    required this.disposition,
    required this.retryCategory,
    required this.retryCount,
    required this.detail,
    required this.userId,
    required this.clientId,
  });

  factory AdminOfflineMutationOutcome.fromMap(Map<String, dynamic> map) {
    return AdminOfflineMutationOutcome(
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: (map['source'] ?? '').toString(),
      kind: (map['kind'] ?? '').toString(),
      disposition: (map['disposition'] ?? '').toString(),
      retryCategory: _trimOrNull(map['retry_category']),
      retryCount: _asInt(map['retry_count']) ?? 0,
      detail: _trimOrNull(map['detail']),
      userId: _trimOrNull(map['user_id']),
      clientId: _trimOrNull(map['client_id']),
    );
  }

  final DateTime createdAt;
  final String source;
  final String kind;
  final String disposition;
  final String? retryCategory;
  final int retryCount;
  final String? detail;
  final String? userId;
  final String? clientId;
}

String? _trimOrNull(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString());
}
