import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/consent_repository.dart';
import '../domain/consent_state.dart';
import 'consent_local_repository.dart';

// ── Repository provider ────────────────────────────────────────────────────

final consentRepositoryProvider = Provider<ConsentRepository>(
  (ref) => ConsentLocalRepository(),
);

// ── State notifier ─────────────────────────────────────────────────────────

final consentNotifierProvider =
    StateNotifierProvider<ConsentNotifier, ConsentState>(
  (ref) => ConsentNotifier(ref.watch(consentRepositoryProvider)),
);

class ConsentNotifier extends StateNotifier<ConsentState> {
  ConsentNotifier(this._repository) : super(const ConsentState()) {
    _init();
  }

  final ConsentRepository _repository;

  Future<void> _init() async {
    final saved = await _repository.load();
    if (mounted) state = saved;
  }

  /// Kaydedilmiş onayı yeniden yükler.
  Future<void> load() async {
    final saved = await _repository.load();
    if (mounted) state = saved;
  }

  /// Tüm onayları kabul et (Analytics + Marketing + DataRetention).
  Future<void> grantAll() async {
    final next = ConsentState(
      analytics: ConsentStatus.granted,
      marketing: ConsentStatus.granted,
      dataRetention: ConsentStatus.granted,
      consentedAt: DateTime.now(),
    );
    await _repository.save(next);
    if (mounted) state = next;
  }

  /// Sadece analitik onayını ver; pazarlama reddedilir.
  Future<void> grantAnalyticsOnly() async {
    final next = ConsentState(
      analytics: ConsentStatus.granted,
      marketing: ConsentStatus.denied,
      dataRetention: ConsentStatus.granted,
      consentedAt: DateTime.now(),
    );
    await _repository.save(next);
    if (mounted) state = next;
  }

  /// Tüm isteğe bağlı onayları reddet; zorunlu dataRetention kabul edilir.
  Future<void> deny() async {
    final next = ConsentState(
      analytics: ConsentStatus.denied,
      marketing: ConsentStatus.denied,
      dataRetention: ConsentStatus.granted,
      consentedAt: DateTime.now(),
    );
    await _repository.save(next);
    if (mounted) state = next;
  }

  /// Belirli bir onayı güncelle.
  Future<void> update({
    ConsentStatus? analytics,
    ConsentStatus? marketing,
    ConsentStatus? dataRetention,
  }) async {
    final next = state.copyWith(
      analytics: analytics,
      marketing: marketing,
      dataRetention: dataRetention,
      consentedAt: DateTime.now(),
    );
    await _repository.save(next);
    if (mounted) state = next;
  }

  /// KVKK veri silme talebi — tüm onay verilerini siler ve state'i sıfırlar.
  Future<void> clearAll() async {
    await _repository.clear();
    if (mounted) state = const ConsentState();
  }
}
