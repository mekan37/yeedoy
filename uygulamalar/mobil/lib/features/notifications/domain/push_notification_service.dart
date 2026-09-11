import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/inbox_repository.dart';
import 'inbox_provider.dart';
import 'notification_target_path_resolver.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(ref);
});

class PushTapIntent {
  const PushTapIntent({required this.route, required this.nonce});

  final String route;
  final int nonce;
}

final pushTapIntentProvider =
    NotifierProvider<PushTapIntentNotifier, PushTapIntent?>(
      PushTapIntentNotifier.new,
    );

/// True if the user has explicitly denied notification permission.
final notificationsDeniedProvider =
    NotifierProvider<NotificationsDeniedNotifier, bool>(
      NotificationsDeniedNotifier.new,
    );

class NotificationsDeniedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void deny() => state = true;
}

class PushTapIntentNotifier extends Notifier<PushTapIntent?> {
  @override
  PushTapIntent? build() => null;

  void emit(String route) {
    state = PushTapIntent(
      route: route,
      nonce: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void clear() => state = null;
}

class PushNotificationService {
  PushNotificationService(this.ref);

  final Ref ref;
  bool _started = false;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _messageOpenSub;
  String? _lastToken;

  Future<void> start() async {
    if (_started) return;
    final platform = _mobilePlatform();
    if (platform == null) return;
    final user = ref.read(userProvider);
    if (user == null) return;

    final messaging = FirebaseMessaging.instance;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        ref.read(notificationsDeniedProvider.notifier).deny();
      }
    } catch (_) {
      // Some platforms may throw when notification permission is unsupported.
    }

    // Sunucuya cihaz kaydı ağ hatasıyla başarısız olabilir — bu, mesaj
    // dinleyicilerinin (push tıklaması, gelen kutusu canlı güncellemesi)
    // kurulmasını ASLA engellememeli. Önceden bu adım hataya düşünce
    // `start()` erken çıkıyor ve `_started` zaten true olduğu için o oturum
    // boyunca bir daha hiç denenmiyordu.
    try {
      await _registerCurrentToken(messaging);
    } catch (_) {
      // no-op — bir sonraki onTokenRefresh veya foreground dönüşünde
      // yeniden denenebilir; kritik olan dinleyicilerin kurulması.
    }

    _tokenSub = messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });

    _messageSub = FirebaseMessaging.onMessage.listen((_) {
      // Keep in-app inbox and badge live on foreground push.
      unawaited(ref.read(inboxProvider.notifier).refresh());
    });

    _messageOpenSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _emitPushTapIntent(message.data);
    });

    // Dinleyiciler kuruldu — artık gerçekten "başlatılmış" sayılabilir.
    _started = true;

    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _emitPushTapIntent(initialMessage.data);
      }
    } catch (_) {
      // no-op
    }
  }

  Future<void> _registerCurrentToken(FirebaseMessaging messaging) async {
    String? token;
    try {
      token = await messaging.getToken();
    } catch (_) {
      token = null;
    }
    if (token == null || token.trim().isEmpty) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    final platform = _mobilePlatform();
    if (platform == null) return;
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    final repo = ref.read(inboxRepositoryProvider);
    await repo.registerDevice(fcmToken: token, platform: platform, appVersion: appVersion);
    _lastToken = token;
  }

  /// Cihaz push kaydını sunucudan siler ve dinleyicileri kapatır.
  ///
  /// Önceden `void` + `unawaited(...)` idi: hem çağıran taraf bu işlemin
  /// bittiğini asla bekleyemiyordu hem de sign-out akışında bu, sunucu
  /// isteği tamamlanmadan `auth.signOut()` çağrılmasına (ve JWT geçersiz
  /// olduğu için unregister'ın sessizce 401 ile başarısız olmasına) yol
  /// açıyordu. Artık `Future<void>` — sign-out akışı bunu bekleyip ANCAK
  /// ondan sonra oturumu kapatmalı.
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    try {
      final token = _lastToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await ref.read(inboxRepositoryProvider).unregisterDevice(fcmToken: token);
      }
    } catch (_) {
      // no-op — cihaz kaydı sunucuda kalabilir, kritik değil.
    } finally {
      _lastToken = null;
    }
    await _tokenSub?.cancel();
    _tokenSub = null;
    await _messageSub?.cancel();
    _messageSub = null;
    await _messageOpenSub?.cancel();
    _messageOpenSub = null;
  }

  void simulatePushPayload(
    Map<String, dynamic> data, {
    String source = 'devtools_push_simulator',
  }) {
    _emitPushTapIntent(data, source: source);
  }

  void _emitPushTapIntent(
    Map<String, dynamic> data, {
    String source = 'push_notification_service',
  }) {
    final route = resolvePushTapRoute(data);
    if (route == null) return;
    ref.read(pushTapIntentProvider.notifier).emit(route);
    unawaited(_logPushOpen(data: data, route: route, source: source));
  }

  Future<void> _logPushOpen({
    required Map<String, dynamic> data,
    required String route,
    required String source,
  }) async {
    final type = (data['type'] ?? '').toString();
    final businessId = (data['business_id'] ?? '').toString().trim();
    final menuId = (data['menu_id'] ?? '').toString().trim();
    final clientId = await getAnalyticsClientId();

    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: _eventNameForType(type),
          businessId: businessId.isEmpty ? null : businessId,
          menuId: menuId.isEmpty ? null : menuId,
          source: source,
          clientId: clientId,
          meta: {
            'type': type,
            'target_path': route,
            'transport': 'push_tap',
          },
        );
  }

  String _eventNameForType(String type) {
    switch (type) {
      case 'price_suggestion_result':
      case 'price_verification_result':
      case 'favorite_price_changed':
      case 'owner_new_price_suggestion':
        return AppEvents.priceChangePushOpen;
      case 'review_reply':
      case 'owner_new_review':
        return AppEvents.commentReplyPushOpen;
      case 'favorite_revisit_reminder':
        return AppEvents.notificationOpen;
      default:
        return AppEvents.notificationOpen;
    }
  }

  String? _mobilePlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }
}
