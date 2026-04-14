import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../../shared/ui/components/panel_page_header.dart';
import '../../../../shared/ui/design_system.dart';
import '../../domain/admin_audit_models.dart';

class AuditTable extends StatelessWidget {
  const AuditTable({
    super.key,
    required this.ownerMode,
    required this.title,
    this.description,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.errorText,
    required this.scrollController,
    required this.searchController,
    required this.actionFilter,
    required this.targetTypeFilter,
    required this.myActionsOnly,
    required this.dateFrom,
    required this.dateTo,
    required this.onActionChanged,
    required this.onTargetTypeChanged,
    required this.onMyActionsChanged,
    required this.onApplyFilters,
    required this.onResetFilters,
    required this.onRefresh,
    required this.onPickDateRange,
    required this.onClearDateRange,
    this.quickFilterValue,
    this.onQuickFilterChanged,
    this.onExportCsv,
  });

  final bool ownerMode;
  final String title;
  final String? description;
  final List<AdminAuditLogItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorText;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final String actionFilter;
  final String targetTypeFilter;
  final bool myActionsOnly;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? quickFilterValue;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onTargetTypeChanged;
  final ValueChanged<bool> onMyActionsChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onResetFilters;
  final VoidCallback onRefresh;
  final Future<void> Function() onPickDateRange;
  final VoidCallback onClearDateRange;
  final ValueChanged<String>? onQuickFilterChanged;
  final VoidCallback? onExportCsv;

  static const List<String> _actionOptions = <String>[
    '',
    'business.verification_changed',
    'business.merge_proposed',
    'business.merge',
    'menu.create',
    'menu.update',
    'menu.archive',
    'menu.publish',
    'menu.created',
    'menu.updated',
    'menu.deleted',
    'menu_item.create',
    'menu_item.update',
    'menu_item.archive',
    'menu_item.publish',
    'menu_item.created',
    'menu_item.updated',
    'menu_item.deleted',
    'price_suggestion.approved',
    'price_suggestion.rejected',
    'owner.price_suggestion.override',
    'owner.price_suggestion.rejected',
    'owner.team.upsert',
    'owner.team.update',
    'owner.team.revoke',
    'claim.approved',
    'claim.rejected',
    'claim.assigned',
    'claim.updated',
    'report.update',
    'report.bulk_update',
    'report.export_csv',
    'report.status_changed',
    'report.assigned',
    'report.handled',
    'user.safety_action',
    'admin.impersonation.start',
    'admin.impersonation.stop',
  ];

  static const List<String> _targetTypeOptions = <String>[
    '',
    'business',
    'menu',
    'menu_item',
    'price_suggestion',
    'team_member',
    'owner_claim',
    'report',
    'user',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelPageHeader(
          padding: EdgeInsets.zero,
          title: Text(title),
          description: (description ?? '').isNotEmpty ? description : null,
          actions: [
            AppBadge(
              label: l10n.adminAuditRecordCount(items.length),
              tone: AppBadgeTone.info,
            ),
            if (onExportCsv != null)
              AppButton(
                label: l10n.adminAuditExportCsvAction,
                icon: Icons.download_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: onExportCsv,
              ),
            AppButton(
              label: l10n.yenile,
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
              onPressed: onRefresh,
            ),
          ],
        ),
        tokens.gap12(),
        if (ownerMode && onQuickFilterChanged != null) ...[
          AppCard(
            child: Wrap(
              spacing: tokens.space8,
              runSpacing: tokens.space8,
              children: [
                for (final quickFilter in _ownerQuickFilters)
                  ChoiceChip(
                    label: Text(_ownerQuickFilterLabel(context, quickFilter)),
                    selected: (quickFilterValue ?? 'all') == quickFilter,
                    onSelected: (_) => onQuickFilterChanged!(quickFilter),
                  ),
              ],
            ),
          ),
          tokens.gap12(),
        ],
        AppCard(
          child: Wrap(
            spacing: tokens.space12,
            runSpacing: tokens.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: searchController,
                  onSubmitted: (_) => onApplyFilters(),
                  decoration: InputDecoration(
                    labelText: l10n.search,
                    hintText: l10n.adminAuditSearchHint,
                    suffixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('audit-action-$actionFilter'),
                  initialValue: actionFilter.isEmpty ? null : actionFilter,
                  items: _actionOptions
                      .map(
                        (value) => DropdownMenuItem<String?>(
                          value: value.isEmpty ? null : value,
                          child: Text(_actionOptionLabel(context, value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onActionChanged,
                  decoration: InputDecoration(
                    labelText: l10n.adminAuditActionColumn,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('audit-target-$targetTypeFilter'),
                  initialValue: targetTypeFilter.isEmpty ? null : targetTypeFilter,
                  items: _targetTypeOptions
                      .map(
                        (value) => DropdownMenuItem<String?>(
                          value: value.isEmpty ? null : value,
                          child: Text(_targetTypeOptionLabel(context, value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onTargetTypeChanged,
                  decoration: InputDecoration(
                    labelText: l10n.adminAuditTargetTypeColumn,
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onPickDateRange,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.adminAuditDateRangeLabel,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dateFrom != null || dateTo != null)
                            IconButton(
                              tooltip: l10n.clear,
                              onPressed: onClearDateRange,
                              icon: const Icon(Icons.clear),
                            ),
                          const Icon(Icons.date_range_outlined),
                        ],
                      ),
                    ),
                    child: Text(_dateRangeLabel(context, dateFrom, dateTo)),
                  ),
                ),
              ),
              SizedBox(
                width: ownerMode ? 220 : 190,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: myActionsOnly,
                  onChanged: onMyActionsChanged,
                  title: Text(
                    ownerMode
                        ? l10n.ownerActivityOnlyMyActions
                        : l10n.adminAuditOnlyMyActions,
                  ),
                ),
              ),
              AppButton(
                label: l10n.apply,
                variant: AppButtonVariant.primary,
                onPressed: onApplyFilters,
              ),
              AppButton(
                label: l10n.clear,
                variant: AppButtonVariant.ghost,
                onPressed: onResetFilters,
              ),
            ],
          ),
        ),
        tokens.gap12(),
        Expanded(
          child: AppCard(
            padding: EdgeInsets.all(tokens.space12),
            child: _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const OwnerPanelFeedback.loading(cardCount: 6);
    }

    if (errorText != null && items.isEmpty) {
      return OwnerPanelFeedback.error(
        title: context.l10n.adminAuditErrorTitle,
        description: errorText!,
        onRetry: onRefresh,
      );
    }

    if (!isLoading && items.isEmpty) {
      return OwnerPanelFeedback.empty(
        icon: Icons.receipt_long_outlined,
        title: context.l10n.adminAuditEmptyTitle,
        description: context.l10n.adminAuditEmptyDescription,
        onRetry: onResetFilters,
        retryLabel: context.l10n.adminAuditClearFilters,
      );
    }

    return ListView(
      controller: scrollController,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              errorText!,
              style: context.bodyStyle.copyWith(color: Colors.red),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text(context.l10n.adminAuditCreatedAtColumn)),
              DataColumn(label: Text(context.l10n.adminAuditActionColumn)),
              DataColumn(label: Text(context.l10n.adminAuditTargetTypeColumn)),
              DataColumn(label: Text(context.l10n.adminAuditTargetIdColumn)),
              DataColumn(label: Text(context.l10n.adminAuditActorColumn)),
              DataColumn(label: Text(context.l10n.adminCommonActionsLabel)),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  onSelectChanged: (_) => _openDetails(context, item),
                  cells: [
                    DataCell(
                      Text(
                        '${_fmtRelative(context, item.createdAt)} • ${_fmtDateTime(item.createdAt)}',
                      ),
                    ),
                    DataCell(Text(_actionLabel(context, item.action))),
                    DataCell(Text(_targetTypeLabel(context, item.targetType))),
                    DataCell(_copyCell(context, item.targetId)),
                    DataCell(Text(_actorLabel(context, item))),
                    DataCell(
                      AppButton(
                        label: context.l10n.adminAuditDetailsAction,
                        variant: AppButtonVariant.ghost,
                        onPressed: () => _openDetails(context, item),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _copyCell(BuildContext context, String value) {
    return Row(
      children: [
        Flexible(child: Text(_short(value))),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 16),
          tooltip: context.l10n.adminAuditCopyTargetId,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.adminAuditCopied)));
          },
        ),
      ],
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminAuditLogItem item,
  ) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminAuditDetailsTitle, style: ctx.subtitleStyle),
              const SizedBox(height: 10),
              Text('${l10n.adminAuditCreatedAtColumn}: ${_fmtDateTime(item.createdAt)}'),
              Text('${l10n.adminAuditActionColumn}: ${_actionLabel(ctx, item.action)}'),
              Text(
                '${l10n.adminAuditTargetTypeColumn}: ${_targetTypeLabel(ctx, item.targetType)}',
              ),
              Text('${l10n.adminAuditTargetIdColumn}: ${item.targetId}'),
              Text('${l10n.adminAuditActorIdLabel}: ${item.actorId}'),
              Text('${l10n.adminAuditActorRoleLabel}: ${_actorRoleLabel(ctx, item.actorRole)}'),
              if ((item.ip ?? '').isNotEmpty)
                Text('${l10n.adminAuditIpLabel}: ${item.ip}'),
              if ((item.userAgent ?? '').isNotEmpty)
                Text('${l10n.adminAuditUserAgentLabel}: ${item.userAgent}'),
              const SizedBox(height: 12),
              Text(l10n.adminAuditBeforeAfterTitle, style: ctx.subtitleStyle),
              const SizedBox(height: 6),
              _buildDiffSection(ctx, item),
              const SizedBox(height: 12),
              Text(l10n.adminAuditMetaTitle, style: ctx.subtitleStyle),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _prettyJson(item.meta),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _ownerQuickFilters = <String>[
  'all',
  'today',
  'last7Days',
  'teamChanges',
];

Widget _buildDiffSection(BuildContext context, AdminAuditLogItem item) {
  final l10n = context.l10n;
  final rows = _buildDiffRows(item.beforeData, item.afterData);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (rows.isNotEmpty)
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.adminAuditDiffFieldLabel}: ${_diffFieldLabel(context, row.path)}',
                    style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.adminAuditDiffBeforeLabel}: ${_renderDiffValue(row.beforeValue)}',
                    style: context.bodyStyle.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.adminAuditDiffAfterLabel}: ${_renderDiffValue(row.afterValue)}',
                    style: context.bodyStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.adminAuditDiffNoChanges,
            style: context.bodyStyle.copyWith(color: Colors.black54),
          ),
        ),
      if (item.beforeData != null) ...[
        Text(
          l10n.adminAuditRawBeforeTitle,
          style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Text(
            _prettyJson(item.beforeData),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (item.afterData != null) ...[
        Text(
          l10n.adminAuditRawAfterTitle,
          style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Text(
            _prettyJson(item.afterData),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    ],
  );
}

String _actorLabel(BuildContext context, AdminAuditLogItem item) {
  final role = _actorRoleLabel(context, item.actorRole);
  final shortId = _short(item.actorId);
  if (role.isEmpty) return shortId;
  return '$role • $shortId';
}

String _actorRoleLabel(BuildContext context, String role) {
  switch (role.trim().toLowerCase()) {
    case 'admin':
      return context.l10n.adminAuditActorRoleAdmin;
    case 'owner':
      return context.l10n.adminAuditActorRoleOwner;
    case 'manager':
      return context.l10n.adminAuditActorRoleManager;
    case 'editor':
      return context.l10n.adminAuditActorRoleEditor;
    case 'staff':
      return context.l10n.adminAuditActorRoleStaff;
    case 'viewer':
      return context.l10n.adminAuditActorRoleViewer;
    case 'user':
      return context.l10n.adminAuditActorRoleUser;
    default:
      return role;
  }
}

String _actionOptionLabel(BuildContext context, String action) {
  if (action.isEmpty) return context.l10n.adminAuditActionFilterAll;
  return _actionLabel(context, action);
}

String _targetTypeOptionLabel(BuildContext context, String targetType) {
  if (targetType.isEmpty) return context.l10n.adminAuditTargetTypeFilterAll;
  return _targetTypeLabel(context, targetType);
}

String _actionLabel(BuildContext context, String action) {
  switch (action) {
    case 'business.verification_changed':
      return context.l10n.auditActionBusinessVerificationChanged;
    case 'business.merge_proposed':
      return context.l10n.auditActionBusinessMergeProposed;
    case 'business.merge':
      return context.l10n.auditActionBusinessMerge;
    case 'menu.create':
    case 'menu.created':
      return context.l10n.auditActionMenuCreated;
    case 'menu.update':
    case 'menu.updated':
      return context.l10n.auditActionMenuUpdated;
    case 'menu.archive':
      return context.l10n.auditActionMenuArchived;
    case 'menu.publish':
      return context.l10n.auditActionMenuPublished;
    case 'menu.deleted':
      return context.l10n.auditActionMenuDeleted;
    case 'menu_item.create':
    case 'menu_item.created':
      return context.l10n.auditActionMenuItemCreated;
    case 'menu_item.update':
    case 'menu_item.updated':
      return context.l10n.auditActionMenuItemUpdated;
    case 'menu_item.archive':
      return context.l10n.auditActionMenuItemArchived;
    case 'menu_item.publish':
      return context.l10n.auditActionMenuItemPublished;
    case 'menu_item.deleted':
      return context.l10n.auditActionMenuItemDeleted;
    case 'price_suggestion.approved':
      return context.l10n.auditActionPriceSuggestionApproved;
    case 'price_suggestion.rejected':
      return context.l10n.auditActionPriceSuggestionRejected;
    case 'owner.price_suggestion.override':
      return context.l10n.auditActionOwnerPriceSuggestionOverride;
    case 'owner.price_suggestion.rejected':
      return context.l10n.auditActionOwnerPriceSuggestionRejected;
    case 'owner.team.upsert':
      return context.l10n.auditActionTeamMemberSaved;
    case 'owner.team.update':
      return context.l10n.auditActionTeamMemberUpdated;
    case 'owner.team.revoke':
      return context.l10n.auditActionTeamMemberRemoved;
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
    case 'report.bulk_update':
      return context.l10n.auditActionReportBulkUpdated;
    case 'report.assigned':
      return context.l10n.auditActionReportAssigned;
    case 'report.handled':
      return context.l10n.auditActionReportHandled;
    case 'report.export_csv':
      return context.l10n.auditActionReportExported;
    case 'user.safety_action':
      return context.l10n.auditActionUserSafetyAction;
    case 'admin.impersonation.start':
      return context.l10n.auditActionImpersonationStarted;
    case 'admin.impersonation.stop':
      return context.l10n.auditActionImpersonationStopped;
    default:
      return action;
  }
}

String _ownerQuickFilterLabel(BuildContext context, String quickFilter) {
  switch (quickFilter) {
    case 'today':
      return context.l10n.ownerActivityPresetToday;
    case 'last7Days':
      return context.l10n.ownerActivityPresetLast7Days;
    case 'teamChanges':
      return context.l10n.ownerActivityPresetTeamChanges;
    default:
      return context.l10n.ownerActivityPresetAll;
  }
}

String _targetTypeLabel(BuildContext context, String targetType) {
  switch (targetType) {
    case 'business':
      return context.l10n.auditTargetTypeBusiness;
    case 'menu':
      return context.l10n.auditTargetTypeMenu;
    case 'menu_item':
      return context.l10n.auditTargetTypeMenuItem;
    case 'price_suggestion':
      return context.l10n.auditTargetTypePriceSuggestion;
    case 'team_member':
      return context.l10n.auditTargetTypeTeamMember;
    case 'owner_claim':
      return context.l10n.auditTargetTypeOwnerClaim;
    case 'report':
      return context.l10n.auditTargetTypeReport;
    case 'user':
      return context.l10n.auditTargetTypeUser;
    default:
      return targetType;
  }
}

String _diffFieldLabel(BuildContext context, String path) {
  if (path == r'$') return context.l10n.adminAuditDiffRootField;
  return path;
}

String _dateRangeLabel(BuildContext context, DateTime? from, DateTime? to) {
  if (from == null && to == null) {
    return context.l10n.adminAuditDateRangeEmpty;
  }
  final start = from == null ? '—' : _fmtDateOnly(from);
  final end = to == null ? '—' : _fmtDateOnly(to);
  return context.l10n.adminAuditDateRangeValue(start, end);
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

String _fmtDateTime(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}

String _fmtDateOnly(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _fmtRelative(BuildContext context, DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
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
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return context.l10n.adminAuditRelativeWeeks(weeks);
  final months = (diff.inDays / 30).floor();
  return context.l10n.adminAuditRelativeMonths(months);
}

String _prettyJson(Object? meta) {
  if (meta == null) return '{}';
  try {
    return const JsonEncoder.withIndent('  ').convert(meta);
  } catch (_) {
    return meta.toString();
  }
}

String _renderDiffValue(Object? value) {
  if (value == null) return '—';
  if (value is String || value is num || value is bool) return value.toString();
  return _prettyJson(value);
}

List<_AuditDiffRow> _buildDiffRows(Object? before, Object? after) {
  final beforeFlat = _flattenAuditValue(before);
  final afterFlat = _flattenAuditValue(after);
  final keys = {...beforeFlat.keys, ...afterFlat.keys}.toList()..sort();
  return keys
      .where((key) => !_valuesEqual(beforeFlat[key], afterFlat[key]))
      .map(
        (key) => _AuditDiffRow(
          path: key,
          beforeValue: beforeFlat[key],
          afterValue: afterFlat[key],
        ),
      )
      .toList(growable: false);
}

Map<String, Object?> _flattenAuditValue(
  Object? value, [
  String path = r'$',
]) {
  if (value is Map) {
    final entries = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final nextPath = path == r'$' ? key : '$path.$key';
      entries.addAll(_flattenAuditValue(entry.value, nextPath));
    }
    return entries;
  }
  if (value is List) {
    final entries = <String, Object?>{};
    for (var i = 0; i < value.length; i++) {
      final nextPath = '$path[$i]';
      entries.addAll(_flattenAuditValue(value[i], nextPath));
    }
    return entries;
  }
  return <String, Object?>{path: value};
}

bool _valuesEqual(Object? left, Object? right) {
  try {
    return jsonEncode(left) == jsonEncode(right);
  } catch (_) {
    return left == right;
  }
}

class _AuditDiffRow {
  const _AuditDiffRow({
    required this.path,
    required this.beforeValue,
    required this.afterValue,
  });

  final String path;
  final Object? beforeValue;
  final Object? afterValue;
}
