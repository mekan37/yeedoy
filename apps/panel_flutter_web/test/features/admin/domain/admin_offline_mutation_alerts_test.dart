import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/admin/domain/admin_offline_mutation_alert_settings.dart';
import 'package:yeedoy/features/admin/domain/admin_observability_models.dart';
import 'package:yeedoy/features/admin/domain/admin_offline_mutation_alerts.dart';

void main() {
  test('builds alarm summary for heavy retry and auth drift', () {
    final items = List<AdminOfflineMutationOutcome>.generate(
      12,
      (index) => AdminOfflineMutationOutcome(
        createdAt: DateTime(2026, 3, 7, 10, index),
        source: 'offline_submission_replay',
        kind: 'favorite',
        disposition: index < 5 ? 'retry' : 'success',
        retryCategory: index < 4 ? 'auth' : (index == 4 ? 'server' : null),
        retryCount: index < 5 ? index + 1 : 0,
        detail: null,
        userId: 'user-1',
        clientId: 'client-1',
      ),
    );

    final summary = AdminOfflineMutationHealthSummary.fromItems(items);

    expect(summary.severity, AdminOfflineMutationHealthSeverity.alarm);
    expect(summary.retryCount, 5);
    expect(summary.reasons.any((reason) => reason.contains('Auth retries')), isTrue);
  });

  test('builds warning summary for moderate drops', () {
    final items = <AdminOfflineMutationOutcome>[
      for (var index = 0; index < 10; index++)
        AdminOfflineMutationOutcome(
          createdAt: DateTime(2026, 3, 7, 11, index),
          source: 'offline_verify_replay',
          kind: 'price_vote',
          disposition: index < 1
              ? 'drop'
              : (index < 3 ? 'retry' : 'success'),
          retryCategory: index == 1 ? 'rate_limit' : null,
          retryCount: index < 3 ? 1 : 0,
          detail: null,
          userId: null,
          clientId: 'client-2',
        ),
    ];

    final summary = AdminOfflineMutationHealthSummary.fromItems(items);

    expect(summary.severity, AdminOfflineMutationHealthSeverity.warning);
    expect(summary.dropCount, 1);
    expect(summary.retryCount, 2);
  });

  test('builds healthy summary when replay outcomes are normal', () {
    final items = <AdminOfflineMutationOutcome>[
      for (var index = 0; index < 10; index++)
        AdminOfflineMutationOutcome(
          createdAt: DateTime(2026, 3, 7, 12, index),
          source: 'offline_submission_replay',
          kind: 'follow',
          disposition: index < 8 ? 'success' : 'resolve',
          retryCategory: null,
          retryCount: 0,
          detail: null,
          userId: null,
          clientId: 'client-3',
        ),
    ];

    final summary = AdminOfflineMutationHealthSummary.fromItems(items);

    expect(summary.severity, AdminOfflineMutationHealthSeverity.ok);
    expect(summary.reasons.single, 'Replay outcomes are within expected bounds.');
  });

  test('escalates when alarm persists across consecutive windows', () {
    final settings = AdminOfflineMutationAlertSettings.defaults();
    final current = AdminOfflineMutationHealthSummary.fromItems(
      [
        for (var index = 0; index < 12; index++)
          AdminOfflineMutationOutcome(
            createdAt: DateTime(2026, 3, 7, 13, index),
            source: 'offline_submission_replay',
            kind: 'favorite',
            disposition: index < 5 ? 'retry' : 'success',
            retryCategory: index < 3 ? 'server' : 'network',
            retryCount: index < 5 ? 1 : 0,
            detail: null,
            userId: null,
            clientId: 'client-a',
          ),
      ],
      settings: settings,
    );
    final previous = AdminOfflineMutationHealthSummary.fromItems(
      [
        for (var index = 0; index < 12; index++)
          AdminOfflineMutationOutcome(
            createdAt: DateTime(2026, 3, 7, 12, index),
            source: 'offline_submission_replay',
            kind: 'favorite',
            disposition: index < 5 ? 'retry' : 'success',
            retryCategory: index < 3 ? 'server' : 'network',
            retryCount: index < 5 ? 1 : 0,
            detail: null,
            userId: null,
            clientId: 'client-b',
          ),
      ],
      settings: settings,
    );

    final decision = AdminOfflineMutationEscalationDecision.evaluate(
      current: current,
      previous: previous,
      settings: settings,
    );

    expect(decision.shouldEscalate, isTrue);
    expect(decision.level, AdminOfflineMutationEscalationLevel.incident);
  });

  test('settings parser clamps invalid threshold ordering', () {
    final settings = AdminOfflineMutationAlertSettings.fromMap({
      'retry_rate_warning_threshold': 0.40,
      'retry_rate_alarm_threshold': 0.20,
      'drop_rate_warning_threshold': 0.30,
      'drop_rate_alarm_threshold': 0.10,
    });

    expect(settings.retryRateAlarmThreshold, 0.40);
    expect(settings.dropRateAlarmThreshold, 0.30);
  });
}
