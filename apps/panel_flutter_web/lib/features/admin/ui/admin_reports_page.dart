import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/admin_table_saved_views_prefs.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_reports_repository.dart';
import '../domain/admin_models.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_reports_controller.dart';
import 'keyboard/admin_keyboard_shortcuts.dart';
import 'web_download.dart';
import 'widgets/admin_new_items_banner.dart';
import 'widgets/admin_table.dart';
import '../../../shared/ui/design_system.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  static const _savedViewScope = 'admin_reports';

  final searchCtrl = TextEditingController();
  final searchFocus = FocusNode();
  final bulkNoteCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  String bulkStatus = '';
  bool exporting = false;
  bool moderationToolsLoading = false;
  int duplicatePhotoGroups = 0;
  int copiedMenuGroups = 0;
  DateTimeRange? _dateRange;
  String _sortKey = 'createdAt';
  bool _sortAscending = false;
  int _page = 0;
  int _rowsPerPage = 20;
  List<AdminSavedViewRecord> _savedViews = const [];
  String? _selectedSavedViewId;

  @override
  void initState() {
    super.initState();
    _loadSavedViews();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(adminReportsControllerProvider.notifier).loadMore();
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

  Future<void> _loadSavedViews() async {
    final views = await AdminTableSavedViewsPrefs.read(_savedViewScope);
    if (!mounted) return;
    setState(() => _savedViews = views);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminReportsControllerProvider);
    final controller = ref.read(adminReportsControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;
    final filteredItems = _filterAndSortReports(st);
    final estimatedTotalCount =
        filteredItems.length + (st.hasMore ? _rowsPerPage : 0);
    final safePage = estimatedTotalCount == 0
        ? 0
        : _page.clamp(0, ((estimatedTotalCount - 1) ~/ _rowsPerPage)).toInt();
    final start = safePage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredItems.length);
    final pageItems = filteredItems.sublist(start, end);
    final allPageSelected =
        pageItems.isNotEmpty &&
        pageItems.every((item) => st.selectedIds.contains(item.id));
    final newItems = ref.watch(adminNewItemsProvider).reportsNew;
    final reasonCounts = <String, int>{};
    for (final item in filteredItems) {
      final key = item.reason.trim().isEmpty
          ? l10n.adminReportsOtherReason
          : item.reason.trim();
      reasonCounts[key] = (reasonCounts[key] ?? 0) + 1;
    }
    final sortedReasons = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            Row(
              children: [
                Text(
                  l10n.adminReportsTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => _exportCsv(st),
                  icon: const Icon(Icons.download),
                  label: Text(
                    exporting
                        ? l10n.adminCommonDownloading
                        : l10n.adminCommonExportCsv,
                    ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    _queueRouteForReports(
                      query: st.query,
                      status: st.statusFilter,
                    ),
                  ),
                  icon: const Icon(Icons.alt_route),
                  label: Text(l10n.adminQueueOpenFromReportsAction),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(adminReportsControllerProvider.notifier)
                        .refresh(force: true);
                    if (!context.mounted) return;
                    if (ok) {
                      ref.read(adminNewItemsProvider.notifier).clearReports();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AdminTableFilterBar(
              searchController: searchCtrl,
              searchHint: l10n.adminReportsSearchHint,
              statusValue: st.statusFilter,
              statusOptions: [
                AdminTableStatusOption(value: '', label: l10n.tumu),
                AdminTableStatusOption(
                  value: 'acik',
                  label: l10n.adminReportsStatusOpen,
                ),
                AdminTableStatusOption(
                  value: 'inceleniyor',
                  label: l10n.adminReportsStatusInvestigating,
                ),
                AdminTableStatusOption(
                  value: 'kapandi',
                  label: l10n.adminReportsStatusClosed,
                ),
                AdminTableStatusOption(
                  value: 'reddedildi',
                  label: l10n.rejected,
                ),
              ],
              onSearchChanged: (value) {
                controller.setQuery(value.trim());
                setState(() {
                  _page = 0;
                  _selectedSavedViewId = null;
                });
              },
              onStatusChanged: (value) {
                controller.setStatusFilter(value);
                setState(() {
                  _page = 0;
                  _selectedSavedViewId = null;
                });
              },
              dateRange: _dateRange,
              onPickDateRange: _pickDateRange,
              onClearDateRange: () {
                setState(() {
                  _dateRange = null;
                  _page = 0;
                  _selectedSavedViewId = null;
                });
              },
              savedViews: _savedViews,
              selectedSavedViewId: _selectedSavedViewId,
              onSavedViewSelected: (value) => _applySavedView(value, controller),
              onSaveCurrentView: () => _saveCurrentView(st),
              onDeleteSavedView: _deleteSavedView,
              extraFilters: [
                AppFilterChip(
                  label: l10n.sla,
                  selected: st.slaOnly,
                  onTap: () {
                    controller.setSlaOnly(!st.slaOnly);
                    setState(() {
                      _page = 0;
                      _selectedSavedViewId = null;
                    });
                  },
                ),
                AppFilterChip(
                  label: l10n.tumu,
                  selected: st.assignedFilter.isEmpty,
                  onTap: () {
                    controller.setAssignedFilter('');
                    setState(() {
                      _page = 0;
                      _selectedSavedViewId = null;
                    });
                  },
                ),
                AppFilterChip(
                  label: l10n.adminCommonUnassigned,
                  selected: st.assignedFilter == 'unassigned',
                  onTap: () {
                    controller.setAssignedFilter('unassigned');
                    setState(() {
                      _page = 0;
                      _selectedSavedViewId = null;
                    });
                  },
                ),
                AppFilterChip(
                  label: l10n.adminCommonMine,
                  selected: st.assignedFilter == 'me',
                  onTap: () {
                    controller.setAssignedFilter('me');
                    setState(() {
                      _page = 0;
                      _selectedSavedViewId = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedReasons.isNotEmpty) ...[
              _ReasonSummaryCard(items: sortedReasons),
              const SizedBox(height: 12),
            ],
            _ModerationToolsCard(
              loading: moderationToolsLoading,
              duplicatePhotoGroups: duplicatePhotoGroups,
              copiedMenuGroups: copiedMenuGroups,
              onRun: _runModerationScans,
            ),
            const SizedBox(height: 12),

            AdminNewItemsBanner(
              count: newItems,
              label: l10n.adminCommonNewRecordsAvailable,
              onRefresh: () async {
                final ok = await ref
                    .read(adminReportsControllerProvider.notifier)
                    .refresh(force: true);
                if (!context.mounted) return;
                if (ok) {
                  ref.read(adminNewItemsProvider.notifier).clearReports();
                }
              },
            ),
            if (newItems > 0) const SizedBox(height: 10),
            AdminTableBulkBar(
              selectedCount: st.selectedIds.length,
              onClear: controller.clearSelection,
              actions: [
                AdminTableBulkAction(
                  label: l10n.adminReportsSelectSameReporter,
                  icon: Icons.group_work_outlined,
                  onPressed:
                      st.selectedIndex == null ? null : () => _selectSameReporter(st),
                ),
                AdminTableBulkAction(
                  label: l10n.adminTableAssignToMeAction,
                  icon: Icons.assignment_ind_outlined,
                  onPressed: st.selectedIds.isEmpty || user?.id == null
                      ? null
                      : () => _assignSelectedToMe(st, user!.id),
                ),
                AdminTableBulkAction(
                  label: l10n.adminReportsCloseSpamWave,
                  icon: Icons.block_outlined,
                  onPressed:
                      st.selectedIds.isEmpty ? null : () => _closeSelectedAsSpam(st),
                  primary: true,
                ),
              ],
            ),
            if (st.selectedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _BulkBar(
                selectedCount: st.selectedIds.length,
                bulkStatus: bulkStatus,
                onStatusChanged: (v) => setState(() => bulkStatus = v),
                noteCtrl: bulkNoteCtrl,
                onClear: controller.clearSelection,
                onApply: st.selectedIds.isEmpty || bulkStatus.isEmpty
                    ? null
                    : () async {
                        try {
                          await controller.bulkUpdateStatus(
                            status: bulkStatus,
                            adminNote: bulkNoteCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.adminCommonUpdated)),
                            );
                          }
                          setState(() => bulkStatus = '');
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
            ],

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
                          child: AdminTableCard(
                            emptyLabel: l10n.adminCommonNoRecordsFound,
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: allPageSelected,
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
                              DataColumn(
                                label: const Text('ID'),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('id', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminReportsReasonColumn),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('reason', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminCommonPriority),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('priority', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminReportsStatusColumn),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('status', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminCommonAssigned),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('assigned', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminReportsCreatedAtColumn),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('createdAt', ascending),
                              ),
                              DataColumn(
                                label: Text(l10n.adminCommonAge),
                                onSort: (_, ascending) =>
                                    _sortReportsBy('age', ascending),
                              ),
                              DataColumn(label: Text(l10n.adminReportsPhotoColumn)),
                              const DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final item in pageItems)
                                _buildReportRow(
                                  context: context,
                                  item: item,
                                  state: st,
                                  userId: user?.id,
                                ),
                            ],
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
                          onPageChanged: (value) => _changeReportsPage(
                            value,
                            state: st,
                            filteredCount: filteredItems.length,
                          ),
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _rowsPerPage = value;
                              _page = 0;
                              _selectedSavedViewId = null;
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

  List<AdminReportItem> _filterAndSortReports(AdminReportsState state) {
    final filtered = state.items.where((item) {
      if (_dateRange == null) return true;
      final createdDay = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
      );
      return !createdDay.isBefore(start) && !createdDay.isAfter(end);
    }).toList();

    filtered.sort((a, b) {
      final direction = _sortAscending ? 1 : -1;
      return switch (_sortKey) {
        'id' => direction * a.id.compareTo(b.id),
        'reason' => direction *
            a.reason.toLowerCase().compareTo(b.reason.toLowerCase()),
        'priority' => direction * _reportPriority(a).compareTo(_reportPriority(b)),
        'status' => direction * a.status.compareTo(b.status),
        'assigned' =>
          direction * (a.assignedTo ?? '').compareTo(b.assignedTo ?? ''),
        'age' => direction * a.ageHours.compareTo(b.ageHours),
        _ => direction * a.createdAt.compareTo(b.createdAt),
      };
    });
    return filtered;
  }

  void _sortReportsBy(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAscending = ascending;
      _page = 0;
      _selectedSavedViewId = null;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateRange = picked;
      _page = 0;
      _selectedSavedViewId = null;
    });
  }

  Future<void> _saveCurrentView(AdminReportsState state) async {
    final label = await promptAdminTableSavedViewLabel(context);
    if (label == null) return;
    await AdminTableSavedViewsPrefs.upsert(
      scope: _savedViewScope,
      label: label,
      payload: {
        'query': searchCtrl.text.trim(),
        'status': state.statusFilter,
        'assigned': state.assignedFilter,
        'sla_only': state.slaOnly,
        'date_start': _dateRange?.start.toIso8601String(),
        'date_end': _dateRange?.end.toIso8601String(),
        'sort_key': _sortKey,
        'sort_ascending': _sortAscending,
        'rows_per_page': _rowsPerPage,
      },
    );
    await _loadSavedViews();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.adminTableSavedViewCreated)),
    );
  }

  Future<void> _deleteSavedView(String id) async {
    await AdminTableSavedViewsPrefs.delete(scope: _savedViewScope, id: id);
    await _loadSavedViews();
    if (!mounted) return;
    setState(() => _selectedSavedViewId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.adminTableSavedViewDeleted)),
    );
  }

  void _applySavedView(
    String? id,
    AdminReportsController controller,
  ) {
    if (id == null) {
      setState(() => _selectedSavedViewId = null);
      return;
    }
    final savedView = _savedViews.where((item) => item.id == id).firstOrNull;
    if (savedView == null) return;
    final payload = savedView.payload;
    searchCtrl.text = (payload['query'] ?? '').toString();
    controller.setQuery(searchCtrl.text.trim());
    controller.setStatusFilter((payload['status'] ?? '').toString());
    controller.setAssignedFilter((payload['assigned'] ?? '').toString());
    controller.setSlaOnly(payload['sla_only'] == true);
    final start = DateTime.tryParse((payload['date_start'] ?? '').toString());
    final end = DateTime.tryParse((payload['date_end'] ?? '').toString());
    setState(() {
      _selectedSavedViewId = id;
      _dateRange = start == null || end == null
          ? null
          : DateTimeRange(start: start, end: end);
      _sortKey = (payload['sort_key'] ?? 'createdAt').toString();
      _sortAscending = payload['sort_ascending'] == true;
      _rowsPerPage =
          int.tryParse((payload['rows_per_page'] ?? '20').toString()) ?? 20;
      _page = 0;
    });
  }

  void _changeReportsPage(
    int value, {
    required AdminReportsState state,
    required int filteredCount,
  }) {
    setState(() => _page = value);
    final requiredItems = (value + 1) * _rowsPerPage;
    if (requiredItems > filteredCount && state.hasMore && !state.isLoadingMore) {
      ref.read(adminReportsControllerProvider.notifier).loadMore();
    }
  }

  DataRow _buildReportRow({
    required BuildContext context,
    required AdminReportItem item,
    required AdminReportsState state,
    required String? userId,
  }) {
    final sourceIndex = state.items.indexWhere((entry) => entry.id == item.id);
    final l10n = context.l10n;
    return DataRow(
      color: _rowColor(state.selectedIndex == sourceIndex, item.slaBreached),
      selected: state.selectedIds.contains(item.id),
      onSelectChanged: (_) => _openDetails(
        context,
        item,
        index: sourceIndex >= 0 ? sourceIndex : null,
      ),
      cells: [
        DataCell(
          Checkbox(
            value: state.selectedIds.contains(item.id),
            onChanged: (value) => ref
                .read(adminReportsControllerProvider.notifier)
                .toggleSelection(item.id, value ?? false),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (item.slaBreached) ...[
                const AppSlaBadge(),
                const SizedBox(width: 6),
              ],
              Text(_short(item.id)),
            ],
          ),
        ),
        DataCell(Text(item.reason)),
        DataCell(AppPriorityBadge(score: _reportPriority(item))),
        DataCell(
          Row(
            children: [
              Text(_reportStatusLabel(context, item.status)),
              if (item.autoModerated) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: l10n.adminReportsAutoModerationApplied,
                  child: const AppAutoBadge(),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(_assignedLabel(context, item.assignedTo, userId))),
        DataCell(Text(_fmtDate(item.createdAt))),
        DataCell(Text(_fmtHours(context, item.ageHours))),
        DataCell(
          Row(
            children: [
              if ((item.menuItemPhotoId ?? '').isNotEmpty)
                IconButton(
                  onPressed: () =>
                      _openReportedMenuPhoto(context, ref, item.menuItemPhotoId!),
                  tooltip: l10n.adminReportsMenuPhotoTooltip,
                  icon: const Icon(Icons.photo_outlined, size: 18),
                ),
              if ((item.targetType ?? '') == 'business_media' &&
                  (item.targetId ?? '').isNotEmpty)
                IconButton(
                  onPressed: () =>
                      _openReportedBusinessMedia(context, ref, item.targetId!),
                  tooltip: l10n.adminReportsBusinessPhotoTooltip,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                ),
            ],
          ),
        ),
        DataCell(
          TextButton(
            onPressed: () => _openDetails(
              context,
              item,
              index: sourceIndex >= 0 ? sourceIndex : null,
            ),
            child: Text(l10n.adminCommonDetails),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCsv(AdminReportsState st) async {
    setState(() => exporting = true);
    try {
      final repo = ref.read(adminReportsRepositoryProvider);
      final csv = await repo.exportCsv(
        status: st.statusFilter,
        query: st.query,
      );
      final filename = 'reports_${_stamp()}.csv';
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
    AdminReportItem item, {
    int? index,
  }) async {
    final l10n = context.l10n;
    final controller = ref.read(adminReportsControllerProvider.notifier);
    if (index != null) {
      controller.selectIndex(index);
    }
    controller.openDetail();
    final userId = ref.read(userProvider)?.id;
    final noteCtrl = TextEditingController(text: item.adminNote ?? '');
    var status = item.status;
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
                    text: l10n.adminReportsSlaExceeded(
                      _fmtHours(context, item.ageHours),
                    ),
                  ),
                Text(
                  l10n.adminReportsDetailTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text('ID: ${item.id}'),
                if ((item.businessId ?? '').isNotEmpty)
                  Text('${l10n.businessLabel}: ${item.businessId}'),
                if ((item.reviewId ?? '').isNotEmpty)
                  Text('${l10n.adminReportsReviewLabel}: ${item.reviewId}'),
                if ((item.menuItemPhotoId ?? '').isNotEmpty)
                  Text(
                    '${l10n.adminReportsMenuPhotoLabel}: ${item.menuItemPhotoId}',
                  ),
                if ((item.targetType ?? '').isNotEmpty)
                  Text(
                    l10n.adminReportsTargetValue(
                      item.targetType!,
                      item.targetId ?? '-',
                    ),
                  ),
                if ((item.menuItemPhotoId ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _openReportedMenuPhoto(
                      context,
                      ref,
                      item.menuItemPhotoId!,
                    ),
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(l10n.adminReportsOpenPhoto),
                  ),
                  const SizedBox(height: 6),
                  _ShadowInfo(
                    label: l10n.adminReportsMenuPhotoLabel,
                    future: _fetchMenuPhotoShadow(ref, item.menuItemPhotoId!),
                  ),
                ],
                if ((item.targetType ?? '') == 'business_media' &&
                    (item.targetId ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _openReportedBusinessMedia(
                      context,
                      ref,
                      item.targetId!,
                    ),
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(l10n.adminReportsOpenPhoto),
                  ),
                  const SizedBox(height: 6),
                  _ShadowInfo(
                    label: l10n.adminReportsBusinessPhotoLabel,
                    future: _fetchBusinessMediaShadow(ref, item.targetId!),
                  ),
                ],
                const SizedBox(height: 6),
                Text('${l10n.adminReportsReasonLabel}: ${item.reason}'),
                if ((item.details ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${l10n.adminCommonDetails}: ${item.details}'),
                ],
                const SizedBox(height: 10),
                Text(
                  '${l10n.adminCommonAssigned}: ${_assignedLabel(context, item.assignedTo, userId)}',
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(status),
                  initialValue: status,
                  items: [
                    DropdownMenuItem(
                      value: 'acik',
                      child: Text(l10n.adminReportsStatusOpen),
                    ),
                    DropdownMenuItem(
                      value: 'inceleniyor',
                      child: Text(l10n.adminReportsStatusInvestigating),
                    ),
                    DropdownMenuItem(
                      value: 'kapandi',
                      child: Text(l10n.adminReportsStatusClosed),
                    ),
                    DropdownMenuItem(
                      value: 'reddedildi',
                      child: Text(l10n.rejected),
                    ),
                  ],
                  onChanged: loading
                      ? null
                      : (v) => setModalState(() => status = v ?? status),
                  decoration: InputDecoration(
                    labelText: l10n.adminReportsStatusColumn,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.adminReportsAdminNoteOptional,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _reportDecisionTemplates(context)
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
                  l10n.adminReportsAutomaticRulesTitle,
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
                                  .read(adminReportsControllerProvider.notifier)
                                  .applyRules(item.id);
                              if (!context.mounted) return;
                              if (applied) {
                                ref
                                    .read(adminNewItemsProvider.notifier)
                                    .clearReports();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.adminReportsAutomaticRuleApplied,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.adminReportsAutomaticRuleNotFound,
                                    ),
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
                          ? l10n.adminReportsApplyingRules
                          : l10n.adminReportsApplyRules,
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
                                          adminReportsControllerProvider
                                              .notifier,
                                        )
                                        .assignToMe(item.id, adminId: userId);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.adminReportsClaimed),
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
                                          adminReportsControllerProvider
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            setModalState(() => loading = true);
                            try {
                              await ref
                                  .read(adminReportsControllerProvider.notifier)
                                  .updateStatus(
                                    reportId: item.id,
                                    status: status,
                                    adminNote: noteCtrl.text.trim(),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.adminCommonUpdated),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppErrorMapper.message(e)),
                                  ),
                                );
                              }
                              setModalState(() => loading = false);
                            }
                          },
                    child: Text(loading ? l10n.saving : l10n.save),
                  ),
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
    ref.read(adminReportsControllerProvider.notifier).closeDetail();
  }

  void _toggleDetail(AdminReportsState st) {
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

  Future<void> _toggleAssign(AdminReportsState st, String? userId) async {
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
      final controller = ref.read(adminReportsControllerProvider.notifier);
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

  Future<void> _handleAction(AdminReportsState st, String key) async {
    final l10n = context.l10n;
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.adminCommonSelectRow)));
      return;
    }
    final item = st.items[st.selectedIndex!];
    String? status;
    if (key == 'I') status = 'inceleniyor';
    if (key == 'C') status = 'kapandi';
    if (key == 'R') status = 'reddedildi';
    if (status == null) return;
    try {
      await ref
          .read(adminReportsControllerProvider.notifier)
          .updateStatus(reportId: item.id, status: status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _selectSameReporter(AdminReportsState st) async {
    if (st.selectedIndex == null || st.selectedIndex! >= st.items.length) {
      return;
    }
    final seed = st.items[st.selectedIndex!];
    final reporterId = (seed.reporterId ?? '').trim();
    if (reporterId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminReportsMissingReporterInfo)),
      );
      return;
    }
    final ids = st.items
        .where((r) => (r.reporterId ?? '').trim() == reporterId)
        .map((r) => r.id)
        .toSet();
    for (final itemId in ids) {
      ref
          .read(adminReportsControllerProvider.notifier)
          .toggleSelection(itemId, true);
    }
  }

  Future<void> _closeSelectedAsSpam(AdminReportsState st) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(adminReportsControllerProvider.notifier)
          .bulkUpdateStatus(
            status: 'kapandi',
            adminNote: l10n.adminReportsBulkSpamNote,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminReportsSelectedClosed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _assignSelectedToMe(AdminReportsState st, String adminId) async {
    final l10n = context.l10n;
    final controller = ref.read(adminReportsControllerProvider.notifier);
    final selected = st.items
        .where((r) => st.selectedIds.contains(r.id))
        .toList();
    if (selected.isEmpty) return;
    var assigned = 0;
    for (final item in selected) {
      try {
        await controller.assignToMe(item.id, adminId: adminId);
        assigned++;
      } catch (_) {
        // Continue with the rest.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(l10n.adminReportsAssignedCount(assigned))),
    );
  }

  Future<void> _runModerationScans() async {
    final l10n = context.l10n;
    setState(() => moderationToolsLoading = true);
    try {
      final client = ref.read(supabaseProvider);
      final photoGroups = await _detectDuplicatePhotos(client);
      final menuGroups = await _detectCopiedMenus(client);
      if (!mounted) return;
      setState(() {
        duplicatePhotoGroups = photoGroups;
        copiedMenuGroups = menuGroups;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.adminReportsModerationScanComplete(photoGroups, menuGroups),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      if (mounted) {
        setState(() => moderationToolsLoading = false);
      }
    }
  }
}

Future<int> _detectDuplicatePhotos(dynamic client) async {
  final res = await client
      .from('menu_item_photos')
      .select('id,business_id,url')
      .order('created_at', ascending: false)
      .limit(1200);
  final rows = (res as List?) ?? const [];
  final groups = <String, Set<String>>{};
  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final businessId = (map['business_id'] ?? '').toString();
    final url = (map['url'] ?? '').toString();
    if (businessId.isEmpty || url.isEmpty) continue;
    final sig = _photoSignature(url);
    if (sig.isEmpty) continue;
    groups.putIfAbsent(sig, () => <String>{}).add(businessId);
  }
  return groups.values.where((bids) => bids.length >= 2).length;
}

Future<int> _detectCopiedMenus(dynamic client) async {
  final res = await client
      .from('menu_items')
      .select('id,business_id,name,price_cents,status')
      .eq('status', 'published')
      .order('updated_at', ascending: false)
      .limit(2000);
  final rows = (res as List?) ?? const [];
  final groups = <String, Set<String>>{};
  for (final row in rows.whereType<Map>()) {
    final map = row.cast<String, dynamic>();
    final businessId = (map['business_id'] ?? '').toString();
    final name = (map['name'] ?? '').toString().trim().toLowerCase();
    final price = (map['price_cents'] ?? '').toString();
    if (businessId.isEmpty || name.isEmpty || price.isEmpty) continue;
    final sig = '$name|$price';
    groups.putIfAbsent(sig, () => <String>{}).add(businessId);
  }
  return groups.values.where((bids) => bids.length >= 3).length;
}

String _photoSignature(String url) {
  final clean = url.split('?').first;
  final file = clean.split('/').isNotEmpty ? clean.split('/').last : clean;
  final base = file.toLowerCase().replaceAll(
    RegExp(r'\.(jpg|jpeg|png|webp)$'),
    '',
  );
  final compact = base.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (compact.length < 6) return '';
  return compact;
}

class _ReasonSummaryCard extends StatelessWidget {
  const _ReasonSummaryCard({required this.items});

  final List<MapEntry<String, int>> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, e) => sum + e.value);
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminReportsReasonDistribution(total),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in items.take(8))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModerationToolsCard extends StatelessWidget {
  const _ModerationToolsCard({
    required this.loading,
    required this.duplicatePhotoGroups,
    required this.copiedMenuGroups,
    required this.onRun,
  });

  final bool loading;
  final int duplicatePhotoGroups;
  final int copiedMenuGroups;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.adminReportsModerationSummary(
                duplicatePhotoGroups,
                copiedMenuGroups,
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: loading ? null : onRun,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_outlined),
            label: Text(
              loading ? l10n.adminReportsScanning : l10n.adminReportsScan,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  const _BulkBar({
    required this.selectedCount,
    required this.bulkStatus,
    required this.onStatusChanged,
    required this.noteCtrl,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final String bulkStatus;
  final ValueChanged<String> onStatusChanged;
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
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            key: ValueKey(bulkStatus),
            initialValue: bulkStatus.isEmpty ? null : bulkStatus,
            items: [
              DropdownMenuItem(
                value: 'acik',
                child: Text(l10n.adminReportsStatusOpen),
              ),
              DropdownMenuItem(
                value: 'inceleniyor',
                child: Text(l10n.adminReportsStatusInvestigating),
              ),
              DropdownMenuItem(
                value: 'kapandi',
                child: Text(l10n.adminReportsStatusClosed),
              ),
              DropdownMenuItem(
                value: 'reddedildi',
                child: Text(l10n.rejected),
              ),
            ],
            onChanged: (v) => onStatusChanged(v ?? ''),
            decoration: InputDecoration(labelText: l10n.adminReportsStatusColumn),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: l10n.adminReportsAdminNoteOptional,
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: onClear,
          child: Text(l10n.adminCommonClear),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: onApply, child: Text(l10n.apply)),
      ],
    );
  }
}

String _short(String id) => id.length > 8 ? '${id.substring(0, 8)}...' : id;

int _reportPriority(AdminReportItem item) {
  var score = 0;
  if (item.slaBreached) score += 70;
  if (item.ageHours >= 48) score += 25;
  if (item.reason.toLowerCase().contains('spam')) score += 20;
  if ((item.reporterId ?? '').isEmpty) score += 10;
  return score;
}

WidgetStateProperty<Color?> _rowColor(bool active, bool slaBreached) =>
    appAdminRowColor(active: active, slaBreached: slaBreached);

String _reportStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status) {
    case 'acik':
      return l10n.adminReportsStatusOpen;
    case 'inceleniyor':
      return l10n.adminReportsStatusInvestigating;
    case 'kapandi':
      return l10n.adminReportsStatusClosed;
    case 'reddedildi':
      return l10n.rejected;
    default:
      return status;
  }
}

String _assignedLabel(BuildContext context, String? assignedTo, String? userId) {
  final l10n = context.l10n;
  if (assignedTo == null || assignedTo.isEmpty) {
    return l10n.adminCommonUnassigned;
  }
  if (userId != null && assignedTo == userId) return l10n.adminCommonMine;
  return l10n.adminCommonOtherAdmin;
}

String _fmtHours(BuildContext context, double v) {
  return context.l10n.adminReportsHoursValue(v.toStringAsFixed(1));
}

List<String> _reportDecisionTemplates(BuildContext context) {
  final l10n = context.l10n;
  return <String>[
    l10n.adminReportsDecisionTemplateViolationConfirmed,
    l10n.adminReportsDecisionTemplateInsufficientEvidence,
    l10n.adminReportsDecisionTemplateNeedsMoreInfo,
  ];
}

Future<void> _openReportedMenuPhoto(
  BuildContext context,
  WidgetRef ref,
  String photoId,
) async {
  final l10n = context.l10n;
  try {
    final res = await ref
        .read(supabaseProvider)
        .from('menu_item_photos')
        .select('url,url_large,url_thumb')
        .eq('id', photoId)
        .maybeSingle();
    if (res == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adminReportsPhotoNotFound)));
      }
      return;
    }
    final map = res.cast<String, dynamic>();
    final url = (map['url_large'] ?? map['url_thumb'] ?? map['url'] ?? '')
        .toString();
    if (url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adminReportsPhotoNotFound)));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(
                url: url,
                variant: AppImageVariant.medium,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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

String _queueRouteForReports({
  required String query,
  required String status,
}) {
  final mappedStatus = switch (status) {
    'acik' => 'open',
    'inceleniyor' => 'reviewing',
    'kapandi' => 'closed',
    'reddedildi' => 'rejected',
    _ => '',
  };
  final queryParameters = <String, String>{
    'type': 'report',
  };
  if (query.trim().isNotEmpty) {
    queryParameters['q'] = query.trim();
  }
  if (mappedStatus.isNotEmpty) {
    queryParameters['status'] = mappedStatus;
  }
  return Uri(path: '/admin/queue', queryParameters: queryParameters).toString();
}

Future<void> _openReportedBusinessMedia(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  final l10n = context.l10n;
  try {
    final res = await ref
        .read(supabaseProvider)
        .from('business_media')
        .select('url,url_large,url_thumb')
        .eq('id', mediaId)
        .maybeSingle();
    if (res == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adminReportsPhotoNotFound)));
      }
      return;
    }
    final map = res.cast<String, dynamic>();
    final url = (map['url_large'] ?? map['url_thumb'] ?? map['url'] ?? '')
        .toString();
    if (url.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.adminReportsPhotoNotFound)));
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(
                url: url,
                variant: AppImageVariant.medium,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }
}

Future<bool?> _fetchMenuPhotoShadow(WidgetRef ref, String photoId) async {
  final res = await ref
      .read(supabaseProvider)
      .from('menu_item_photos')
      .select('is_shadow')
      .eq('id', photoId)
      .maybeSingle();
  if (res == null) return null;
  return (res['is_shadow'] ?? false) == true;
}

Future<bool?> _fetchBusinessMediaShadow(WidgetRef ref, String mediaId) async {
  final res = await ref
      .read(supabaseProvider)
      .from('business_media')
      .select('is_shadow')
      .eq('id', mediaId)
      .maybeSingle();
  if (res == null) return null;
  return (res['is_shadow'] ?? false) == true;
}

class _ShadowInfo extends StatelessWidget {
  const _ShadowInfo({required this.label, required this.future});

  final String label;
  final Future<bool?> future;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<bool?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(l10n.adminReportsVisibilityLoading(label));
        }
        final value = snapshot.data;
        if (value == null) {
          return Text(l10n.adminReportsVisibilityUnknown(label));
        }
        return Text(
          value
              ? l10n.adminReportsVisibilityHidden(label)
              : l10n.adminReportsVisibilityNormal(label),
        );
      },
    );
  }
}
