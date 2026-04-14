part of '../admin_queue_page.dart';

class _QueueDetailPanel extends ConsumerWidget {
  const _QueueDetailPanel({
    required this.item,
    required this.userId,
    required this.onClose,
    required this.onOpenSource,
    required this.onToggleAssignment,
    this.onApprove,
    this.onReject,
  });

  final AdminQueueItem item;
  final String? userId;
  final VoidCallback onClose;
  final VoidCallback onOpenSource;
  final VoidCallback onToggleAssignment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final decisionSupport = buildAdminQueueDecisionSupport(item);
    final previewEntries = _previewEntries(context, item);
    final auditContext = ref.watch(_queueAuditContextProvider(item));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.adminQueueDetailTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    item.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailLine(
                    label: l10n.adminQueueColumnType,
                    value: _typeLabel(context, item.type),
                  ),
                  _DetailLine(
                    label: l10n.adminTableStatusLabel,
                    value: _statusLabel(context, item.status),
                  ),
                  _DetailLine(label: l10n.city, value: _cityValue(item)),
                  if ((item.businessName ?? '').trim().isNotEmpty)
                    _DetailLine(
                      label: l10n.ownerBusinessNameLabel,
                      value: item.businessName!.trim(),
                    ),
                  _DetailLine(
                    label: l10n.adminCommonAssigned,
                    value: _assignedLabel(context, item.assignedTo, userId),
                  ),
                  _DetailLine(
                    label: l10n.adminQueueColumnCreatedAt,
                    value: _fmtDateTime(item.createdAt),
                  ),
                  _DetailLine(label: l10n.sla, value: _slaLabel(context, item)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onOpenSource,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.adminQueueOpenSourceAction),
                      ),
                      OutlinedButton.icon(
                        onPressed: onToggleAssignment,
                        icon: Icon(
                          item.assignedTo == null
                              ? Icons.assignment_ind_outlined
                              : Icons.assignment_late_outlined,
                        ),
                        label: Text(
                          item.assignedTo == null
                              ? l10n.adminQueueAssignToMeAction
                              : l10n.adminQueueUnassignAction,
                        ),
                      ),
                      if (onApprove != null)
                        FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(l10n.approved),
                        ),
                      if (onReject != null)
                        OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(l10n.rejected),
                        ),
                    ],
                  ),
                  if (previewEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _QueuePreviewCard(entries: previewEntries),
                  ],
                  const SizedBox(height: 16),
                  _QueueDecisionSupportCard(
                    support: decisionSupport,
                  ),
                  const SizedBox(height: 16),
                  _QueueDecisionHistoryCard(
                    item: item,
                    auditContext: auditContext,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminQueueDetailPayloadTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(item.detail),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
