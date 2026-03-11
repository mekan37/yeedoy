import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/admin/domain/admin_audit_models.dart';
import 'package:yeedoy/features/admin/domain/admin_queue_explainer.dart';
import 'package:yeedoy/features/admin/domain/admin_queue_models.dart';

void main() {
  test('price suggestion support explains conflict and anomaly signals', () {
    final item = AdminQueueItem(
      id: 'price-1',
      type: AdminQueueItemType.priceSuggestion,
      status: 'pending',
      createdAt: DateTime(2026, 3, 6),
      ageHours: 12,
      slaHours: 48,
      slaBreached: false,
      title: 'Latte',
      subtitle: '120 -> 220 TRY',
      detail: const {
        'quality_confidence': 0.42,
        'anomaly_score': 0.81,
        'conflict_state': 'queued',
        'conflict_variants_24h': 3,
        'anomaly_flags': ['price_conflict', 'high_increase'],
        'created_by_reputation': 32,
        'created_by_risk_score': 66,
        'business_quality_score': 44.0,
      },
      totalCount: 1,
    );

    final support = buildAdminQueueDecisionSupport(item);

    expect(support.pendingReasonCode, 'conflict_and_anomaly');
    expect(support.anomalyReasonCode, 'high_anomaly_score');
    expect(
      support.insights.any((insight) => insight.code == 'actor_risk'),
      isTrue,
    );
    expect(
      support.insights.any((insight) => insight.code == 'anomaly_flags'),
      isTrue,
    );
  });

  test('claim support highlights missing evidence', () {
    final item = AdminQueueItem(
      id: 'claim-1',
      type: AdminQueueItemType.claim,
      status: 'pending',
      createdAt: DateTime(2026, 3, 6),
      ageHours: 8,
      slaHours: 48,
      slaBreached: false,
      title: 'Owner claim',
      subtitle: 'Pending',
      detail: const {
        'claimant_reputation': 72,
        'claimant_risk_score': 0,
        'evidence_url': '',
      },
      totalCount: 1,
    );

    final support = buildAdminQueueDecisionSupport(item);

    expect(support.pendingReasonCode, 'missing_evidence');
    expect(
      support.insights.any((insight) => insight.code == 'missing_evidence'),
      isTrue,
    );
  });

  test('claim support uses auto pending signal when evidence exists', () {
    final item = AdminQueueItem(
      id: 'claim-2',
      type: AdminQueueItemType.claim,
      status: 'pending',
      createdAt: DateTime(2026, 3, 6),
      ageHours: 6,
      slaHours: 48,
      slaBreached: false,
      title: 'Owner claim',
      subtitle: 'Pending',
      detail: const {
        'claimant_reputation': 20,
        'claimant_risk_score': 67,
        'claimant_auto_pending': true,
        'evidence_url': 'https://example.com/evidence.jpg',
      },
      totalCount: 1,
    );

    final support = buildAdminQueueDecisionSupport(item);

    expect(support.pendingReasonCode, 'claimant_auto_pending');
    expect(support.anomalyReasonCode, 'risky_actor');
  });

  test('business submission support respects missing field detail payload', () {
    final item = AdminQueueItem(
      id: 'submission-1',
      type: AdminQueueItemType.businessSubmission,
      status: 'new',
      createdAt: DateTime(2026, 3, 6),
      ageHours: 4,
      slaHours: 24,
      slaBreached: false,
      title: 'Cafe Nova',
      subtitle: 'Kadikoy',
      detail: const {
        'missing_fields': ['address', 'phone', 'website'],
        'review_reason': 'missing_submission_data',
      },
      totalCount: 1,
    );

    final support = buildAdminQueueDecisionSupport(item);

    expect(support.pendingReasonCode, 'missing_submission_data');
    expect(
      support.insights.any((insight) => insight.code == 'missing_fields'),
      isTrue,
    );
  });

  test('audit context summarizes recent decisions', () {
    final item = AdminQueueItem(
      id: 'price-1',
      type: AdminQueueItemType.priceSuggestion,
      status: 'pending',
      createdAt: DateTime(2026, 3, 6),
      ageHours: 8,
      slaHours: 48,
      slaBreached: false,
      title: 'Latte',
      subtitle: 'Pending',
      detail: const {},
      totalCount: 1,
    );
    final logs = [
      AdminAuditLogItem(
        createdAt: DateTime(2026, 3, 6, 10),
        actorId: 'admin-1',
        actorRole: 'admin',
        action: 'price_suggestion.approved',
        targetType: 'price_suggestion',
        targetId: 'price-2',
      ),
      AdminAuditLogItem(
        createdAt: DateTime(2026, 3, 6, 9),
        actorId: 'admin-1',
        actorRole: 'admin',
        action: 'price_suggestion.rejected',
        targetType: 'price_suggestion',
        targetId: 'price-3',
      ),
      AdminAuditLogItem(
        createdAt: DateTime(2026, 3, 6, 8),
        actorId: 'admin-1',
        actorRole: 'admin',
        action: 'price_suggestion.assigned',
        targetType: 'price_suggestion',
        targetId: 'price-1',
      ),
    ];

    final summary = summarizeAdminQueueAuditContext(item, logs);

    expect(summary.relevantCount, 3);
    expect(summary.exactTargetCount, 1);
    expect(summary.approvedCount, 1);
    expect(summary.rejectedCount, 1);
    expect(summary.assignedCount, 1);
  });
}
