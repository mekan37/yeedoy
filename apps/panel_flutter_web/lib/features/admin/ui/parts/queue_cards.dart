part of '../admin_queue_page.dart';

class _QueuePreviewCard extends StatelessWidget {
  const _QueuePreviewCard({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    return _QueueInfoCard(
      title: context.l10n.adminQueuePreviewTitle,
      icon: Icons.summarize_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            _DetailLine(label: entry.$1, value: entry.$2),
        ],
      ),
    );
  }
}

class _QueueDecisionSupportCard extends StatelessWidget {
  const _QueueDecisionSupportCard({
    required this.support,
  });

  final AdminQueueDecisionSupport support;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasSignals = support.insights.isNotEmpty;
    final hasReasons =
        (support.pendingReasonCode ?? '').isNotEmpty ||
        (support.anomalyReasonCode ?? '').isNotEmpty;
    return _QueueInfoCard(
      title: l10n.adminQueueDecisionSupportTitle,
      icon: Icons.tune_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasSignals && !hasReasons)
            Text(
              l10n.adminQueueDecisionSupportEmpty,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          if ((support.pendingReasonCode ?? '').isNotEmpty)
            _DetailLine(
              label: l10n.adminQueuePendingReasonLabel,
              value: _queueDecisionReasonLabel(
                context,
                support.pendingReasonCode!,
              ),
            ),
          if ((support.anomalyReasonCode ?? '').isNotEmpty)
            _DetailLine(
              label: l10n.adminQueueAnomalyReasonLabel,
              value: _queueDecisionReasonLabel(
                context,
                support.anomalyReasonCode!,
              ),
            ),
          if (hasSignals) ...[
            const SizedBox(height: 6),
            Text(
              l10n.adminQueueDecisionSignalsLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final insight in support.insights)
                  _QueueSignalInsightChip(
                    label: _queueDecisionInsightLabel(context, insight),
                    severity: insight.severity,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueDecisionHistoryCard extends StatelessWidget {
  const _QueueDecisionHistoryCard({
    required this.item,
    required this.auditContext,
  });

  final AdminQueueItem item;
  final AsyncValue<AdminQueueAuditContextSummary> auditContext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _QueueInfoCard(
      title: l10n.adminQueueDecisionHistoryTitle,
      icon: Icons.history_outlined,
      child: auditContext.when(
        data: (summary) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminQueueDecisionHistorySummary(
                  summary.relevantCount,
                  summary.exactTargetCount,
                  summary.approvedCount,
                  summary.rejectedCount,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.adminQueueDecisionHistoryAssignments(
                  summary.assignedCount,
                  summary.handledCount,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              if (summary.recentItems.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.adminQueueDecisionHistoryEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ] else ...[
                const SizedBox(height: 12),
                for (final auditItem in summary.recentItems) ...[
                  _QueueAuditHistoryEntry(
                    title: _queueAuditActionLabel(context, auditItem.action),
                    subtitle:
                        '${auditItem.targetId == item.id ? l10n.adminQueueDecisionHistoryExactTarget : l10n.adminQueueDecisionHistorySimilarRecord} • ${_formatRelativeAuditTime(context, auditItem.createdAt)}',
                    metadata:
                        '${_fmtDateTime(auditItem.createdAt)} • ${auditItem.targetId}',
                  ),
                  if (auditItem != summary.recentItems.last)
                    const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
        loading: () => Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(l10n.adminQueueDecisionHistoryLoading),
          ],
        ),
        error: (error, _) => Text(
          '${l10n.adminQueueDecisionHistoryError}: ${AppErrorMapper.message(error)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
        ),
      ),
    );
  }
}

class _QueueInfoCard extends StatelessWidget {
  const _QueueInfoCard({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
