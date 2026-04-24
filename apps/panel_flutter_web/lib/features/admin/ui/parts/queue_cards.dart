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
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              if (summary.recentItems.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.adminQueueDecisionHistoryEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
          ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}

/// Mobile card view for a single queue item (used when viewport < 720px).
class _QueueMobileListCard extends StatelessWidget {
  const _QueueMobileListCard({
    required this.item,
    required this.isSelected,
    required this.userId,
    required this.onTap,
    required this.onSelectChanged,
    required this.onToggleAssignment,
    this.onApprove,
    this.onReject,
  });

  final AdminQueueItem item;
  final bool isSelected;
  final String? userId;
  final VoidCallback onTap;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onToggleAssignment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _StatusPill(label: _typeLabel(context, item.type)),
                      _StatusPill(label: _statusLabel(context, item.status)),
                      _SlaBadge(
                        label: _slaLabel(context, item),
                        breached: item.slaBreached,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    _cityValue(item),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmtDateTime(item.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: item.assignedTo == null
                      ? l10n.adminQueueAssignToMeAction
                      : l10n.adminQueueUnassignAction,
                  onPressed: onToggleAssignment,
                  icon: Icon(
                    item.assignedTo == null
                        ? Icons.assignment_ind_outlined
                        : Icons.assignment_late_outlined,
                    size: 20,
                  ),
                ),
                if (onApprove != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.approved,
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                  ),
                if (onReject != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.rejected,
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.adminQueueOpenDetailsAction,
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
          ],
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
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
