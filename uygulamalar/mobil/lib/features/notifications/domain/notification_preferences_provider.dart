import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_preferences_repository.dart';
import 'notification_preferences_models.dart';

// ── AsyncNotifier state ────────────────────────────────────────────────────

/// Pazarlama e-posta izni state'i.
///
/// [AsyncLoading]: sayfa ilk yüklenirken / RPC çağrısı devam ederken.
/// [AsyncData]: backend değeri başarıyla alındı.
/// [AsyncError]: RPC kalıcı hata verdi — UI güvenli hata mesajı göstermeli.
final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier,
    NotificationPreferences>(NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  NotificationPreferencesRepository get _repo =>
      ref.read(notificationPreferencesRepositoryProvider);

  @override
  Future<NotificationPreferences> build() async {
    return _repo.getMyNotificationPreferences();
  }

  /// Toggle: pazarlama e-posta iznini [enabled] değeriyle günceller.
  ///
  /// Optimistik güncelleme yapar:
  ///   1. State hemen [enabled] değeriyle güncellenir (UI anlık döner).
  ///   2. RPC çağrılır.
  ///   3. RPC hata verirse eski değere geri dönülür ve hata state'e yazılır.
  Future<void> setMarketingEmailOptIn({required bool enabled}) async {
    // Önceki başarılı değeri sakla — hata durumunda geri almak için.
    final previous =
        state.asData?.value ?? NotificationPreferences.defaultValue;

    // Optimistik güncelleme
    state = AsyncData(
      previous.copyWith(
        marketingEmailOptIn: enabled,
        clearOptedInAt: !enabled,
      ),
    );

    try {
      await _repo.updateMyMarketingEmailOptIn(enabled: enabled);
      // Başarı: backend'den güncel değeri yeniden çek (opted_in_at dahil)
      final fresh = await _repo.getMyNotificationPreferences();
      state = AsyncData(fresh);
    } catch (e, st) {
      // Rollback: eski değere dön
      state = AsyncData(previous);
      // Hata bilgisini geçici olarak error state ile raporla;
      // UI bir sonraki build'de state.hasError ile bunu yakalayabilir.
      // Not: state=AsyncError kalıcı olmadan önce AsyncData(previous) set edildi,
      // bu yüzden son state data — aşağıdaki exception UI katmanına fırlatılır.
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Sayfayı yenileme — RPC'den güncel değeri çeker.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.getMyNotificationPreferences(),
    );
  }
}
