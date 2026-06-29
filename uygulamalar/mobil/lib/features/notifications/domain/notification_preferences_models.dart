import 'package:flutter/foundation.dart';

/// Global platform pazarlama e-posta izni modeli.
///
/// Bu model yalnızca [user_profiles.marketing_email_opt_in] ve
/// [user_profiles.marketing_email_opted_in_at] alanlarını temsil eder.
///
/// Karıştırılmaması gereken alan: [business_follows.is_subscribed_email]
/// işletme bazlı aboneliği temsil eder ve bu modelde yer almaz.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.marketingEmailOptIn,
    this.marketingEmailOptedInAt,
  });

  /// Platform geneli pazarlama e-posta izni.
  /// Kaynak: [user_profiles.marketing_email_opt_in]
  /// Default: false (migration 20260620000001 ile eklendi)
  final bool marketingEmailOptIn;

  /// Son opt-in zaman damgası. Kullanıcı izni geri çektiğinde null olur.
  /// Kaynak: [user_profiles.marketing_email_opted_in_at]
  /// KVKK ispat yükümlülüğü için korunur.
  final DateTime? marketingEmailOptedInAt;

  /// Backend değer yokken veya migration henüz uygulanmamışken kullanılacak
  /// güvenli başlangıç değeri. Default false — opt-out.
  static const NotificationPreferences defaultValue = NotificationPreferences(
    marketingEmailOptIn: false,
  );

  factory NotificationPreferences.fromRpcJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      marketingEmailOptIn: (json['marketing_email_opt_in'] as bool?) ?? false,
      marketingEmailOptedInAt: json['marketing_email_opted_in_at'] == null
          ? null
          : DateTime.tryParse(
              (json['marketing_email_opted_in_at'] as String?) ?? '',
            ),
    );
  }

  NotificationPreferences copyWith({
    bool? marketingEmailOptIn,
    DateTime? marketingEmailOptedInAt,
    bool clearOptedInAt = false,
  }) {
    return NotificationPreferences(
      marketingEmailOptIn: marketingEmailOptIn ?? this.marketingEmailOptIn,
      marketingEmailOptedInAt: clearOptedInAt
          ? null
          : (marketingEmailOptedInAt ?? this.marketingEmailOptedInAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          runtimeType == other.runtimeType &&
          marketingEmailOptIn == other.marketingEmailOptIn &&
          marketingEmailOptedInAt == other.marketingEmailOptedInAt;

  @override
  int get hashCode =>
      marketingEmailOptIn.hashCode ^ marketingEmailOptedInAt.hashCode;
}
