import '../analytics/app_events.dart';
import '../perf/perf_slo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_repository.dart';
import '../analytics/analytics_client.dart';

class AlertRules {
  const AlertRules._();

  static const double crashFreeAlarmThreshold = 0.998;
  static const int offlineMutationMinSignalCount = 8;
  static const double offlineMutationRetryRateWarningThreshold = 0.15;
  static const double offlineMutationRetryRateAlarmThreshold = 0.35;
  static const double offlineMutationDropRateWarningThreshold = 0.08;
  static const double offlineMutationDropRateAlarmThreshold = 0.15;
  static const int offlineMutationAttentionWarningCount = 4;
  static const int offlineMutationAuthAlarmCount = 3;
  static const int offlineMutationServerAlarmCount = 3;
  static const int offlineMutationRateLimitWarningCount = 4;

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

  static bool shouldWarnOfflineMutationRetryRate({
    required int totalCount,
    required int retryCount,
  }) {
    if (totalCount < offlineMutationMinSignalCount || retryCount <= 0) {
      return false;
    }
    return (retryCount / totalCount) >=
        offlineMutationRetryRateWarningThreshold;
  }

  static bool shouldAlertOfflineMutationRetryRate({
    required int totalCount,
    required int retryCount,
  }) {
    if (totalCount < offlineMutationMinSignalCount || retryCount <= 0) {
      return false;
    }
    return (retryCount / totalCount) >= offlineMutationRetryRateAlarmThreshold;
  }

  static bool shouldWarnOfflineMutationDropRate({
    required int totalCount,
    required int dropCount,
  }) {
    if (totalCount < offlineMutationMinSignalCount || dropCount <= 0) {
      return false;
    }
    return (dropCount / totalCount) >= offlineMutationDropRateWarningThreshold;
  }

  static bool shouldAlertOfflineMutationDropRate({
    required int totalCount,
    required int dropCount,
  }) {
    if (totalCount < offlineMutationMinSignalCount || dropCount <= 0) {
      return false;
    }
    return (dropCount / totalCount) >= offlineMutationDropRateAlarmThreshold;
  }

  static bool shouldWarnOfflineMutationAttentionCount({
    required int attentionCount,
  }) {
    return attentionCount >= offlineMutationAttentionWarningCount;
  }

  static bool shouldAlertOfflineMutationAuthRetries({
    required int authRetryCount,
  }) {
    return authRetryCount >= offlineMutationAuthAlarmCount;
  }

  static bool shouldAlertOfflineMutationServerRetries({
    required int serverRetryCount,
  }) {
    return serverRetryCount >= offlineMutationServerAlarmCount;
  }

  static bool shouldWarnOfflineMutationRateLimitRetries({
    required int rateLimitRetryCount,
  }) {
    return rateLimitRetryCount >= offlineMutationRateLimitWarningCount;
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
