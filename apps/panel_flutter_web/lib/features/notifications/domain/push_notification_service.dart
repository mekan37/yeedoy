import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/inbox_repository.dart';
import 'inbox_provider.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  PushNotificationService(this.ref);

  final Ref ref;
  bool _started = false;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  String? _lastToken;

  Future<void> start() async {
    if (_started) return;
    final user = ref.read(userProvider);
    if (user == null) return;

    _started = true;
    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {
      // Some platforms may throw when notification permission is unsupported.
    }

    await _registerCurrentToken(messaging);

    _tokenSub = messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });

    _messageSub = FirebaseMessaging.onMessage.listen((_) {
      // Keep in-app inbox and badge live on foreground push.
      unawaited(ref.read(inboxProvider.notifier).refresh());
    });
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
    final repo = ref.read(inboxRepositoryProvider);
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
    await repo.registerDevice(
      fcmToken: token,
      platform: kIsWeb ? 'web' : platform,
    );
    _lastToken = token;
  }

  void stop() {
    if (!_started) return;
    _started = false;
    unawaited(() async {
      try {
        final token = _lastToken ?? await FirebaseMessaging.instance.getToken();
        if (token == null || token.trim().isEmpty) return;
        await ref
            .read(inboxRepositoryProvider)
            .unregisterDevice(fcmToken: token);
      } catch (_) {
        // no-op
      } finally {
        _lastToken = null;
      }
    }());
    _tokenSub?.cancel();
    _tokenSub = null;
    _messageSub?.cancel();
    _messageSub = null;
  }
}
