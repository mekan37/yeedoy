import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_claims_repository.dart';
import '../domain/admin_claims_controller.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import 'keyboard/admin_keyboard_shortcuts.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import 'widgets/admin_table.dart';
import '../../../shared/ui/design_system.dart';
import '../../../shared/ui/components/panel_page_header.dart';

class AdminClaimsPage extends ConsumerStatefulWidget {
  const AdminClaimsPage({super.key});

  @override
  ConsumerState<AdminClaimsPage> createState() => _AdminClaimsPageState();
}

class _AdminClaimsPageState extends ConsumerState<AdminClaimsPage> {
  static const _columns = <AdminVirtualTableColumn>[
    AdminVirtualTableColumn(width: 56, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 120, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 220, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 120, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 170, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 120, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 120, label: SizedBox.shrink()),
  ];

  final searchCtrl = TextEditingController();
  final searchFocus = FocusNode();
  final bulkNoteCtrl = TextEditingController();
  String bulkDecision = '';
  bool exporting = false;
  int _page = 0;
  int _rowsPerPage = 20;

  @override
  void dispose() {
    searchCtrl.dispose();
    searchFocus.dispose();
    bulkNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminClaimsControllerProvider);
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;
    final estimatedTotalCount = st.items.length + (st.hasMore ? _rowsPerPage : 0);
    final safePage = estimatedTotalCount == 0
        ? 0
        : _page.clamp(0, ((estimatedTotalCount - 1) ~/ _rowsPerPage)).toInt();
    final start = safePage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, st.items.length);
    final pageItems = st.items.sublist(start, end);
    final allSelected =
        pageItems.isNotEmpty &&
        pageItems.every((c) => st.selectedIds.contains(c.id));
    final newItems = ref.watch(adminNewItemsProvider).claimsNew;

    return AdminKeyboardShortcuts(
      enabled: st.selectedIds.isEmpty,
      onNext: () => controller.next(),
      onPrev: () => controller.prev(),
      onToggleModal: () => _toggleDetail(st),
      onCloseModal: _closeDetail,
      onFocusSearch: () => searchFocus.requestFocus(),
      onAssignToggle: () => _toggleAssign(st, user?.id),
      onAction: (key) => _handleAction(st, key),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelPageHeader(
              padding: EdgeInsets.zero,
              title: Text(l10n.adminShellClaimsLabel),
              description: l10n.adminShellClaimsDescription,
              actions: [
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => _exportCsv(st),
                  icon: const Icon(Icons.download),
                  label: Text(
                    exporting
                        ? l10n.adminClaimsExportingAction
                        : l10n.adminClaimsExportCsvAction,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    _queueRouteForClaims(
                      query: st.query,
                      status: st.statusFilter,
                    ),
                  ),
                  icon: const Icon(Icons.alt_route),
                  label: Text(l10n.adminQueueOpenFromClaimsAction),
                ),
                IconButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(adminClaimsControllerProvider.notifier)
                        .refresh(force: true);
                    if (!context.mounted) return;
                    if (ok) {
                      ref.read(adminNewItemsProvider.notifier).clearClaims();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    focusNode: searchFocus,
                    onChanged: (v) {
                      setState(() => _page = 0);
                      ref
                          .read(adminClaimsControllerProvider.notifier)
                          .setQuery(v.trim());
                    },
                    decoration: InputDecoration(
                      hintText: l10n.adminClaimsSearchHint,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    AppFilterChip(
                      label: l10n.sla,
                      selected: st.slaOnly,
                      onTap: () {
                        setState(() => _page = 0);
                        ref
                            .read(adminClaimsControllerProvider.notifier)
                            .setSlaOnly(!st.slaOnly);
                      },
                    ),
                    AppFilterChip(
                      label: l10n.tumu,
                      selected: st.statusFilter.isEmpty,
                      onTap: () {
                        setState(() => _page = 0);
                        ref
                            .read(adminClaimsControllerProvider.notifier)
                            .setStatusFilter('');
                      },
                    ),
                    AppFilterChip(
                      label: l10n.pending,
                      selected: st.statusFilter == 'pending',
                      onTap: () {
                        setState(() => _page = 0);
                        ref
                            .read(adminClaimsControllerProvider.notifier)
                            .setStatusFilter('pending');
                      },
                    ),
                    AppFilterChip(
                      label: l10n.approved,
                      selected: st.statusFilter == 'approved',
                      onTap: () {
                        setState(() => _page = 0);
                        ref
                            .read(adminClaimsControllerProvider.notifier)
                            .setStatusFilter('approved');
                      },
                    ),
                    AppFilterChip(
                      label: l10n.rejected,
                      selected: st.statusFilter == 'rejected',
                      onTap: () {
                        setState(() => _page = 0);
                        ref
                            .read(adminClaimsControllerProvider.notifier)
                            .setStatusFilter('rejected');
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppFilterChip(
                  label: l10n.tumu,
                  selected: st.assignedFilter.isEmpty,
                  onTap: () {
                    setState(() => _page = 0);
                    ref
                        .read(adminClaimsControllerProvider.notifier)
                        .setAssignedFilter('');
                  },
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n.adminClaimsAssignedUnassigned,
                  selected: st.assignedFilter == 'unassigned',
                  onTap: () {
                    setState(() => _page = 0);
                    ref
                        .read(adminClaimsControllerProvider.notifier)
                        .setAssignedFilter('unassigned');
                  },
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n.adminClaimsAssignedMine,
                  selected: st.assignedFilter == 'me',
                  onTap: () {
                    setState(() => _page = 0);
                    ref
                        .read(adminClaimsControllerProvider.notifier)
                        .setAssignedFilter('me');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            AdminNewItemsBanner(
              count: newItems,
              label: l10n.adminClaimsNewRecordsAvailable,
              onRefresh: () async {
                final ok = await ref
                    .read(adminClaimsControllerProvider.notifier)
                    .refresh(force: true);
                if (!context.mounted) return;
                if (ok) {
                  ref.read(adminNewItemsProvider.notifier).clearClaims();
                }
              },
            ),
            if (newItems > 0) const SizedBox(height: 10),

            _BulkBar(
              selectedCount: st.selectedIds.length,
              bulkDecision: bulkDecision,
              onDecisionChanged: (v) => setState(() => bulkDecision = v),
              noteCtrl: bulkNoteCtrl,
              onClear: () => ref
                  .read(adminClaimsControllerProvider.notifier)
                  .clearSelection(),
              onApply: st.selectedIds.isEmpty || bulkDecision.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(adminClaimsControllerProvider.notifier)
                            .bulkDecide(
                              decision: bulkDecision,
                              note: bulkNoteCtrl.text.trim(),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.adminClaimsBulkUpdated)),
                          );
                        }
                        setState(() => bulkDecision = '');
                        bulkNoteCtrl.clear();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorMapper.message(e))),
                          );
                        }
                      }
                    },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: st.selectedIndex == null
                      ? null
                      : () => _selectSamePhone(st),
                  icon: const Icon(Icons.group_work_outlined),
                  label: Text(l10n.adminClaimsSelectSamePhoneAction),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: st.selectedIds.isEmpty || user?.id == null
                      ? null
                      : () => _assignSelectedToMe(st, user!.id),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: Text(l10n.adminClaimsAssignSelectedToMeAction),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppErrorMapper.message(st.error),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            Expanded(
              child: st.isLoading && st.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: AdminVirtualTableCard(
                            emptyLabel: l10n.adminClaimsEmpty,
                            columns: [
                              AdminVirtualTableColumn(
                                width: 56,
                                label: Checkbox(
                                  value: allSelected,
                                  onChanged: (value) {
                                    for (final item in pageItems) {
                                      controller.toggleSelection(
                                        item.id,
                                        value ?? false,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const AdminVirtualTableColumn(
                                width: 120,
                                label: Text('ID'),
                              ),
                              AdminVirtualTableColumn(
                                width: 220,
                                label: Text(l10n.adminClaimsFullNameColumn),
                              ),
                              AdminVirtualTableColumn(
                                width: 120,
                                label: Text(l10n.adminClaimsPriorityColumn),
                              ),
                              AdminVirtualTableColumn(
                                width: 170,
                                label: Text(l10n.adminClaimsStatusColumn),
                              ),
                              AdminVirtualTableColumn(
                                width: 140,
                                label: Text(l10n.adminClaimsAssignedColumn),
                              ),
                              AdminVirtualTableColumn(
                                width: 140,
                                label: Text(l10n.adminClaimsCreatedAtColumn),
                              ),
                              AdminVirtualTableColumn(
                                width: 120,
                                label: Text(l10n.adminClaimsAgeColumn),
                              ),
                              const AdminVirtualTableColumn(
                                width: 120,
                                label: Text(''),
                              ),
                            ],
                            rowCount: pageItems.length,
                            rowBuilder: (context, index) {
                              final item = pageItems[index];
                              final sourceIndex = st.items.indexWhere(
                                (entry) => entry.id == item.id,
                              );
                              return AdminVirtualTableRowView(
                                columns: _columns,
                                row: AdminVirtualTableRow(
                                  key: ValueKey(item.id),
                                  backgroundColor: _rowColor(
                                    st.selectedIndex == sourceIndex,
                                    item.slaBreached,
                                  ).resolve({}),
                                  selected: st.selectedIds.contains(item.id),
                                  onTap: () => _openDetails(
                                    context,
                                    item,
                                    index: sourceIndex >= 0 ? sourceIndex : null,
                                  ),
                                  cells: [
                                    Checkbox(
                                      value: st.selectedIds.contains(item.id),
                                      onChanged: (value) => controller
                                          .toggleSelection(item.id, value ?? false),
                                    ),
                                    Row(
                                      children: [
                                        if (item.slaBreached) ...[
                                          const AppSlaBadge(),
                                          const SizedBox(width: 6),
                                        ],
                                        Flexible(
                                          child: Text(
                                            _short(item.id),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      item.fullName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    AppPriorityBadge(score: _claimPriority(item)),
                                    Row(
                                      children: [
                                        Text(_claimStatusLabel(l10n, item.status)),
                                        if (item.autoModerated) ...[
                                          const SizedBox(width: 6),
                                          Tooltip(
                                            message: l10n.adminClaimsAutoModeratedTooltip,
                                            child: const AppAutoBadge(),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      _assignedLabel(
                                        l10n,
                                        item.assignedTo,
                                        user?.id,
                                      ),
                                    ),
                                    Text(_fmtDate(item.createdAt)),
                                    Text(_fmtDays(l10n, item.ageDays)),
                                    TextButton(
                                      onPressed: () => _openDetails(
                                        context,
                                        item,
                                        index: sourceIndex >= 0 ? sourceIndex : null,
                                      ),
                                      child: Text(l10n.adminClaimsDetailsAction),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (st.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        const SizedBox(height: 12),
                        AdminTablePaginationBar(
                          page: safePage,
                          rowsPerPage: _rowsPerPage,
                          totalCount: estimatedTotalCount,
                          onPageChanged: (value) => _changeClaimsPage(
                            value,
                            state: st,
                          ),
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _rowsPerPage = value;
                              _page = 0;
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeClaimsPage(
    int value, {
    required AdminClaimsState state,
  }) {
    setState(() => _page = value);
    final requiredItems = (value + 1) * _rowsPerPage;
    if (requiredItems > state.items.length && state.hasMore && !state.isLoadingMore) {
      ref.read(adminClaimsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _exportCsv(AdminClaimsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminClaimsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        query: st.query,
      );
      final filename = 'claims_${_stamp()}.csv';
      if (!mounted) return;
      downloadCsv(filename, csv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) {
        setState(() => exporting = false);
      }
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminOwnerClaimItem item, {
    int? index,
  }) async {
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    final l10n = context.l10n;
    if (index != null) {
      controller.selectIndex(index);
    }
    controller.openDetail();
    final userId = ref.read(userProvider)?.id;
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
    var loading = false;
    var applyingRules = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.slaBreached)
                  AppSlaBanner(
                    text: l10n.adminClaimsSlaBreached(
                      _fmtDays(l10n, item.ageDays),
                    ),
                  ),
                Text(
                  l10n.adminClaimsDetailTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('ID: ${item.id}'),
                if ((item.businessId ?? '').isNotEmpty)
                  Text('${l10n.businessLabel}: ${item.businessId}'),
                const SizedBox(height: 6),
                Text('${l10n.adminClaimsFullNameColumn}: ${item.fullName}'),
                Text('${l10n.adminClaimsPhoneLabel}: ${item.phone}'),
                if ((item.evidenceUrl ?? '').isNotEmpty)
                  Text('${l10n.adminClaimsEvidenceLabel}: ${item.evidenceUrl}'),
                if ((item.note ?? '').isNotEmpty) Text('${l10n.note}: ${item.note}'),
                const SizedBox(height: 10),
                Text(
                  '${l10n.adminClaimsAssignedColumn}: ${_assignedLabel(l10n, item.assignedTo, userId)}',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.adminClaimsAdminNoteOptionalLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _claimDecisionTemplates(l10n)
                      .map(
                        (template) => ActionChip(
                          label: Text(template),
                          onPressed: () {
                            noteCtrl.text = template;
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.adminClaimsAutoRulesTitle,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: loading || applyingRules
                        ? null
                        : () async {
                            setModalState(() => applyingRules = true);
                            try {
                              final applied = await ref
                                  .read(adminClaimsControllerProvider.notifier)
                                  .applyRules(item.id);
                              if (!context.mounted) return;
                              if (applied) {
                                ref
                                    .read(adminNewItemsProvider.notifier)
                                    .clearClaims();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.adminClaimsAutoRuleApplied),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.adminClaimsNoAutoRuleFound),
                                  ),
                                );
                                setModalState(() => applyingRules = false);
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppErrorMapper.message(e)),
                                ),
                              );
                              setModalState(() => applyingRules = false);
                            }
                          },
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(
                      applyingRules
                          ? l10n.adminClaimsApplyingAction
                          : l10n.adminClaimsApplyRulesAction,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (userId != null &&
                        (item.assignedTo == null ||
                            item.assignedTo != userId)) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setModalState(() => loading = true);
                                  try {
                                    await ref
                                        .read(
                                          adminClaimsControllerProvider
                                              .notifier,
                                        )
                                        .assignToMe(item.id, adminId: userId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.adminClaimsDone),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppErrorMapper.message(e),
                                          ),
                                        ),
                                      );
                                    }
                                    setModalState(() => loading = false);
                                  }
                                },
                          child: Text(
                            loading
                                ? l10n.adminClaimsProcessingAction
                                : l10n.adminClaimsAssignToMeAction,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (item.assignedTo != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  setModalState(() => loading = true);
                                  try {
                                    await ref
                                        .read(
                                          adminClaimsControllerProvider
                                              .notifier,
                                        )
                                        .unassign(item.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.adminClaimsAssignmentRemoved,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppErrorMapper.message(e),
                                          ),
                                        ),
                                      );
                                    }
                                    setModalState(() => loading = false);
                                  }
                                },
                          child: Text(
                            loading
                                ? l10n.adminClaimsProcessingAction
                                : l10n.adminClaimsUnassignAction,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminClaimsControllerProvider.notifier,
                                      )
                                      .decide(
                                        claimId: item.id,
                                        decision: 'approved',
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.adminClaimsApproved),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppErrorMapper.message(e),
                                        ),
                                      ),
                                    );
                                  }
                                  setModalState(() => loading = false);
                                }
                              },
                        child: Text(
                          loading
                              ? l10n.adminClaimsProcessingAction
                              : l10n.adminAppealApproveAction,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModalState(() => loading = true);
                                try {
                                  await ref
                                      .read(
                                        adminClaimsControllerProvider.notifier,
                                      )
                                      .decide(
                                        claimId: item.id,
                                        decision: 'rejected',
                                        note: noteCtrl.text.trim(),
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.adminClaimsRejected),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppErrorMapper.message(e),
                                        ),
                                      ),
                                    );
                                  }
                                  setModalState(() => loading = false);
                                }
                              },
                        child: Text(
                          loading
                              ? l10n.adminClaimsProcessingAction
                              : l10n.adminAppealRejectAction,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      controller.closeDetail();
    });
  }

  void _closeDetail() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(adminClaimsControllerProvider.notifier).closeDetail();
  }

  void _toggleDetail(AdminClaimsState st) {
    if (st.isDetailOpen) {
      _closeDetail();
      return;
    }
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.adminClaimsSelectRowFirst)),
      );
      return;
    }
    final item = st.items[st.selectedIndex!];
    _openDetails(context, item, index: st.selectedIndex);
  }

  Future<void> _toggleAssign(AdminClaimsState st, String? userId) async {
    if (userId == null) return;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.adminClaimsSelectRowFirst)),
      );
      return;
    }
    final item = st.items[st.selectedIndex!];
    try {
      final controller = ref.read(adminClaimsControllerProvider.notifier);
      if (item.assignedTo == userId) {
        await controller.unassign(item.id);
      } else {
        await controller.assignToMe(item.id, adminId: userId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _handleAction(AdminClaimsState st, String key) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.adminClaimsSelectRowFirst)),
      );
      return;
    }
    final item = st.items[st.selectedIndex!];
    String? decision;
    if (key == 'P') decision = 'approved';
    if (key == 'R') decision = 'rejected';
    if (decision == null) return;
    try {
      await ref
          .read(adminClaimsControllerProvider.notifier)
          .decide(claimId: item.id, decision: decision);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _selectSamePhone(AdminClaimsState st) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      return;
    }
    final seed = st.items[st.selectedIndex!];
    final phone = seed.phone.trim();
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminClaimsNoPhone)),
      );
      return;
    }
    final ids = st.items
        .where((c) => c.phone.trim() == phone)
        .map((c) => c.id)
        .toSet();
    for (final itemId in ids) {
      ref
          .read(adminClaimsControllerProvider.notifier)
          .toggleSelection(itemId, true);
    }
  }

  Future<void> _assignSelectedToMe(AdminClaimsState st, String adminId) async {
    final controller = ref.read(adminClaimsControllerProvider.notifier);
    final selected = st.items
        .where((c) => st.selectedIds.contains(c.id))
        .toList();
    if (selected.isEmpty) return;
    var assigned = 0;
    for (final item in selected) {
      try {
        await controller.assignToMe(item.id, adminId: adminId);
        assigned++;
      } catch (_) {
        // Keep processing the rest.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(context.l10n.adminClaimsAssignedToYou(assigned))),
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selectedCount,
    required this.bulkDecision,
    required this.onDecisionChanged,
    required this.noteCtrl,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final String bulkDecision;
  final ValueChanged<String> onDecisionChanged;
  final TextEditingController noteCtrl;
  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Text(
          l10n.adminClaimsSelectedCount(selectedCount),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            key: ValueKey(bulkDecision),
            initialValue: bulkDecision.isEmpty ? null : bulkDecision,
            items: [
              DropdownMenuItem(
                value: 'approved',
                child: Text(l10n.adminAppealApproveAction),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text(l10n.adminAppealRejectAction),
              ),
            ],
            onChanged: (v) => onDecisionChanged(v ?? ''),
            decoration: InputDecoration(
              labelText: l10n.adminAppealDecisionLabel,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: l10n.adminClaimsAdminNoteOptionalLabel,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: onClear,
          child: Text(l10n.adminClaimsClearSelectionAction),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: onApply, child: Text(l10n.apply)),
      ],
    );
  }
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

WidgetStateProperty<Color?> _rowColor(bool active, bool slaBreached) =>
    appAdminRowColor(active: active, slaBreached: slaBreached);

String _assignedLabel(AppLocalizations l10n, String? assignedTo, String? userId) {
  if (assignedTo == null || assignedTo.isEmpty) {
    return l10n.adminClaimsAssignedUnassigned;
  }
  if (userId != null && assignedTo == userId) return l10n.adminClaimsAssignedMine;
  return l10n.adminClaimsAssignedAnotherAdmin;
}

String _fmtDays(AppLocalizations l10n, double v) =>
    l10n.adminClaimsAgeValue(v.toStringAsFixed(1));

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int _claimPriority(AdminOwnerClaimItem item) {
  var score = 0;
  if (item.slaBreached) score += 70;
  if (item.ageDays >= 3) score += 20;
  if ((item.evidenceUrl ?? '').trim().isEmpty) score += 15;
  if (item.status == 'pending') score += 10;
  return score;
}

String _claimStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'pending' => l10n.pending,
  'approved' => l10n.approved,
  'rejected' => l10n.rejected,
  _ => status,
};

List<String> _claimDecisionTemplates(AppLocalizations l10n) => <String>[
  l10n.adminClaimsDecisionTemplateApproved,
  l10n.adminClaimsDecisionTemplateRejected,
  l10n.adminClaimsDecisionTemplateNeedsDocuments,
];

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}

String _queueRouteForClaims({
  required String query,
  required String status,
}) {
  final queryParameters = <String, String>{
    'type': 'claim',
  };
  if (query.trim().isNotEmpty) {
    queryParameters['q'] = query.trim();
  }
  if (status.trim().isNotEmpty) {
    queryParameters['status'] = status.trim();
  }
  return Uri(path: '/admin/queue', queryParameters: queryParameters).toString();
}
