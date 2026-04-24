part of '../admin_queue_page.dart';

class _QueueSignalInsightChip extends StatelessWidget {
  const _QueueSignalInsightChip({
    required this.label,
    required this.severity,
  });

  final String label;
  final AdminQueueInsightSeverity severity;

  @override
  Widget build(BuildContext context) {
    final colors = _insightSeverityColors(severity);
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.$3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QueueAuditHistoryEntry extends StatelessWidget {
  const _QueueAuditHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.metadata,
  });

  final String title;
  final String subtitle;
  final String metadata;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            metadata,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SlaBadge extends StatelessWidget {
  const _SlaBadge({
    required this.label,
    required this.breached,
  });

  final String label;
  final bool breached;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: breached
            ? Colors.red.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: breached ? Colors.red.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

List<AdminTableStatusOption> _typeOptions(AppLocalizations l10n) {
  return [
    AdminTableStatusOption(value: '', label: l10n.tumu),
    AdminTableStatusOption(
      value: AdminQueueItemType.businessSubmission.wireValue,
      label: l10n.adminQueueTypeBusinessSubmission,
    ),
    AdminTableStatusOption(
      value: AdminQueueItemType.report.wireValue,
      label: l10n.adminQueueTypeReport,
    ),
    AdminTableStatusOption(
      value: AdminQueueItemType.priceSuggestion.wireValue,
      label: l10n.adminQueueTypePriceSuggestion,
    ),
    AdminTableStatusOption(
      value: AdminQueueItemType.claim.wireValue,
      label: l10n.adminQueueTypeClaim,
    ),
    AdminTableStatusOption(
      value: AdminQueueItemType.mediaFlag.wireValue,
      label: l10n.adminQueueTypeMediaFlag,
    ),
  ];
}

List<AdminTableStatusOption> _statusOptions(AppLocalizations l10n) {
  return [
    AdminTableStatusOption(value: '', label: l10n.tumu),
    AdminTableStatusOption(value: 'new', label: l10n.adminQueueStatusNew),
    AdminTableStatusOption(value: 'pending', label: l10n.pending),
    AdminTableStatusOption(value: 'open', label: l10n.adminQueueStatusOpen),
    AdminTableStatusOption(
      value: 'reviewing',
      label: l10n.adminQueueStatusReviewing,
    ),
    AdminTableStatusOption(
      value: 'closed',
      label: l10n.adminQueueStatusClosed,
    ),
    AdminTableStatusOption(value: 'approved', label: l10n.approved),
    AdminTableStatusOption(value: 'rejected', label: l10n.rejected),
  ];
}

String _typeLabel(BuildContext context, AdminQueueItemType type) {
  return switch (type) {
    AdminQueueItemType.businessSubmission => context
        .l10n
        .adminQueueTypeBusinessSubmission,
    AdminQueueItemType.report => context.l10n.adminQueueTypeReport,
    AdminQueueItemType.priceSuggestion => context
        .l10n
        .adminQueueTypePriceSuggestion,
    AdminQueueItemType.claim => context.l10n.adminQueueTypeClaim,
    AdminQueueItemType.mediaFlag => context.l10n.adminQueueTypeMediaFlag,
  };
}

String _statusLabel(BuildContext context, String status) {
  return switch (status) {
    'new' => context.l10n.adminQueueStatusNew,
    'pending' => context.l10n.pending,
    'approved' => context.l10n.approved,
    'rejected' => context.l10n.rejected,
    'open' => context.l10n.adminQueueStatusOpen,
    'reviewing' => context.l10n.adminQueueStatusReviewing,
    'closed' => context.l10n.adminQueueStatusClosed,
    _ => status,
  };
}

String _assignedLabel(BuildContext context, String? assignedTo, String? userId) {
  if (assignedTo == null || assignedTo.isEmpty) {
    return context.l10n.adminCommonUnassigned;
  }
  if (userId != null && assignedTo == userId) {
    return context.l10n.adminCommonMine;
  }
  return context.l10n.adminCommonOtherAdmin;
}

String _cityValue(AdminQueueItem item) {
  final city = (item.city ?? '').trim();
  final district = (item.district ?? '').trim();
  if (city.isEmpty && district.isEmpty) return '—';
  if (district.isEmpty) return city;
  if (city.isEmpty) return district;
  return '$city / $district';
}

String _slaLabel(BuildContext context, AdminQueueItem item) {
  return context.l10n.adminQueueSlaWaitingHours(
    item.ageHours.toStringAsFixed(1),
    item.slaHours,
  );
}

(Color, Color, Color) _insightSeverityColors(
  AdminQueueInsightSeverity severity,
) {
  return switch (severity) {
    AdminQueueInsightSeverity.critical => (
        Colors.red.shade50,
        Colors.red.shade200,
        Colors.red.shade800,
      ),
    AdminQueueInsightSeverity.warning => (
        Colors.orange.shade50,
        Colors.orange.shade200,
        Colors.orange.shade900,
      ),
    AdminQueueInsightSeverity.info => (
        Colors.blue.shade50,
        Colors.blue.shade200,
        Colors.blue.shade900,
      ),
    AdminQueueInsightSeverity.positive => (
        Colors.green.shade50,
        Colors.green.shade200,
        Colors.green.shade900,
      ),
  };
}

String _queueDecisionReasonLabel(BuildContext context, String code) {
  final l10n = context.l10n;
  return switch (code) {
    'conflict_and_anomaly' => l10n.adminQueuePendingReasonConflictAndAnomaly,
    'price_conflict' => l10n.adminQueuePendingReasonPriceConflict,
    'anomaly_queue' => l10n.adminQueuePendingReasonAnomalyQueue,
    'low_confidence' => l10n.adminQueuePendingReasonLowConfidence,
    'manual_review' => l10n.adminQueuePendingReasonManualReview,
    'grey_area' => l10n.adminQueuePendingReasonGreyArea,
    'missing_evidence' => l10n.adminQueuePendingReasonMissingEvidence,
    'claimant_auto_pending' => l10n.adminQueuePendingReasonClaimantAutoPending,
    'missing_submission_data' => l10n.adminQueuePendingReasonMissingSubmissionData,
    'high_anomaly_score' => l10n.adminQueueAnomalyReasonHighAnomalyScore,
    'conflicting_prices' => l10n.adminQueueAnomalyReasonConflictingPrices,
    'risky_actor' => l10n.adminQueueAnomalyReasonRiskyActor,
    'low_business_quality' => l10n.adminQueueAnomalyReasonLowBusinessQuality,
    'auto_moderated' => l10n.adminQueueAnomalyReasonAutoModerated,
    _ => _humanizeQueueCode(code),
  };
}

String _queueDecisionInsightLabel(
  BuildContext context,
  AdminQueueSignalInsight insight,
) {
  final l10n = context.l10n;
  return switch (insight.code) {
    'quality_confidence' => l10n.adminQueueSignalQualityConfidence(
        _formatPercent(insight.numericValue),
      ),
    'anomaly_score' => l10n.adminQueueSignalAnomalyScore(
        _formatPercent(insight.numericValue),
      ),
    'conflict_variants_24h' => l10n.adminQueueSignalConflictVariants(
        insight.intValue ?? 0,
      ),
    'anomaly_flags' => l10n.adminQueueSignalAnomalyFlags(
        _formatInsightTags(insight.tags),
      ),
    'actor_reputation' => l10n.adminQueueSignalActorReputation(
        insight.intValue ?? 0,
      ),
    'actor_risk' => l10n.adminQueueSignalActorRisk(insight.intValue ?? 0),
    'business_quality' => l10n.adminQueueSignalBusinessQuality(
        _formatDecimal(insight.numericValue),
      ),
    'auto_moderated' => l10n.adminQueueSignalAutoModerated,
    'short_details' => l10n.adminQueueSignalShortDetails(
        insight.intValue ?? 0,
      ),
    'missing_evidence' => l10n.adminQueueSignalMissingEvidence,
    'missing_fields' => l10n.adminQueueSignalMissingFields(
        insight.intValue ?? insight.tags.length,
        _formatInsightTags(insight.tags),
      ),
    _ => _humanizeQueueCode(insight.code),
  };
}

String _queueAuditActionLabel(BuildContext context, String action) {
  switch (action) {
    case 'business_submission.assigned':
      return context.l10n.adminQueueAuditActionBusinessSubmissionAssigned;
    case 'business_submission.unassigned':
      return context.l10n.adminQueueAuditActionBusinessSubmissionUnassigned;
    case 'price_suggestion.assigned':
      return context.l10n.adminQueueAuditActionPriceSuggestionAssigned;
    case 'price_suggestion.unassigned':
      return context.l10n.adminQueueAuditActionPriceSuggestionUnassigned;
    case 'report.auto_close_duplicate':
      return context.l10n.adminQueueAuditActionReportAutoCloseDuplicate;
    case 'report.auto_reject_low_quality':
      return context.l10n.adminQueueAuditActionReportAutoRejectLowQuality;
    case 'report.auto_queue_grey':
      return context.l10n.adminQueueAuditActionReportAutoQueueGrey;
    case 'price_suggestion.approved':
      return context.l10n.auditActionPriceSuggestionApproved;
    case 'price_suggestion.rejected':
      return context.l10n.auditActionPriceSuggestionRejected;
    case 'claim.approved':
      return context.l10n.auditActionClaimApproved;
    case 'claim.rejected':
      return context.l10n.auditActionClaimRejected;
    case 'claim.assigned':
      return context.l10n.auditActionClaimAssigned;
    case 'claim.updated':
      return context.l10n.auditActionClaimUpdated;
    case 'report.update':
    case 'report.status_changed':
      return context.l10n.auditActionReportUpdated;
    case 'report.assigned':
      return context.l10n.auditActionReportAssigned;
    case 'report.handled':
      return context.l10n.auditActionReportHandled;
    default:
      return _humanizeQueueCode(action.replaceAll('.', ' '));
  }
}

String _formatRelativeAuditTime(BuildContext context, DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return context.l10n.adminAuditRelativeNow;
  if (diff.inMinutes < 60) {
    return context.l10n.adminAuditRelativeMinutes(diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return context.l10n.adminAuditRelativeHours(diff.inHours);
  }
  if (diff.inDays < 7) {
    return context.l10n.adminAuditRelativeDays(diff.inDays);
  }
  if (diff.inDays < 30) {
    return context.l10n.adminAuditRelativeWeeks((diff.inDays / 7).floor());
  }
  return context.l10n.adminAuditRelativeMonths((diff.inDays / 30).floor());
}

String _formatPercent(double? value) {
  if (value == null) return '0%';
  return '${(value * 100).round()}%';
}

String _formatDecimal(double? value) {
  if (value == null) return '0';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

String _formatInsightTags(List<String> tags) {
  if (tags.isEmpty) return '—';
  return tags.map(_humanizeQueueCode).join(', ');
}

String _humanizeQueueCode(String code) {
  final normalized = code.trim().replaceAll(RegExp(r'[_\.\-]+'), ' ');
  if (normalized.isEmpty) return code;
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
      )
      .join(' ');
}

List<(String, String)> _previewEntries(BuildContext context, AdminQueueItem item) {
  final l10n = context.l10n;
  return switch (item.type) {
    AdminQueueItemType.businessSubmission => [
        if (_detailText(item.detail, 'submitted_by') != null)
          (l10n.adminQueuePreviewCreatedByLabel, _detailText(item.detail, 'submitted_by')!),
        if (_detailText(item.detail, 'category') != null)
          (l10n.adminQueuePreviewCategoryLabel, _detailText(item.detail, 'category')!),
        if (_detailText(item.detail, 'address') != null)
          (l10n.adminQueuePreviewAddressLabel, _detailText(item.detail, 'address')!),
        if (_detailText(item.detail, 'phone') != null)
          (l10n.adminQueuePreviewPhoneLabel, _detailText(item.detail, 'phone')!),
        if (_detailText(item.detail, 'website') != null)
          (l10n.adminQueuePreviewWebsiteLabel, _detailText(item.detail, 'website')!),
        if (_detailText(item.detail, 'admin_note') != null)
          (l10n.adminQueuePreviewAdminNoteLabel, _detailText(item.detail, 'admin_note')!),
      ],
    AdminQueueItemType.report || AdminQueueItemType.mediaFlag => [
        if (_detailText(item.detail, 'reason') != null)
          (l10n.adminQueuePreviewReasonLabel, _detailText(item.detail, 'reason')!),
        if (_detailText(item.detail, 'target_type') != null)
          (l10n.adminQueuePreviewTargetTypeLabel, _detailText(item.detail, 'target_type')!),
        if (_detailText(item.detail, 'target_id') != null)
          (l10n.adminQueuePreviewTargetIdLabel, _detailText(item.detail, 'target_id')!),
        if (_detailText(item.detail, 'details') != null)
          (l10n.adminQueuePreviewDetailsLabel, _detailText(item.detail, 'details')!),
        if (_detailText(item.detail, 'admin_note') != null)
          (l10n.adminQueuePreviewAdminNoteLabel, _detailText(item.detail, 'admin_note')!),
      ],
    AdminQueueItemType.claim => [
        if (_detailText(item.detail, 'full_name') != null)
          (l10n.adminQueuePreviewApplicantLabel, _detailText(item.detail, 'full_name')!),
        if (_detailText(item.detail, 'phone') != null)
          (l10n.adminQueuePreviewPhoneLabel, _detailText(item.detail, 'phone')!),
        if (_detailText(item.detail, 'note') != null)
          (l10n.adminQueuePreviewDetailsLabel, _detailText(item.detail, 'note')!),
        if (_detailText(item.detail, 'evidence_url') != null)
          (l10n.adminQueuePreviewEvidenceLabel, _detailText(item.detail, 'evidence_url')!),
        if (_detailText(item.detail, 'admin_note') != null)
          (l10n.adminQueuePreviewAdminNoteLabel, _detailText(item.detail, 'admin_note')!),
      ],
    AdminQueueItemType.priceSuggestion => [
        if (_detailText(item.detail, 'menu_item_name') != null)
          (l10n.adminQueuePreviewMenuItemLabel, _detailText(item.detail, 'menu_item_name')!),
        if (_priceLabel(item.detail, 'current_price_cents') != null)
          (l10n.adminQueuePreviewCurrentPriceLabel, _priceLabel(item.detail, 'current_price_cents')!),
        if (_priceLabel(item.detail, 'suggested_price_cents') != null)
          (l10n.adminQueuePreviewSuggestedPriceLabel, _priceLabel(item.detail, 'suggested_price_cents')!),
        if (_detailText(item.detail, 'anomaly_score') != null)
          (l10n.adminQueuePreviewAnomalyLabel, _detailText(item.detail, 'anomaly_score')!),
        if (_detailText(item.detail, 'conflict_state') != null)
          (l10n.adminQueuePreviewConflictLabel, _detailText(item.detail, 'conflict_state')!),
        if (_detailText(item.detail, 'created_by') != null)
          (l10n.adminQueuePreviewCreatedByLabel, _detailText(item.detail, 'created_by')!),
      ],
  };
}

String? _detailText(Map<String, dynamic> detail, String key) {
  final raw = detail[key];
  if (raw == null) return null;
  if (raw is List) {
    if (raw.isEmpty) return null;
    final text = raw.map((value) => value.toString().trim()).where((value) => value.isNotEmpty).join(', ');
    return text.isEmpty ? null : text;
  }
  final text = raw.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

String? _priceLabel(Map<String, dynamic> detail, String key) {
  final cents = detail[key];
  final currency = _detailText(detail, 'currency') ?? 'TRY';
  final value = switch (cents) {
    int _ => cents / 100,
    num _ => cents.toDouble() / 100,
    _ => double.tryParse((cents ?? '').toString()),
  };
  if (value == null) return null;
  return '${value.toStringAsFixed(2)} $currency';
}

String _safeFilterValue(String? value) {
  final text = (value ?? '').trim();
  return text;
}

String _buildQueueCsv(AppLocalizations l10n, List<AdminQueueItem> items) {
  final rows = <List<String>>[
    [
      l10n.adminQueueColumnType,
      l10n.adminQueueColumnTitle,
      l10n.adminTableStatusLabel,
      l10n.ownerBusinessNameLabel,
      l10n.city,
      l10n.adminCommonAssigned,
      l10n.adminQueueColumnCreatedAt,
      l10n.sla,
    ],
    for (final item in items)
      [
        _typeLabelFromL10n(l10n, item.type),
        item.title,
        _statusLabelFromL10n(l10n, item.status),
        item.businessName ?? '',
        _cityValue(item),
        item.assignedTo ?? '',
        _fmtDateTime(item.createdAt),
        _slaLabelFromL10n(l10n, item),
      ],
  ];
  return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String _typeLabelFromL10n(AppLocalizations l10n, AdminQueueItemType type) {
  return switch (type) {
    AdminQueueItemType.businessSubmission => l10n.adminQueueTypeBusinessSubmission,
    AdminQueueItemType.report => l10n.adminQueueTypeReport,
    AdminQueueItemType.priceSuggestion => l10n.adminQueueTypePriceSuggestion,
    AdminQueueItemType.claim => l10n.adminQueueTypeClaim,
    AdminQueueItemType.mediaFlag => l10n.adminQueueTypeMediaFlag,
  };
}

String _statusLabelFromL10n(AppLocalizations l10n, String status) {
  return switch (status) {
    'new' => l10n.adminQueueStatusNew,
    'pending' => l10n.pending,
    'approved' => l10n.approved,
    'rejected' => l10n.rejected,
    'open' => l10n.adminQueueStatusOpen,
    'reviewing' => l10n.adminQueueStatusReviewing,
    'closed' => l10n.adminQueueStatusClosed,
    _ => status,
  };
}

String _slaLabelFromL10n(AppLocalizations l10n, AdminQueueItem item) {
  return l10n.adminQueueSlaWaitingHours(
    item.ageHours.toStringAsFixed(1),
    item.slaHours,
  );
}

String _fmtDateTime(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String _stamp() {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute';
}
