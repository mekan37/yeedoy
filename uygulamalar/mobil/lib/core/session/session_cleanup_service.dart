import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/auth_providers.dart';
import '../../features/favorites/domain/favorite_status_provider.dart';
import '../../features/notifications/domain/push_notification_service.dart';
import '../cache/request_cache.dart';
import '../network/supabase_provider.dart';
import '../storage/inbox_prefs.dart';
import '../storage/offline_mutation_queue.dart';

/// Oturum/hesap yaşam döngüsünü tek bir yerden yönetir.
///
/// Önceden: logout ne çevrimdışı yazma kuyruğunu, ne [RequestCache]'i, ne
/// gelen kutusu önbelleğini, ne de sunucudaki push cihaz kaydını
/// temizliyordu — ortak/paylaşılan bir cihazda A'nın verisi ve bekleyen
/// yazma işlemleri B'nin hesabına karışabiliyordu. Ayrıca 3 farklı çıkış
/// yolu vardı (`AuthService.signOut()`, ve iki yerde doğrudan
/// `Supabase.instance.client.auth.signOut()`); yeni eklenecek bir temizlik
/// mantığı o iki yolda sessizce atlanıyordu.
///
/// Artık: UI kodu ASLA `client.auth.signOut()`'u doğrudan çağırmamalı,
/// bunun yerine `ref.read(sessionCleanupServiceProvider).signOut()`
/// kullanmalı. Sıralama önemli: push cihaz kaydı, oturum (ve dolayısıyla
/// JWT) geçersiz olmadan ÖNCE ve `await` edilerek sunucudan silinir;
/// yerel önbellek/kuyruk temizliği ise [sessionCleanupLifecycleProvider]
/// aracılığıyla `sessionProvider`'daki her değişimde reaktif olarak çalışır
/// (böylece açık çıkış dışındaki oturum sonlanmalarını — örn. token'ın
/// sunucu tarafından iptali — da kapsar).
class SessionCleanupService {
  SessionCleanupService(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    try {
      await _ref.read(pushNotificationServiceProvider).stop();
    } catch (_) {
      // Push unregister en kötü ihtimalle cihaz kaydını sunucuda bırakır;
      // bu, oturumu kapatmayı engellememeli.
    }
    await _ref.read(supabaseProvider).auth.signOut(scope: SignOutScope.global);
  }

  /// [sessionCleanupLifecycleProvider] tarafından `sessionProvider` her
  /// değiştiğinde (sign-out, sign-in, kullanıcı değişimi) çağrılır.
  Future<void> onSessionChanged(String? newUserId) async {
    await OfflineMutationQueueStore.dropForUserMismatch(keepUserId: newUserId);
    RequestCache.shared.clearAll();
    await InboxPrefs.clear();
    if (newUserId == null) {
      _ref.read(favoriteIdsProvider.notifier).clear();
      _ref.read(favoriteStatusCacheProvider.notifier).clear();
    }
  }
}

final sessionCleanupServiceProvider = Provider<SessionCleanupService>((ref) {
  return SessionCleanupService(ref);
});

final sessionCleanupLifecycleProvider = Provider<void>((ref) {
  final service = ref.read(sessionCleanupServiceProvider);
  String? lastUserId = ref.read(userProvider)?.id;

  ref.listen(userProvider, (previous, next) {
    final nextId = next?.id;
    if (nextId == lastUserId) return;
    lastUserId = nextId;
    // ignore: discarded_futures
    service.onSessionChanged(nextId);
  });
});
