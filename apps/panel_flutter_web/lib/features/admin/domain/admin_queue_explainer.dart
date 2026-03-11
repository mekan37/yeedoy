import 'admin_audit_models.dart';
import 'admin_queue_models.dart';

enum AdminQueueInsightSeverity {
  critical,
  warning,
  info,
  positive,
}

class AdminQueueSignalInsight {
  const AdminQueueSignalInsight({
    required this.code,
    required this.severity,
    this.numericValue,
    this.intValue,
    this.boolValue,
    this.tags = const <String>[],
  });

  final String code;
  final AdminQueueInsightSeverity severity;
  final double? numericValue;
  final int? intValue;
  final bool? boolValue;
  final List<String> tags;
}

class AdminQueueDecisionSupport {
  const AdminQueueDecisionSupport({
    required this.pendingReasonCode,
    required this.anomalyReasonCode,
    required this.insights,
  });

  final String? pendingReasonCode;
  final String? anomalyReasonCode;
  final List<AdminQueueSignalInsight> insights;
}

class AdminQueueAuditContextSummary {
  const AdminQueueAuditContextSummary({
    required this.relevantCount,
    required this.exactTargetCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.assignedCount,
    required this.handledCount,
    required this.recentItems,
  });

  final int relevantCount;
  final int exactTargetCount;
  final int approvedCount;
  final int rejectedCount;
  final int assignedCount;
  final int handledCount;
  final List<AdminAuditLogItem> recentItems;
}

AdminQueueDecisionSupport buildAdminQueueDecisionSupport(AdminQueueItem item) {
  return switch (item.type) {
    AdminQueueItemType.priceSuggestion => _buildPriceSuggestionSupport(item),
    AdminQueueItemType.report || AdminQueueItemType.mediaFlag => _buildReportSupport(item),
    AdminQueueItemType.claim => _buildClaimSupport(item),
    AdminQueueItemType.businessSubmission => _buildBusinessSubmissionSupport(item),
  };
}

String? resolveAdminQueueAuditTargetType(AdminQueueItem item) {
  return switch (item.type) {
    AdminQueueItemType.priceSuggestion => 'price_suggestion',
    AdminQueueItemType.claim => 'owner_claim',
    AdminQueueItemType.report || AdminQueueItemType.mediaFlag => 'report',
    AdminQueueItemType.businessSubmission => null,
  };
}

AdminQueueAuditContextSummary summarizeAdminQueueAuditContext(
  AdminQueueItem item,
  List<AdminAuditLogItem> auditItems,
) {
  final exactTargetId = item.id.trim();
  var approvedCount = 0;
  var rejectedCount = 0;
  var assignedCount = 0;
  var handledCount = 0;
  var exactTargetCount = 0;

  for (final auditItem in auditItems) {
    if (auditItem.targetId == exactTargetId) {
      exactTargetCount++;
    }

    final action = auditItem.action.trim().toLowerCase();
    if (action.contains('approved')) approvedCount++;
    if (action.contains('rejected')) rejectedCount++;
    if (action.contains('assigned')) assignedCount++;
    if (action.contains('handled') || action.contains('status_changed')) {
      handledCount++;
    }
  }

  return AdminQueueAuditContextSummary(
    relevantCount: auditItems.length,
    exactTargetCount: exactTargetCount,
    approvedCount: approvedCount,
    rejectedCount: rejectedCount,
    assignedCount: assignedCount,
    handledCount: handledCount,
    recentItems: auditItems.take(4).toList(growable: false),
  );
}

AdminQueueDecisionSupport _buildPriceSuggestionSupport(AdminQueueItem item) {
  final detail = item.detail;
  final anomalyScore = _detailDouble(detail, 'anomaly_score');
  final qualityConfidence = _detailDouble(detail, 'quality_confidence');
  final conflictCount = _detailInt(detail, 'conflict_variants_24h');
  final contributorReputation = _detailInt(detail, 'created_by_reputation');
  final contributorRisk = _detailInt(detail, 'created_by_risk_score');
  final businessQuality = _detailDouble(detail, 'business_quality_score');
  final conflictState = _detailText(detail, 'conflict_state');
  final reviewReason = _detailText(detail, 'review_reason');
  final anomalyFlags = _detailStringList(detail, 'anomaly_flags');
  final insights = <AdminQueueSignalInsight>[];

  if (qualityConfidence != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'quality_confidence',
        severity: qualityConfidence < 0.65
            ? AdminQueueInsightSeverity.warning
            : AdminQueueInsightSeverity.positive,
        numericValue: qualityConfidence,
      ),
    );
  }
  if (anomalyScore != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'anomaly_score',
        severity: anomalyScore >= 0.80
            ? AdminQueueInsightSeverity.critical
            : anomalyScore >= 0.50
                ? AdminQueueInsightSeverity.warning
                : AdminQueueInsightSeverity.info,
        numericValue: anomalyScore,
      ),
    );
  }
  if (conflictCount != null && conflictCount > 0) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'conflict_variants_24h',
        severity: conflictCount >= 3
            ? AdminQueueInsightSeverity.warning
            : AdminQueueInsightSeverity.info,
        intValue: conflictCount,
      ),
    );
  }
  if (anomalyFlags.isNotEmpty) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'anomaly_flags',
        severity: AdminQueueInsightSeverity.warning,
        tags: anomalyFlags,
      ),
    );
  }
  if (contributorReputation != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_reputation',
        severity: contributorReputation >= 80
            ? AdminQueueInsightSeverity.positive
            : contributorReputation < 40
                ? AdminQueueInsightSeverity.warning
                : AdminQueueInsightSeverity.info,
        intValue: contributorReputation,
      ),
    );
  }
  if (contributorRisk != null && contributorRisk > 0) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_risk',
        severity: contributorRisk >= 50
            ? AdminQueueInsightSeverity.critical
            : AdminQueueInsightSeverity.warning,
        intValue: contributorRisk,
      ),
    );
  }
  if (businessQuality != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'business_quality',
        severity: businessQuality < 50
            ? AdminQueueInsightSeverity.warning
            : AdminQueueInsightSeverity.info,
        numericValue: businessQuality,
      ),
    );
  }

  String? pendingReasonCode;
  if (item.status == 'pending') {
    pendingReasonCode = reviewReason;
    if (pendingReasonCode == null || pendingReasonCode.isEmpty) {
      if (conflictState == 'queued' && (anomalyScore ?? 0) >= 0.50) {
        pendingReasonCode = 'conflict_and_anomaly';
      } else if (conflictState == 'queued') {
        pendingReasonCode = 'price_conflict';
      } else if ((anomalyScore ?? 0) >= 0.50) {
        pendingReasonCode = 'anomaly_queue';
      } else if ((qualityConfidence ?? 1) < 0.65) {
        pendingReasonCode = 'low_confidence';
      } else {
        pendingReasonCode = 'manual_review';
      }
    }
  }

  String? anomalyReasonCode;
  if ((anomalyScore ?? 0) >= 0.80) {
    anomalyReasonCode = 'high_anomaly_score';
  } else if (anomalyFlags.contains('price_conflict') || conflictState == 'queued') {
    anomalyReasonCode = 'conflicting_prices';
  } else if ((contributorRisk ?? 0) >= 50) {
    anomalyReasonCode = 'risky_actor';
  } else if ((businessQuality ?? 100) < 50) {
    anomalyReasonCode = 'low_business_quality';
  }

  return AdminQueueDecisionSupport(
    pendingReasonCode: pendingReasonCode,
    anomalyReasonCode: anomalyReasonCode,
    insights: insights,
  );
}

AdminQueueDecisionSupport _buildReportSupport(AdminQueueItem item) {
  final detail = item.detail;
  final reporterReputation = _detailInt(detail, 'reporter_reputation');
  final reporterRisk = _detailInt(detail, 'reporter_risk_score');
  final autoModerated = _detailBool(detail, 'auto_moderated');
  final detailLength = _detailText(detail, 'details')?.length ?? 0;
  final reviewReason = _detailText(detail, 'review_reason');
  final insights = <AdminQueueSignalInsight>[];

  if (reporterReputation != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_reputation',
        severity: reporterReputation >= 80
            ? AdminQueueInsightSeverity.positive
            : reporterReputation < 40
                ? AdminQueueInsightSeverity.warning
                : AdminQueueInsightSeverity.info,
        intValue: reporterReputation,
      ),
    );
  }
  if (reporterRisk != null && reporterRisk > 0) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_risk',
        severity: reporterRisk >= 50
            ? AdminQueueInsightSeverity.critical
            : AdminQueueInsightSeverity.warning,
        intValue: reporterRisk,
      ),
    );
  }
  if (autoModerated == true) {
    insights.add(
      const AdminQueueSignalInsight(
        code: 'auto_moderated',
        severity: AdminQueueInsightSeverity.info,
        boolValue: true,
      ),
    );
  }
  if (detailLength > 0 && detailLength < 20) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'short_details',
        severity: AdminQueueInsightSeverity.warning,
        intValue: detailLength,
      ),
    );
  }

  String? pendingReasonCode;
  if (item.status == 'open' || item.status == 'reviewing') {
    pendingReasonCode = reviewReason;
    if (pendingReasonCode == null || pendingReasonCode.isEmpty) {
      if (autoModerated == true) {
        pendingReasonCode = 'grey_area';
      } else if ((reporterRisk ?? 0) >= 50) {
        pendingReasonCode = 'risky_actor';
      } else {
        pendingReasonCode = 'manual_review';
      }
    }
  }

  String? anomalyReasonCode;
  if ((reporterRisk ?? 0) >= 50) {
    anomalyReasonCode = 'risky_actor';
  } else if (autoModerated == true) {
    anomalyReasonCode = 'auto_moderated';
  }

  return AdminQueueDecisionSupport(
    pendingReasonCode: pendingReasonCode,
    anomalyReasonCode: anomalyReasonCode,
    insights: insights,
  );
}

AdminQueueDecisionSupport _buildClaimSupport(AdminQueueItem item) {
  final detail = item.detail;
  final claimantReputation = _detailInt(detail, 'claimant_reputation');
  final claimantRisk = _detailInt(detail, 'claimant_risk_score');
  final claimantAutoPending = _detailBool(detail, 'claimant_auto_pending');
  final hasEvidence = (_detailText(detail, 'evidence_url') ?? '').isNotEmpty;
  final reviewReason = _detailText(detail, 'review_reason');
  final insights = <AdminQueueSignalInsight>[];

  if (claimantReputation != null) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_reputation',
        severity: claimantReputation >= 80
            ? AdminQueueInsightSeverity.positive
            : claimantReputation < 40
                ? AdminQueueInsightSeverity.warning
                : AdminQueueInsightSeverity.info,
        intValue: claimantReputation,
      ),
    );
  }
  if (claimantRisk != null && claimantRisk > 0) {
    insights.add(
      AdminQueueSignalInsight(
        code: 'actor_risk',
        severity: claimantRisk >= 50
            ? AdminQueueInsightSeverity.critical
            : AdminQueueInsightSeverity.warning,
        intValue: claimantRisk,
      ),
    );
  }
  if (!hasEvidence) {
    insights.add(
      const AdminQueueSignalInsight(
        code: 'missing_evidence',
        severity: AdminQueueInsightSeverity.warning,
        boolValue: true,
      ),
    );
  }

  String? pendingReasonCode;
  if (item.status == 'pending') {
    pendingReasonCode = reviewReason;
    if (pendingReasonCode == null || pendingReasonCode.isEmpty) {
      if (!hasEvidence) {
        pendingReasonCode = 'missing_evidence';
      } else if (claimantAutoPending == true || (claimantRisk ?? 0) >= 50) {
        pendingReasonCode = 'claimant_auto_pending';
      } else {
        pendingReasonCode = 'manual_review';
      }
    }
  }

  String? anomalyReasonCode;
  if ((claimantRisk ?? 0) >= 50) {
    anomalyReasonCode = 'risky_actor';
  }

  return AdminQueueDecisionSupport(
    pendingReasonCode: pendingReasonCode,
    anomalyReasonCode: anomalyReasonCode,
    insights: insights,
  );
}

AdminQueueDecisionSupport _buildBusinessSubmissionSupport(AdminQueueItem item) {
  final detail = item.detail;
  final detailMissingFields = _detailStringList(detail, 'missing_fields');
  final missingFields = detailMissingFields.isNotEmpty
      ? detailMissingFields
      : <String>[
          if ((_detailText(detail, 'address') ?? '').isEmpty) 'address',
          if ((_detailText(detail, 'phone') ?? '').isEmpty) 'phone',
          if ((_detailText(detail, 'website') ?? '').isEmpty) 'website',
          if ((_detailText(detail, 'category') ?? '').isEmpty) 'category',
        ];
  final reviewReason = _detailText(detail, 'review_reason');
  final insights = <AdminQueueSignalInsight>[
    if (missingFields.isNotEmpty)
      AdminQueueSignalInsight(
        code: 'missing_fields',
        severity: missingFields.length >= 2
            ? AdminQueueInsightSeverity.warning
            : AdminQueueInsightSeverity.info,
        intValue: missingFields.length,
        tags: missingFields,
      ),
  ];

  String? pendingReasonCode;
  if (item.status == 'new') {
    pendingReasonCode = reviewReason;
    if (pendingReasonCode == null || pendingReasonCode.isEmpty) {
      pendingReasonCode = missingFields.length >= 2
          ? 'missing_submission_data'
          : 'manual_review';
    }
  }

  return AdminQueueDecisionSupport(
    pendingReasonCode: pendingReasonCode,
    anomalyReasonCode: null,
    insights: insights,
  );
}

String? _detailText(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

double? _detailDouble(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw == null) return null;
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

int? _detailInt(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

bool? _detailBool(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final text = raw.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

List<String> _detailStringList(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw is! List) return const <String>[];
  return raw
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty && entry != 'null')
      .toList(growable: false);
}
