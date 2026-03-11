import '../../../core/monitoring/alert_rules.dart';

class AdminOfflineMutationAlertSettings {
  const AdminOfflineMutationAlertSettings({
    required this.minSignalCount,
    required this.retryRateWarningThreshold,
    required this.retryRateAlarmThreshold,
    required this.dropRateWarningThreshold,
    required this.dropRateAlarmThreshold,
    required this.attentionWarningCount,
    required this.authAlarmCount,
    required this.serverAlarmCount,
    required this.rateLimitWarningCount,
    required this.warningEscalationWindows,
    required this.alarmEscalationWindows,
  });

  factory AdminOfflineMutationAlertSettings.defaults() {
    return const AdminOfflineMutationAlertSettings(
      minSignalCount: AlertRules.offlineMutationMinSignalCount,
      retryRateWarningThreshold:
          AlertRules.offlineMutationRetryRateWarningThreshold,
      retryRateAlarmThreshold: AlertRules.offlineMutationRetryRateAlarmThreshold,
      dropRateWarningThreshold:
          AlertRules.offlineMutationDropRateWarningThreshold,
      dropRateAlarmThreshold: AlertRules.offlineMutationDropRateAlarmThreshold,
      attentionWarningCount: AlertRules.offlineMutationAttentionWarningCount,
      authAlarmCount: AlertRules.offlineMutationAuthAlarmCount,
      serverAlarmCount: AlertRules.offlineMutationServerAlarmCount,
      rateLimitWarningCount: AlertRules.offlineMutationRateLimitWarningCount,
      warningEscalationWindows: 2,
      alarmEscalationWindows: 2,
    );
  }

  factory AdminOfflineMutationAlertSettings.fromMap(Map<String, dynamic> map) {
    final defaults = AdminOfflineMutationAlertSettings.defaults();
    final retryWarning = _asDouble(
      map['retry_rate_warning_threshold'],
      defaults.retryRateWarningThreshold,
    );
    final retryAlarm = _asDouble(
      map['retry_rate_alarm_threshold'],
      defaults.retryRateAlarmThreshold,
    );
    final dropWarning = _asDouble(
      map['drop_rate_warning_threshold'],
      defaults.dropRateWarningThreshold,
    );
    final dropAlarm = _asDouble(
      map['drop_rate_alarm_threshold'],
      defaults.dropRateAlarmThreshold,
    );

    return AdminOfflineMutationAlertSettings(
      minSignalCount: _asInt(map['min_signal_count'], defaults.minSignalCount),
      retryRateWarningThreshold: retryWarning.clamp(0.0, 1.0),
      retryRateAlarmThreshold: retryAlarm.clamp(retryWarning, 1.0),
      dropRateWarningThreshold: dropWarning.clamp(0.0, 1.0),
      dropRateAlarmThreshold: dropAlarm.clamp(dropWarning, 1.0),
      attentionWarningCount: _asInt(
        map['attention_warning_count'],
        defaults.attentionWarningCount,
      ),
      authAlarmCount: _asInt(map['auth_alarm_count'], defaults.authAlarmCount),
      serverAlarmCount: _asInt(
        map['server_alarm_count'],
        defaults.serverAlarmCount,
      ),
      rateLimitWarningCount: _asInt(
        map['rate_limit_warning_count'],
        defaults.rateLimitWarningCount,
      ),
      warningEscalationWindows: _asInt(
        map['warning_escalation_windows'],
        defaults.warningEscalationWindows,
      ),
      alarmEscalationWindows: _asInt(
        map['alarm_escalation_windows'],
        defaults.alarmEscalationWindows,
      ),
    );
  }

  final int minSignalCount;
  final double retryRateWarningThreshold;
  final double retryRateAlarmThreshold;
  final double dropRateWarningThreshold;
  final double dropRateAlarmThreshold;
  final int attentionWarningCount;
  final int authAlarmCount;
  final int serverAlarmCount;
  final int rateLimitWarningCount;
  final int warningEscalationWindows;
  final int alarmEscalationWindows;

  Map<String, Object?> toMap() {
    return {
      'min_signal_count': minSignalCount,
      'retry_rate_warning_threshold': retryRateWarningThreshold,
      'retry_rate_alarm_threshold': retryRateAlarmThreshold,
      'drop_rate_warning_threshold': dropRateWarningThreshold,
      'drop_rate_alarm_threshold': dropRateAlarmThreshold,
      'attention_warning_count': attentionWarningCount,
      'auth_alarm_count': authAlarmCount,
      'server_alarm_count': serverAlarmCount,
      'rate_limit_warning_count': rateLimitWarningCount,
      'warning_escalation_windows': warningEscalationWindows,
      'alarm_escalation_windows': alarmEscalationWindows,
    };
  }

  AdminOfflineMutationAlertSettings copyWith({
    int? minSignalCount,
    double? retryRateWarningThreshold,
    double? retryRateAlarmThreshold,
    double? dropRateWarningThreshold,
    double? dropRateAlarmThreshold,
    int? attentionWarningCount,
    int? authAlarmCount,
    int? serverAlarmCount,
    int? rateLimitWarningCount,
    int? warningEscalationWindows,
    int? alarmEscalationWindows,
  }) {
    return AdminOfflineMutationAlertSettings(
      minSignalCount: minSignalCount ?? this.minSignalCount,
      retryRateWarningThreshold:
          retryRateWarningThreshold ?? this.retryRateWarningThreshold,
      retryRateAlarmThreshold:
          retryRateAlarmThreshold ?? this.retryRateAlarmThreshold,
      dropRateWarningThreshold:
          dropRateWarningThreshold ?? this.dropRateWarningThreshold,
      dropRateAlarmThreshold:
          dropRateAlarmThreshold ?? this.dropRateAlarmThreshold,
      attentionWarningCount:
          attentionWarningCount ?? this.attentionWarningCount,
      authAlarmCount: authAlarmCount ?? this.authAlarmCount,
      serverAlarmCount: serverAlarmCount ?? this.serverAlarmCount,
      rateLimitWarningCount:
          rateLimitWarningCount ?? this.rateLimitWarningCount,
      warningEscalationWindows:
          warningEscalationWindows ?? this.warningEscalationWindows,
      alarmEscalationWindows:
          alarmEscalationWindows ?? this.alarmEscalationWindows,
    );
  }
}

double _asDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? fallback;
}

int _asInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}
