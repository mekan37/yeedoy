import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consent_repository.dart';
import '../domain/consent_state.dart';

/// SharedPreferences destekli KVKK onay deposu.
///
/// Tüm anahtarlar `kvkk_consent_` ön ekiyle saklanır.
class ConsentLocalRepository implements ConsentRepository {
  static const _kAnalytics = 'kvkk_consent_analytics';
  static const _kMarketing = 'kvkk_consent_marketing';
  static const _kDataRetention = 'kvkk_consent_data_retention';
  static const _kConsentedAt = 'kvkk_consent_consented_at';

  @override
  Future<ConsentState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ConsentState(
      analytics: _read(prefs, _kAnalytics),
      marketing: _read(prefs, _kMarketing),
      dataRetention: _read(prefs, _kDataRetention),
      consentedAt: _readDate(prefs, _kConsentedAt),
    );
  }

  @override
  Future<void> save(ConsentState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAnalytics, state.analytics.name);
    await prefs.setString(_kMarketing, state.marketing.name);
    await prefs.setString(_kDataRetention, state.dataRetention.name);
    if (state.consentedAt != null) {
      await prefs.setString(
        _kConsentedAt,
        state.consentedAt!.toIso8601String(),
      );
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAnalytics);
    await prefs.remove(_kMarketing);
    await prefs.remove(_kDataRetention);
    await prefs.remove(_kConsentedAt);
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  static ConsentStatus _read(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return ConsentStatus.unknown;
    return ConsentStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ConsentStatus.unknown,
    );
  }

  static DateTime? _readDate(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
