import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import 'push_notification_service.dart';

final pushNotificationLifecycleProvider = Provider<void>((ref) {
  final service = ref.read(pushNotificationServiceProvider);

  void syncWithSession(Object? session) {
    if (session != null) {
      service.start();
    } else {
      service.stop();
    }
  }

  ref.listen(sessionProvider, (previous, next) => syncWithSession(next));
  ref.onDispose(service.stop);
  syncWithSession(ref.read(sessionProvider));
});
