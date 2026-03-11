import 'admin_offline_mutation_alert_settings.dart';
import 'admin_observability_models.dart';

enum AdminOfflineMutationHealthSeverity { ok, warning, alarm }

enum AdminOfflineMutationEscalationLevel { none, opsWatch, opsAction, incident }

class AdminOfflineMutationHealthSummary {
  const AdminOfflineMutationHealthSummary({
    required this.severity,
    required this.totalCount,
    required this.successCount,
    required this.resolveCount,
    required this.retryCount,
    required this.dropCount,
    required this.attentionCount,
    required this.retryRate,
    required this.dropRate,
    required this.lowSignal,
    required this.authRetryCount,
    required this.serverRetryCount,
    required this.rateLimitRetryCount,
    required this.reasons,
  });

  factory AdminOfflineMutationHealthSummary.fromItems(
    List<AdminOfflineMutationOutcome> items, {
    AdminOfflineMutationAlertSettings? settings,
  }) {
    final rules = settings ?? AdminOfflineMutationAlertSettings.defaults();
    final totalCount = items.length;
    final dispositionCounts = _countBy(items.map((item) => item.disposition));
    final retryCategoryCounts = _countBy(
      items
          .map((item) => item.retryCategory)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty),
    );
    final successCount = dispositionCounts['success'] ?? 0;
    final resolveCount = dispositionCounts['resolve'] ?? 0;
    final retryCount = dispositionCounts['retry'] ?? 0;
    final dropCount = dispositionCounts['drop'] ?? 0;
    final attentionCount = retryCount + dropCount;
    final retryRate = totalCount == 0 ? 0.0 : retryCount / totalCount;
    final dropRate = totalCount == 0 ? 0.0 : dropCount / totalCount;
    final authRetries = retryCategoryCounts['auth'] ?? 0;
    final serverRetries = retryCategoryCounts['server'] ?? 0;
    final rateLimitRetries = retryCategoryCounts['rate_limit'] ?? 0;
    final lowSignal = totalCount < rules.minSignalCount;

    final reasons = <String>[];
    var severity = AdminOfflineMutationHealthSeverity.ok;

    void escalate(AdminOfflineMutationHealthSeverity next) {
      if (next.index > severity.index) {
        severity = next;
      }
    }

    if (totalCount == 0) {
      reasons.add('No replay outcomes in the selected window.');
    } else {
      if (!lowSignal &&
          dropCount > 0 &&
          dropRate >= rules.dropRateAlarmThreshold) {
        escalate(AdminOfflineMutationHealthSeverity.alarm);
        reasons.add(
          'Drop rate ${_formatPercent(dropRate)} exceeds the alarm threshold (${_formatPercent(rules.dropRateAlarmThreshold)}).',
        );
      } else if (!lowSignal &&
          dropCount > 0 &&
          dropRate >= rules.dropRateWarningThreshold) {
        escalate(AdminOfflineMutationHealthSeverity.warning);
        reasons.add(
          'Drop rate ${_formatPercent(dropRate)} is above the warning band (${_formatPercent(rules.dropRateWarningThreshold)}).',
        );
      }

      if (!lowSignal &&
          retryCount > 0 &&
          retryRate >= rules.retryRateAlarmThreshold) {
        escalate(AdminOfflineMutationHealthSeverity.alarm);
        reasons.add(
          'Retry rate ${_formatPercent(retryRate)} exceeds the alarm threshold (${_formatPercent(rules.retryRateAlarmThreshold)}).',
        );
      } else if (!lowSignal &&
          retryCount > 0 &&
          retryRate >= rules.retryRateWarningThreshold) {
        escalate(AdminOfflineMutationHealthSeverity.warning);
        reasons.add(
          'Retry rate ${_formatPercent(retryRate)} is above the warning band (${_formatPercent(rules.retryRateWarningThreshold)}).',
        );
      }

      if (authRetries >= rules.authAlarmCount) {
        escalate(AdminOfflineMutationHealthSeverity.alarm);
        reasons.add(
          'Auth retries ($authRetries) reached the escalation hotspot (${rules.authAlarmCount}).',
        );
      }

      if (serverRetries >= rules.serverAlarmCount) {
        escalate(AdminOfflineMutationHealthSeverity.alarm);
        reasons.add(
          'Server retries ($serverRetries) reached the escalation hotspot (${rules.serverAlarmCount}).',
        );
      }

      if (rateLimitRetries >= rules.rateLimitWarningCount) {
        escalate(AdminOfflineMutationHealthSeverity.warning);
        reasons.add(
          'Rate-limit retries ($rateLimitRetries) reached the warning hotspot (${rules.rateLimitWarningCount}).',
        );
      }

      if (attentionCount >= rules.attentionWarningCount) {
        escalate(AdminOfflineMutationHealthSeverity.warning);
        reasons.add(
          'Attention items reached $attentionCount in this window (threshold ${rules.attentionWarningCount}).',
        );
      }

      if (lowSignal) {
        reasons.add(
          'Signal is still low ($totalCount events); interpret spikes carefully.',
        );
      }

      if (reasons.isEmpty) {
        reasons.add('Replay outcomes are within expected bounds.');
      }
    }

    return AdminOfflineMutationHealthSummary(
      severity: severity,
      totalCount: totalCount,
      successCount: successCount,
      resolveCount: resolveCount,
      retryCount: retryCount,
      dropCount: dropCount,
      attentionCount: attentionCount,
      retryRate: retryRate,
      dropRate: dropRate,
      lowSignal: lowSignal,
      authRetryCount: authRetries,
      serverRetryCount: serverRetries,
      rateLimitRetryCount: rateLimitRetries,
      reasons: reasons,
    );
  }

  final AdminOfflineMutationHealthSeverity severity;
  final int totalCount;
  final int successCount;
  final int resolveCount;
  final int retryCount;
  final int dropCount;
  final int attentionCount;
  final double retryRate;
  final double dropRate;
  final bool lowSignal;
  final int authRetryCount;
  final int serverRetryCount;
  final int rateLimitRetryCount;
  final List<String> reasons;

  String get title {
    switch (severity) {
      case AdminOfflineMutationHealthSeverity.alarm:
        return 'Offline replay alarm';
      case AdminOfflineMutationHealthSeverity.warning:
        return 'Offline replay warning';
      case AdminOfflineMutationHealthSeverity.ok:
        return 'Offline replay healthy';
    }
  }

  String get statusLabel {
    switch (severity) {
      case AdminOfflineMutationHealthSeverity.alarm:
        return 'Alarm';
      case AdminOfflineMutationHealthSeverity.warning:
        return 'Warning';
      case AdminOfflineMutationHealthSeverity.ok:
        return 'Healthy';
    }
  }

  String get summaryLine {
    return 'Total $totalCount | Success $successCount | Resolve $resolveCount | Retry ${_formatPercent(retryRate)} | Drop ${_formatPercent(dropRate)}';
  }
}

class AdminOfflineMutationEscalationDecision {
  const AdminOfflineMutationEscalationDecision({
    required this.level,
    required this.target,
    required this.reason,
    required this.shouldEscalate,
  });

  factory AdminOfflineMutationEscalationDecision.evaluate({
    required AdminOfflineMutationHealthSummary current,
    required AdminOfflineMutationHealthSummary previous,
    required AdminOfflineMutationAlertSettings settings,
  }) {
    if (current.severity == AdminOfflineMutationHealthSeverity.ok) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.none,
        target: 'none',
        reason: 'Current replay window is healthy.',
        shouldEscalate: false,
      );
    }

    if (current.serverRetryCount >= settings.serverAlarmCount) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.incident,
        target: 'backend_oncall',
        reason: 'Server retry hotspot suggests backend instability.',
        shouldEscalate: true,
      );
    }

    if (current.authRetryCount >= settings.authAlarmCount) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.opsAction,
        target: 'auth_session_owner',
        reason: 'Auth retry hotspot suggests session drift or token issues.',
        shouldEscalate: true,
      );
    }

    final currentIsAlarm =
        current.severity == AdminOfflineMutationHealthSeverity.alarm;
    final previousIsAlarm =
        previous.severity == AdminOfflineMutationHealthSeverity.alarm;
    if (currentIsAlarm &&
        settings.alarmEscalationWindows <= 1 &&
        !current.lowSignal) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.incident,
        target: 'ops_incident',
        reason: 'Alarm threshold is configured to escalate immediately.',
        shouldEscalate: true,
      );
    }
    if (currentIsAlarm &&
        previousIsAlarm &&
        settings.alarmEscalationWindows <= 2 &&
        !current.lowSignal) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.incident,
        target: 'ops_incident',
        reason: 'Alarm persisted across consecutive replay windows.',
        shouldEscalate: true,
      );
    }

    final currentIsWarning =
        current.severity == AdminOfflineMutationHealthSeverity.warning;
    final previousIsWarning =
        previous.severity == AdminOfflineMutationHealthSeverity.warning;
    if (currentIsWarning &&
        previousIsWarning &&
        settings.warningEscalationWindows <= 2 &&
        !current.lowSignal) {
      return const AdminOfflineMutationEscalationDecision(
        level: AdminOfflineMutationEscalationLevel.opsAction,
        target: 'ops_triage',
        reason: 'Warning persisted across consecutive replay windows.',
        shouldEscalate: true,
      );
    }

    return AdminOfflineMutationEscalationDecision(
      level: AdminOfflineMutationEscalationLevel.opsWatch,
      target: 'ops_watch',
      reason: current.severity == AdminOfflineMutationHealthSeverity.alarm
          ? 'Monitor the next replay window before escalating.'
          : 'Warning is present but has not yet met escalation persistence rules.',
      shouldEscalate: false,
    );
  }

  final AdminOfflineMutationEscalationLevel level;
  final String target;
  final String reason;
  final bool shouldEscalate;

  String get label {
    switch (level) {
      case AdminOfflineMutationEscalationLevel.none:
        return 'No escalation';
      case AdminOfflineMutationEscalationLevel.opsWatch:
        return 'Ops watch';
      case AdminOfflineMutationEscalationLevel.opsAction:
        return 'Ops action';
      case AdminOfflineMutationEscalationLevel.incident:
        return 'Incident';
    }
  }
}

Map<String, int> _countBy(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    final normalized = value.trim().isEmpty ? 'unknown' : value.trim();
    counts.update(normalized, (current) => current + 1, ifAbsent: () => 1);
  }
  return counts;
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}
