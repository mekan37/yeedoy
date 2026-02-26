import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import 'push_notification_service.dart';

final pushNotificationLifecycleProvider = Provider<void>((ref) {
  void sync() {
    final session = ref.read(sessionProvider);
    final service = ref.read(pushNotificationServiceProvider);
    if (session != null) {
      service.start();
    } else {
      service.stop();
    }
  }

  ref.listen(sessionProvider, (previous, next) => sync());
  ref.onDispose(() => ref.read(pushNotificationServiceProvider).stop());
  sync();
});
