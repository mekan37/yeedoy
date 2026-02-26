import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/domain/auth_providers.dart';
import 'admin_access_provider.dart';
import 'admin_realtime_service.dart';

final adminRealtimeLifecycleProvider = Provider<void>((ref) {
  if (!kIsWeb) return;

  void sync() {
    final session = ref.read(sessionProvider);
    final adminAccess = ref.read(adminAccessProvider).value ?? false;
    final canStart = session != null && adminAccess;
    final service = ref.read(adminRealtimeServiceProvider);
    if (canStart) {
      service.start();
    } else {
      service.stop();
    }
  }

  ref.listen(sessionProvider, (previous, next) => sync());
  ref.listen(adminAccessProvider, (previous, next) => sync());
  ref.onDispose(() => ref.read(adminRealtimeServiceProvider).stop());

  sync();
});
