enum ConsentStatus { unknown, granted, denied }

class ConsentState {
  const ConsentState({
    this.analytics = ConsentStatus.unknown,
    this.marketing = ConsentStatus.unknown,
    this.dataRetention = ConsentStatus.unknown,
    this.consentedAt,
  });

  final ConsentStatus analytics;
  final ConsentStatus marketing;

  /// KVKK madde 7 — 5 yıl saklama / kullanıcı silme hakkı.
  final ConsentStatus dataRetention;
  final DateTime? consentedAt;

  bool get allGranted =>
      analytics == ConsentStatus.granted &&
      marketing == ConsentStatus.granted &&
      dataRetention == ConsentStatus.granted;

  /// Kullanıcı en az bir konuda karar verdiyse true.
  bool get hasDecided =>
      analytics != ConsentStatus.unknown ||
      marketing != ConsentStatus.unknown;

  ConsentState copyWith({
    ConsentStatus? analytics,
    ConsentStatus? marketing,
    ConsentStatus? dataRetention,
    DateTime? consentedAt,
  }) {
    return ConsentState(
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
      dataRetention: dataRetention ?? this.dataRetention,
      consentedAt: consentedAt ?? this.consentedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'analytics': analytics.name,
        'marketing': marketing.name,
        'dataRetention': dataRetention.name,
        'consentedAt': consentedAt?.toIso8601String(),
      };

  factory ConsentState.fromJson(Map<String, dynamic> json) {
    return ConsentState(
      analytics: _parseStatus(json['analytics']),
      marketing: _parseStatus(json['marketing']),
      dataRetention: _parseStatus(json['dataRetention']),
      consentedAt: json['consentedAt'] == null
          ? null
          : DateTime.tryParse(json['consentedAt'] as String),
    );
  }

  static ConsentStatus _parseStatus(dynamic raw) {
    if (raw is! String) return ConsentStatus.unknown;
    return ConsentStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ConsentStatus.unknown,
    );
  }
}
