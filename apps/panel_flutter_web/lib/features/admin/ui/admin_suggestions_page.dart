import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_suggestions_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_suggestions_controller.dart';
import 'keyboard/admin_keyboard_shortcuts.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import '../../../shared/ui/design_system.dart';

class AdminSuggestionsPage extends ConsumerStatefulWidget {
  const AdminSuggestionsPage({super.key});

  @override
  ConsumerState<AdminSuggestionsPage> createState() =>
      _AdminSuggestionsPageState();
}

class _AdminSuggestionsPageState extends ConsumerState<AdminSuggestionsPage> {
  final searchCtrl = TextEditingController();
  final searchFocus = FocusNode();
  final bulkNoteCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminSuggestionsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    searchFocus.dispose();
    bulkNoteCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminSuggestionsControllerProvider);
    final controller = ref.read(adminSuggestionsControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;
    final allSelected =
        st.items.isNotEmpty &&
        st.items.every((s) => st.selectedIds.contains(s.id));
    final newItems = ref.watch(adminNewItemsProvider).suggestionsNew;

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
              title: Text(l10n.adminSuggestionsTitle),
              actions: [
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => _exportCsv(st),
                  icon: const Icon(Icons.download),
                  label: Text(
                    exporting
                        ? l10n.adminCommonDownloading
                        : l10n.adminCommonExportCsv,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(adminSuggestionsControllerProvider.notifier)
                        .refresh(force: true);
                    if (!context.mounted) return;
                    if (ok) {
                      ref
                          .read(adminNewItemsProvider.notifier)
                          .clearSuggestions();
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
                    onChanged: (v) => ref
                        .read(adminSuggestionsControllerProvider.notifier)
                        .setQuery(v.trim()),
                    decoration: InputDecoration(
                      hintText: l10n.adminSuggestionsSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    AppFilterChip(
                      label: 'SLA',
                      selected: st.slaOnly,
                      onTap: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .setSlaOnly(!st.slaOnly),
                    ),
                    AppFilterChip(
                      label: l10n.tumu,
                      selected: st.statusFilter.isEmpty,
                      onTap: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .setStatusFilter(''),
                    ),
                    AppFilterChip(
                      label: l10n.pending,
                      selected: st.statusFilter == 'pending',
                      onTap: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .setStatusFilter('pending'),
                    ),
                    AppFilterChip(
                      label: l10n.approved,
                      selected: st.statusFilter == 'approved',
                      onTap: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .setStatusFilter('approved'),
                    ),
                    AppFilterChip(
                      label: l10n.rejected,
                      selected: st.statusFilter == 'rejected',
                      onTap: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .setStatusFilter('rejected'),
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
                  onTap: () => ref
                      .read(adminSuggestionsControllerProvider.notifier)
                      .setAssignedFilter(''),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n.adminCommonUnassigned,
                  selected: st.assignedFilter == 'unassigned',
                  onTap: () => ref
                      .read(adminSuggestionsControllerProvider.notifier)
                      .setAssignedFilter('unassigned'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: l10n.adminCommonMine,
                  selected: st.assignedFilter == 'me',
                  onTap: () => ref
                      .read(adminSuggestionsControllerProvider.notifier)
                      .setAssignedFilter('me'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AdminNewItemsBanner(
              count: newItems,
              label: l10n.adminCommonNewRecordsAvailable,
              onRefresh: () async {
                final ok = await ref
                    .read(adminSuggestionsControllerProvider.notifier)
                    .refresh(force: true);
                if (!context.mounted) return;
                if (ok) {
                  ref.read(adminNewItemsProvider.notifier).clearSuggestions();
                }
              },
            ),
            if (newItems > 0) const SizedBox(height: 10),

            _BulkBar(
              selectedCount: st.selectedIds.length,
              noteCtrl: bulkNoteCtrl,
              onClear: () => ref
                  .read(adminSuggestionsControllerProvider.notifier)
                  .clearSelection(),
              onApply: st.selectedIds.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(adminSuggestionsControllerProvider.notifier)
                            .bulkReject(adminNote: bulkNoteCtrl.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.rejected)),
                          );
                        }
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
                  : ListView(
                      controller: scrollCtrl,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: allSelected,
                                  onChanged: (v) => ref
                                      .read(
                                        adminSuggestionsControllerProvider
                                            .notifier,
                                      )
                                      .selectAllVisible(v ?? false),
                                ),
                              ),
                              const DataColumn(label: Text('ID')),
                              DataColumn(
                                label: Text(l10n.adminSuggestionsNameColumn),
                              ),
                              DataColumn(
                                label: Text(l10n.adminSuggestionsStatusColumn),
                              ),
                              DataColumn(label: Text(l10n.adminCommonAssigned)),
                              DataColumn(
                                label: Text(l10n.adminSuggestionsCreatedAtColumn),
                              ),
                              DataColumn(label: Text(l10n.adminCommonAge)),
                              const DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (var i = 0; i < st.items.length; i++)
                                DataRow(
                                  color: _rowColor(
                                    st.selectedIndex == i,
                                    st.items[i].slaBreached,
                                  ),
                                  selected: st.selectedIds.contains(
                                    st.items[i].id,
                                  ),
                                  onSelectChanged: (_) => _openDetails(
                                    context,
                                    st.items[i],
                                    index: i,
                                  ),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: st.selectedIds.contains(
                                          st.items[i].id,
                                        ),
                                        onChanged: (v) => ref
                                            .read(
                                              adminSuggestionsControllerProvider
                                                  .notifier,
                                            )
                                            .toggleSelection(
                                              st.items[i].id,
                                              v ?? false,
                                            ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          if (st.items[i].slaBreached) ...[
                                            const AppSlaBadge(),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(_short(st.items[i].id)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(st.items[i].name)),
                                    DataCell(
                                      Text(
                                        _suggestionStatusLabel(
                                          context,
                                          st.items[i].status,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _assignedLabel(
                                          context,
                                          st.items[i].assignedTo,
                                          user?.id,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(_fmtDate(st.items[i].createdAt)),
                                    ),
                                    DataCell(
                                      Text(_fmtDays(context, st.items[i].ageDays)),
                                    ),
                                    DataCell(
                                      TextButton(
                                        onPressed: () => _openDetails(
                                          context,
                                          st.items[i],
                                          index: i,
                                        ),
                                        child: Text(l10n.adminCommonDetails),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (!st.isLoading && st.items.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(l10n.adminCommonNoRecordsFound),
                            ),
                          ),
                        if (st.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(AdminSuggestionsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminSuggestionsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        query: st.query,
      );
      final filename = 'suggestions_${_stamp()}.csv';
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
    AdminSuggestionItem item, {
    int? index,
  }) async {
    final l10n = context.l10n;
    final controller = ref.read(adminSuggestionsControllerProvider.notifier);
    if (index != null) {
      controller.selectIndex(index);
    }
    controller.openDetail();
    final userId = ref.read(userProvider)?.id;
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
    var loading = false;

    ref
        .read(adminSuggestionsControllerProvider.notifier)
        .loadDuplicates(item.id);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dupState = ref.watch(adminSuggestionsControllerProvider);
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.slaBreached)
                    AppSlaBanner(
                      text: l10n.adminSuggestionsSlaExceeded(
                        _fmtDays(context, item.ageDays),
                      ),
                    ),
                  Text(
                    l10n.adminSuggestionsDetailTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text('ID: ${item.id}'),
                  if ((item.category ?? '').isNotEmpty)
                    Text('${l10n.adminSuggestionsCategoryLabel}: ${item.category}'),
                  Text(
                    '${l10n.adminSuggestionsLocationLabel}: ${_locText(context, item.district, item.city)}',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${l10n.adminCommonAssigned}: ${_assignedLabel(context, item.assignedTo, userId)}',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.adminSuggestionsAdminNoteOptional,
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
                                            adminSuggestionsControllerProvider
                                                .notifier,
                                          )
                                          .assignToMe(item.id, adminId: userId);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.adminSuggestionsAssignedToMe,
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
                                  ? l10n.adminCommonProcessing
                                  : l10n.adminReportsAssignToMe,
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
                                            adminSuggestionsControllerProvider
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
                                              l10n.adminReportsAssignmentRemoved,
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
                                  ? l10n.adminCommonProcessing
                                  : l10n.adminReportsUnassign,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    l10n.adminSuggestionsPossibleDuplicatesTitle,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (dupState.duplicatesLoading)
                    const _DuplicatesSkeleton()
                  else if (dupState.duplicatesError != null)
                    _DuplicatesError(
                      message: AppErrorMapper.message(dupState.duplicatesError),
                      onRetry: () => ref
                          .read(adminSuggestionsControllerProvider.notifier)
                          .loadDuplicates(item.id),
                    )
                  else if (dupState.duplicates.isEmpty)
                    Text(l10n.adminSuggestionsNoSimilarBusiness)
                  else
                    Column(
                      children: [
                        for (final d in dupState.duplicates) ...[
                          _DuplicateRow(
                            dup: d,
                            onLink: () => _linkToExisting(
                              suggestionId: item.id,
                              businessId: d.id,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),

                  const SizedBox(height: 12),
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
                                          adminSuggestionsControllerProvider
                                              .notifier,
                                        )
                                        .approve(
                                          suggestionId: item.id,
                                          adminNote: noteCtrl.text.trim(),
                                        );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.adminSuggestionsCreatedNewBusiness,
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
                                ? l10n.adminCommonProcessing
                                : l10n.adminSuggestionsCreateNewBusiness,
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
                                          adminSuggestionsControllerProvider
                                              .notifier,
                                        )
                                        .reject(
                                          suggestionId: item.id,
                                          adminNote: noteCtrl.text.trim(),
                                        );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(l10n.rejected)),
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
                                ? l10n.adminCommonProcessing
                                : l10n.rejected,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
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
    ref.read(adminSuggestionsControllerProvider.notifier).closeDetail();
  }

  void _toggleDetail(AdminSuggestionsState st) {
    final l10n = context.l10n;
    if (st.isDetailOpen) {
      _closeDetail();
      return;
    }
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminCommonSelectRow)));
      return;
    }
    final item = st.items[st.selectedIndex!];
    _openDetails(context, item, index: st.selectedIndex);
  }

  Future<void> _toggleAssign(AdminSuggestionsState st, String? userId) async {
    final l10n = context.l10n;
    if (userId == null) return;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminCommonSelectRow)));
      return;
    }
    final item = st.items[st.selectedIndex!];
    try {
      final controller = ref.read(adminSuggestionsControllerProvider.notifier);
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

  Future<void> _handleAction(AdminSuggestionsState st, String key) async {
    final l10n = context.l10n;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminCommonSelectRow)));
      return;
    }
    final item = st.items[st.selectedIndex!];
    try {
      final controller = ref.read(adminSuggestionsControllerProvider.notifier);
      if (key == 'N') {
        await controller.approve(suggestionId: item.id);
        return;
      }
      if (key == 'R') {
        await controller.reject(suggestionId: item.id);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _linkToExisting({
    required String suggestionId,
    required String businessId,
  }) async {
    final l10n = context.l10n;
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminSuggestionsLinkExistingConfirmTitle),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.adminSuggestionsAdminNoteOptional,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.start),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    try {
      await ref
          .read(adminSuggestionsControllerProvider.notifier)
          .linkToExisting(
            suggestionId: suggestionId,
            businessId: businessId,
            adminNote: noteCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminSuggestionsLinkedToExisting)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selectedCount,
    required this.noteCtrl,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final TextEditingController noteCtrl;
  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Text(
          l10n.adminReportsSelectedCount(selectedCount),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: l10n.adminSuggestionsAdminNoteOptional,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: onClear, child: Text(l10n.adminCommonClear)),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onApply,
          child: Text(l10n.adminSuggestionsRejectSelected),
        ),
      ],
    );
  }
}

class _DuplicatesSkeleton extends StatelessWidget {
  const _DuplicatesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _SkeletonCard(),
        );
      }),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, width: 140, color: AppColors.border),
          const SizedBox(height: 8),
          Container(height: 10, width: 200, color: AppColors.border),
        ],
      ),
    );
  }
}

class _DuplicatesError extends StatelessWidget {
  const _DuplicatesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.danger)),
        const SizedBox(height: 6),
        OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _DuplicateRow extends StatelessWidget {
  const _DuplicateRow({required this.dup, required this.onLink});
  final DuplicateBusiness dup;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = dup.score;
    final scoreColor = score >= 0.8
        ? AppColors.success
        : (score >= 0.65 ? AppColors.warning : AppColors.muted);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dup.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _locText(context, dup.district, dup.city),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '%${(score * 100).toStringAsFixed(0)}',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onLink,
            child: Text(l10n.adminSuggestionsLinkToThisBusiness),
          ),
        ],
      ),
    );
  }
}

String _locText(BuildContext context, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return context.l10n.adminSuggestionsNoLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d • $c';
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

WidgetStateProperty<Color?> _rowColor(bool active, bool slaBreached) =>
    appAdminRowColor(active: active, slaBreached: slaBreached);

String _assignedLabel(BuildContext context, String? assignedTo, String? userId) {
  final l10n = context.l10n;
  if (assignedTo == null || assignedTo.isEmpty) return l10n.adminCommonUnassigned;
  if (userId != null && assignedTo == userId) return l10n.adminCommonMine;
  return l10n.adminCommonOtherAdmin;
}

String _fmtDays(BuildContext context, double v) {
  return context.l10n.adminSuggestionsDaysValue(v.toStringAsFixed(1));
}

String _suggestionStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status) {
    case 'pending':
      return l10n.pending;
    case 'approved':
      return l10n.approved;
    case 'rejected':
      return l10n.rejected;
    default:
      return status;
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _stamp() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  return '$y$m${d}_$hh$mm';
}
