import '../analitik/uygulama_olaylari.dart';
import '../performans/performans_esikleri.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analitik/analitik_deposu.dart';
import '../analitik/analitik_istemcisi.dart';

class AlertRules {
  const AlertRules._();

  static const double crashFreeAlarmThreshold = 0.998;

  static bool shouldAlertCrashFree(double crashFreeRate) {
    return crashFreeRate < crashFreeAlarmThreshold;
  }

  static bool shouldAlertHomeTtiP95(int homeTtiP95Ms) {
    return homeTtiP95Ms > PerfSlo.homeTtiP95Ms;
  }

  static bool shouldAlertEdge429Spike({
    required int currentWindow429Count,
    required int baselineWindow429Count,
    double multiplier = 2.0,
  }) {
    if (baselineWindow429Count <= 0) return currentWindow429Count >= 20;
    return currentWindow429Count >=
        (baselineWindow429Count * multiplier).round();
  }
}

Future<void> logObservabilityAlert(
  WidgetRef ref, {
  required String alertType,
  required Map<String, Object?> meta,
  String source = 'observability',
}) async {
  final clientId = await getAnalyticsClientId();
  await ref
      .read(analyticsRepositoryProvider)
      .logEvent(
        eventName: AppEvents.observabilityAlert,
        source: source,
        clientId: clientId,
        meta: <String, dynamic>{'alert_type': alertType, ...meta},
      );
}
