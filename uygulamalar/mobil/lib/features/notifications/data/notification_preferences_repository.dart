import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../domain/notification_preferences_models.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return _NotificationPreferencesRepositoryImpl(ref.watch(supabaseProvider));
});

/// Global platform pazarlama e-posta izni repository arayüzü.
///
/// RPC'ler:
///   - [getMyNotificationPreferences]: get_my_notification_preferences_v1()
///   - [updateMyMarketingEmailOptIn]: update_my_marketing_email_opt_in_v1(boolean)
///
/// Kesinlikle karıştırılmayacaklar:
///   - [business_follows.is_subscribed_email]: işletme bazlı abonelik.
///     Bu repository o alana dokunmaz.
///   - SharedPreferences: pazarlama e-posta izni için source-of-truth DEĞİL.
///
/// Migration bağımlılığı:
///   Bu repository, [user_profiles.marketing_email_opt_in] sütununun
///   üretimde mevcut olmasını gerektirir (migration 20260620000001).
///   Migration henüz uygulanmamışsa RPC hata verir ve bu repository
///   [NotificationPreferences.defaultValue] döndürerek güvenle başarısız olur.
abstract class NotificationPreferencesRepository {
  /// Kullanıcının global pazarlama e-posta izin durumunu okur.
  ///
  /// Başarıda [NotificationPreferences] döner.
  /// Hata durumunda (oturum yok, migration yok, ağ hatası)
  /// [NotificationPreferences.defaultValue] döner — asla exception fırlatmaz.
  Future<NotificationPreferences> getMyNotificationPreferences();

  /// Kullanıcının global pazarlama e-posta iznini günceller.
  ///
  /// [enabled] = true  → backend: marketing_email_opt_in=true, opted_in_at=now()
  /// [enabled] = false → backend: marketing_email_opt_in=false, opted_in_at=NULL
  ///
  /// Flutter doğrudan tablo güncellemesi yapmaz; yalnızca RPC kullanılır.
  /// business_follows.is_subscribed_email'e HİÇBİR ZAMAN dokunulmaz.
  ///
  /// Exception fırlatır — çağıran katman UI'da hatayı ele almalı.
  Future<void> updateMyMarketingEmailOptIn({required bool enabled});
}

class _NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  _NotificationPreferencesRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  /// Kullanıcının global pazarlama e-posta izin durumunu okur.
  ///
  /// Başarıda [NotificationPreferences] döner.
  /// Hata durumunda (oturum yok, migration yok, ağ hatası)
  /// [NotificationPreferences.defaultValue] döner — asla exception fırlatmaz.
  @override
  Future<NotificationPreferences> getMyNotificationPreferences() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return NotificationPreferences.defaultValue;

    try {
      final result = await _supabase
          .rpc('get_my_notification_preferences_v1')
          .single();

      final map = (result as Map).cast<String, dynamic>();
      return NotificationPreferences.fromRpcJson(map);
    } on PostgrestException catch (e) {
      // Migration henüz uygulanmamış (PGRST202: function not found) veya
      // sütun yok (42703) — güvenli default döndür.
      _logSafe(
        'getMyNotificationPreferences: RPC hatası — '
        'migration uygulanmamış olabilir. code=${e.code}',
      );
      return NotificationPreferences.defaultValue;
    } catch (e) {
      _logSafe('getMyNotificationPreferences: beklenmedik hata: $e');
      return NotificationPreferences.defaultValue;
    }
  }

  /// Kullanıcının global pazarlama e-posta iznini günceller.
  ///
  /// [enabled] = true  → backend: marketing_email_opt_in=true, opted_in_at=now()
  /// [enabled] = false → backend: marketing_email_opt_in=false, opted_in_at=NULL
  ///
  /// Flutter doğrudan tablo güncellemesi yapmaz; yalnızca RPC kullanılır.
  /// business_follows.is_subscribed_email'e HİÇBİR ZAMAN dokunulmaz.
  ///
  /// Exception fırlatır — çağıran katman UI'da hatayı ele almalı.
  @override
  Future<void> updateMyMarketingEmailOptIn({required bool enabled}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw StateError('auth_required');

    await _supabase.rpc(
      'update_my_marketing_email_opt_in_v1',
      params: {'p_value': enabled},
    );
  }

  void _logSafe(String message) {
    // Üretimde loglama framework'üne yönlendirilebilir.
    // Şu an sadece debug modda yazdır.
    assert(() {
      // ignore: avoid_print
      print('[NotificationPreferencesRepository] $message');
      return true;
    }());
  }
}
