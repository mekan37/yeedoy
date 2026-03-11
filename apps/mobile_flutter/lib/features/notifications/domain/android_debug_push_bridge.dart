import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_service.dart';

const _debugPushEventChannel = EventChannel(
  'com.yeedoy.app/debug_push_payload',
);

final androidDebugPushBridgeProvider = Provider<AndroidDebugPushBridge>((ref) {
  return const AndroidDebugPushBridge();
});

final androidDebugPushLifecycleProvider = Provider<void>((ref) {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final bridge = ref.read(androidDebugPushBridgeProvider);
  final service = ref.read(pushNotificationServiceProvider);
  final sub = bridge.payloadStream.listen(
    (payload) {
      assert(() {
        debugPrint('[AndroidDebugPushBridge] payload=$payload');
        return true;
      }());
      service.simulatePushPayload(
        payload,
        source: 'android_debug_push_bridge',
      );
    },
    onError: (Object error, StackTrace stackTrace) {
      assert(() {
        debugPrint('[AndroidDebugPushBridge] error=$error');
        return true;
      }());
    },
  );
  ref.onDispose(sub.cancel);
});

class AndroidDebugPushBridge {
  const AndroidDebugPushBridge();

  Stream<Map<String, dynamic>> get payloadStream {
    return _debugPushEventChannel.receiveBroadcastStream().map((event) {
      if (event is! Map) return const <String, dynamic>{};
      return event.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }).where((payload) => payload.isNotEmpty);
  }
}
