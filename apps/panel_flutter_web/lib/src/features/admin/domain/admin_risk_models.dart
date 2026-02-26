class AdminRiskQueueItem {
  AdminRiskQueueItem({
    required this.userId,
    required this.riskScore,
    required this.signalCount,
    required this.lastSignalAt,
    required this.newAccountHits,
    required this.deviceChangeHits,
    required this.sameIpHits,
    required this.duplicateTextHits,
    required this.recommendedAction,
    this.softLimitedUntil,
    this.autoPendingUntil,
    this.shadowBannedUntil,
  });

  final String userId;
  final int riskScore;
  final int signalCount;
  final DateTime? lastSignalAt;
  final int newAccountHits;
  final int deviceChangeHits;
  final int sameIpHits;
  final int duplicateTextHits;
  final String recommendedAction;
  final DateTime? softLimitedUntil;
  final DateTime? autoPendingUntil;
  final DateTime? shadowBannedUntil;

  bool get isSoftLimited =>
      softLimitedUntil != null && softLimitedUntil!.isAfter(DateTime.now());
  bool get isAutoPending =>
      autoPendingUntil != null && autoPendingUntil!.isAfter(DateTime.now());
  bool get isShadowBanned =>
      shadowBannedUntil != null && shadowBannedUntil!.isAfter(DateTime.now());

  factory AdminRiskQueueItem.fromMap(Map<String, dynamic> map) {
    return AdminRiskQueueItem(
      userId: (map['user_id'] ?? '').toString(),
      riskScore: _asInt(map['risk_score']),
      signalCount: _asInt(map['signal_count']),
      lastSignalAt: _asDate(map['last_signal_at']),
      newAccountHits: _asInt(map['new_account_hits']),
      deviceChangeHits: _asInt(map['device_change_hits']),
      sameIpHits: _asInt(map['same_ip_hits']),
      duplicateTextHits: _asInt(map['duplicate_text_hits']),
      recommendedAction: (map['recommended_action'] ?? '').toString(),
      softLimitedUntil: _asDate(map['soft_limited_until']),
      autoPendingUntil: _asDate(map['auto_pending_until']),
      shadowBannedUntil: _asDate(map['shadow_banned_until']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

DateTime? _asDate(Object? value) {
  if (value is DateTime) return value;
  final text = (value ?? '').toString();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
