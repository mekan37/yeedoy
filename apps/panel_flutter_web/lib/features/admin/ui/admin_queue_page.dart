import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/admin_table_saved_views_prefs.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_audit_repository.dart';
import '../data/admin_business_submissions_repository.dart';
import '../data/admin_claims_repository.dart';
import '../data/admin_price_suggestions_repository.dart';
import '../data/admin_queue_repository.dart';
import '../domain/admin_queue_explainer.dart';
import '../domain/admin_queue_models.dart';
import 'web_download.dart';
import 'widgets/admin_table.dart';

part 'parts/queue_detail_panel.dart';
part 'parts/queue_cards.dart';
part 'parts/queue_widgets.dart';

final _queueAuditContextProvider = FutureProvider.autoDispose.family<
  AdminQueueAuditContextSummary,
  AdminQueueItem
>((ref, item) async {
  final repo = ref.watch(adminAuditRepositoryProvider);
  final targetType = resolveAdminQueueAuditTargetType(item);
  final businessId = (item.businessId ?? '').trim();
  final targetId = item.id.trim();
  final useBusinessContext = targetType != null && businessId.isNotEmpty;
  final auditItems = await repo.fetchLogs(
    limit: 8,
    targetTypeFilter: useBusinessContext ? targetType : null,
    businessId: useBusinessContext ? businessId : null,
    targetId: useBusinessContext ? null : targetId,
  );
  return summarizeAdminQueueAuditContext(item, auditItems);
});

class AdminQueuePage extends ConsumerStatefulWidget {
  const AdminQueuePage({
    super.key,
    this.initialType,
    this.initialStatus,
    this.initialCity,
    this.initialQuery,
  });

  final String? initialType;
  final String? initialStatus;
  final String? initialCity;
  final String? initialQuery;

  @override
  ConsumerState<AdminQueuePage> createState() => _AdminQueuePageState();
}

class _AdminQueuePageState extends ConsumerState<AdminQueuePage> {
  static const String _savedViewScope = 'admin_queue';

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  Timer? _debounce;
  bool _loading = true;
  Object? _error;
  List<AdminQueueItem> _items = const [];
  int _totalCount = 0;
  final Set<String> _selectedIds = <String>{};
  String? _selectedDetailId;
  String _typeFilter = '';
  String _statusFilter = '';
  DateTimeRange? _dateRange;
  int _page = 0;
  int _rowsPerPage = 20;
  String _sortKey = 'created_at';
  bool _sortAscending = false;
  List<AdminSavedViewRecord> _savedViews = const [];
  String? _selectedSavedViewId;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _hydrateInitialFilters();
    _load();
    _loadSavedViews();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userId = ref.watch(userProvider)?.id;
    if (_loading && _items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: OwnerPanelFeedback.loading(cardCount: 6),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.error(
          title: l10n.adminQueueErrorTitle,
          description: AppErrorMapper.message(_error),
          onRetry: _load,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 1320;
        final detailItem = _selectedItem;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelPageHeader(
                padding: EdgeInsets.zero,
                title: Text(l10n.adminQueueTitle),
                description: l10n.adminQueueDescription,
              ),
              const SizedBox(height: 12),
              AdminTableFilterBar(
                searchController: _searchCtrl,
                searchHint: l10n.adminQueueSearchHint,
                statusValue: _statusFilter,
                statusOptions: _statusOptions(l10n),
                onSearchChanged: (_) => _scheduleReload(),
                onStatusChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                    _page = 0;
                    _selectedSavedViewId = null;
                  });
                  _load();
                },
                dateRange: _dateRange,
                onPickDateRange: _pickDateRange,
                onClearDateRange: () {
                  setState(() {
                    _dateRange = null;
                    _page = 0;
                    _selectedSavedViewId = null;
                  });
                  _load();
                },
                savedViews: _savedViews,
                selectedSavedViewId: _selectedSavedViewId,
                onSavedViewSelected: _applySavedView,
                onSaveCurrentView: _saveCurrentView,
                onDeleteSavedView: _deleteSavedView,
                trailing: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exporting ? null : _exportCsv,
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: Text(l10n.adminQueueExportCsvAction),
                    ),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.yenile),
                    ),
                  ],
                ),
                extraFilters: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_typeFilter),
                      initialValue: _typeFilter,
                      decoration: InputDecoration(
                        labelText: l10n.adminQueueTypeLabel,
                      ),
                      items: _typeOptions(l10n)
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _typeFilter = value ?? '';
                          _page = 0;
                          _selectedSavedViewId = null;
                        });
                        _load();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _cityCtrl,
                      onChanged: (_) => _scheduleReload(),
                      decoration: InputDecoration(
                        labelText: l10n.city,
                        hintText: l10n.adminQueueCityHint,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdminTableBulkBar(
                selectedCount: _selectedIds.length,
                onClear: () => setState(() => _selectedIds.clear()),
                actions: [
                  AdminTableBulkAction(
                    label: l10n.adminTableAssignToMeAction,
                    icon: Icons.assignment_ind_outlined,
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => _bulkAssign(assignToMe: true),
                  ),
                  AdminTableBulkAction(
                    label: l10n.adminQueueUnassignSelectedAction,
                    icon: Icons.assignment_late_outlined,
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => _bulkAssign(assignToMe: false),
                  ),
                  AdminTableBulkAction(
                    label: l10n.adminTableApproveSelectedAction,
                    icon: Icons.check_circle_outline,
                    onPressed: !_hasApprovableSelection
                        ? null
                        : _bulkApproveSelected,
                    primary: true,
                  ),
                  AdminTableBulkAction(
                    label: l10n.adminTableRejectSelectedAction,
                    icon: Icons.cancel_outlined,
                    onPressed: !_hasRejectableSelection
                        ? null
                        : _bulkRejectSelected,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: AdminTableCard(
                              emptyLabel: l10n.adminQueueEmptyDescription,
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columns: _buildColumns(context),
                              rows: _buildRows(context, wideLayout, userId),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdminTablePaginationBar(
                            page: _page,
                            rowsPerPage: _rowsPerPage,
                            totalCount: _totalCount,
                            onPageChanged: (value) {
                              setState(() => _page = value);
                              _load();
                            },
                            onRowsPerPageChanged: (value) {
                              setState(() {
                                _rowsPerPage = value;
                                _page = 0;
                                _selectedSavedViewId = null;
                              });
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (wideLayout && detailItem != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 380,
                        child: _QueueDetailPanel(
                          item: detailItem,
                          userId: userId,
                          onClose: () => setState(() => _selectedDetailId = null),
                          onOpenSource: () => _goToSource(detailItem),
                          onToggleAssignment: () => _toggleAssignment(detailItem),
                          onApprove: detailItem.canApprove
                              ? () => _approveItem(detailItem)
                              : null,
                          onReject: detailItem.canReject
                              ? () => _rejectItem(detailItem)
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _hydrateInitialFilters() {
    _typeFilter = _safeFilterValue(widget.initialType);
    _statusFilter = _safeFilterValue(widget.initialStatus);
    _searchCtrl.text = (widget.initialQuery ?? '').trim();
    _cityCtrl.text = (widget.initialCity ?? '').trim();
  }

  AdminQueueItem? get _selectedItem {
    final id = _selectedDetailId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool get _allPageSelected =>
      _items.isNotEmpty && _items.every((item) => _selectedIds.contains(item.id));

  bool get _hasApprovableSelection => _selectedItems.any((item) => item.canApprove);

  bool get _hasRejectableSelection => _selectedItems.any((item) => item.canReject);

  List<AdminQueueItem> get _selectedItems {
    return _items.where((item) => _selectedIds.contains(item.id)).toList();
  }

  int? get _sortColumnIndex => switch (_sortKey) {
    'item_type' => 1,
    'title' => 2,
    'city' => 3,
    'status' => 4,
    'created_at' => 6,
    'age_hours' => 7,
    _ => null,
  };

  List<DataColumn> _buildColumns(BuildContext context) {
    final l10n = context.l10n;
    return [
      DataColumn(
        label: Checkbox(
          value: _allPageSelected,
          onChanged: (value) {
            setState(() {
              for (final item in _items) {
                if (value == true) {
                  _selectedIds.add(item.id);
                } else {
                  _selectedIds.remove(item.id);
                }
              }
            });
          },
        ),
      ),
      DataColumn(
        label: Text(l10n.adminQueueColumnType),
        onSort: (_, ascending) => _changeSort('item_type', ascending),
      ),
      DataColumn(
        label: Text(l10n.adminQueueColumnTitle),
        onSort: (_, ascending) => _changeSort('title', ascending),
      ),
      DataColumn(
        label: Text(l10n.city),
        onSort: (_, ascending) => _changeSort('city', ascending),
      ),
      DataColumn(
        label: Text(l10n.adminTableStatusLabel),
        onSort: (_, ascending) => _changeSort('status', ascending),
      ),
      DataColumn(label: Text(l10n.adminCommonAssigned)),
      DataColumn(
        label: Text(l10n.adminQueueColumnCreatedAt),
        onSort: (_, ascending) => _changeSort('created_at', ascending),
      ),
      DataColumn(
        label: Text(l10n.sla),
        onSort: (_, ascending) => _changeSort('age_hours', ascending),
      ),
      DataColumn(label: Text(l10n.adminCommonActionsLabel)),
    ];
  }

  List<DataRow> _buildRows(
    BuildContext context,
    bool wideLayout,
    String? userId,
  ) {
    final l10n = context.l10n;
    return [
      for (final item in _items)
        DataRow(
          selected: _selectedIds.contains(item.id),
          onSelectChanged: (_) => _openDetails(item, wideLayout),
          cells: [
            DataCell(
              Checkbox(
                value: _selectedIds.contains(item.id),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(item.id);
                    } else {
                      _selectedIds.remove(item.id);
                    }
                  });
                },
              ),
            ),
            DataCell(Text(_typeLabel(context, item.type))),
            DataCell(
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (item.subtitle.trim().isNotEmpty)
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            DataCell(
              Text(
                _cityValue(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(_StatusPill(label: _statusLabel(context, item.status))),
            DataCell(Text(_assignedLabel(context, item.assignedTo, userId))),
            DataCell(Text(_fmtDateTime(item.createdAt))),
            DataCell(
              _SlaBadge(
                label: _slaLabel(context, item),
                breached: item.slaBreached,
              ),
            ),
            DataCell(
              Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: item.assignedTo == null
                        ? l10n.adminQueueAssignToMeAction
                        : l10n.adminQueueUnassignAction,
                    onPressed: () => _toggleAssignment(item),
                    icon: Icon(
                      item.assignedTo == null
                          ? Icons.assignment_ind_outlined
                          : Icons.assignment_late_outlined,
                    ),
                  ),
                  if (item.canApprove)
                    IconButton(
                      tooltip: l10n.approved,
                      onPressed: () => _approveItem(item),
                      icon: const Icon(Icons.check_circle_outline),
                    ),
                  if (item.canReject)
                    IconButton(
                      tooltip: l10n.rejected,
                      onPressed: () => _rejectItem(item),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  IconButton(
                    tooltip: l10n.adminQueueOpenDetailsAction,
                    onPressed: () => _openDetails(item, wideLayout),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
    ];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(adminQueueRepositoryProvider).listQueue(
            type: _typeFilter,
            status: _statusFilter,
            city: _cityCtrl.text.trim(),
            query: _searchCtrl.text.trim(),
            from: _dateRange?.start,
            to: _dateRange == null
                ? null
                : DateTime(
                    _dateRange!.end.year,
                    _dateRange!.end.month,
                    _dateRange!.end.day,
                    23,
                    59,
                    59,
                  ),
            sortKey: _sortKey,
            sortAscending: _sortAscending,
            limit: _rowsPerPage,
            offset: _page * _rowsPerPage,
          );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalCount = result.totalCount;
        _loading = false;
        _selectedIds.removeWhere((id) => !_items.any((item) => item.id == id));
        if (_selectedDetailId != null &&
            !_items.any((item) => item.id == _selectedDetailId)) {
          _selectedDetailId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadSavedViews() async {
    final views = await AdminTableSavedViewsPrefs.read(_savedViewScope);
    if (!mounted) return;
    setState(() => _savedViews = views);
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _page = 0;
        _selectedSavedViewId = null;
      });
      _load();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _dateRange = picked;
      _page = 0;
      _selectedSavedViewId = null;
    });
    _load();
  }

  Future<void> _saveCurrentView() async {
    final label = await promptAdminTableSavedViewLabel(context);
    if (label == null) return;
    await AdminTableSavedViewsPrefs.upsert(
      scope: _savedViewScope,
      label: label,
      payload: {
        'query': _searchCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'type': _typeFilter,
        'status': _statusFilter,
        'date_start': _dateRange?.start.toIso8601String(),
        'date_end': _dateRange?.end.toIso8601String(),
        'sort_key': _sortKey,
        'sort_ascending': _sortAscending,
        'rows_per_page': _rowsPerPage,
      },
    );
    await _loadSavedViews();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.adminTableSavedViewCreated)));
  }

  Future<void> _deleteSavedView(String id) async {
    await AdminTableSavedViewsPrefs.delete(scope: _savedViewScope, id: id);
    await _loadSavedViews();
    if (!mounted) return;
    setState(() => _selectedSavedViewId = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.adminTableSavedViewDeleted)));
  }

  void _applySavedView(String? id) {
    if (id == null) {
      setState(() => _selectedSavedViewId = null);
      return;
    }
    AdminSavedViewRecord? view;
    for (final item in _savedViews) {
      if (item.id == id) {
        view = item;
        break;
      }
    }
    if (view == null) return;
    final payload = view.payload;
    _searchCtrl.text = (payload['query'] ?? '').toString();
    _cityCtrl.text = (payload['city'] ?? '').toString();
    final start = DateTime.tryParse((payload['date_start'] ?? '').toString());
    final end = DateTime.tryParse((payload['date_end'] ?? '').toString());
    setState(() {
      _selectedSavedViewId = id;
      _typeFilter = (payload['type'] ?? '').toString();
      _statusFilter = (payload['status'] ?? '').toString();
      _dateRange = start == null || end == null
          ? null
          : DateTimeRange(start: start, end: end);
      _sortKey = (payload['sort_key'] ?? 'created_at').toString();
      _sortAscending = payload['sort_ascending'] == true;
      _rowsPerPage =
          int.tryParse((payload['rows_per_page'] ?? '20').toString()) ?? 20;
      _page = 0;
    });
    _load();
  }

  void _changeSort(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAscending = ascending;
      _page = 0;
      _selectedSavedViewId = null;
    });
    _load();
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final exportCount = _totalCount > 0 ? _totalCount : _rowsPerPage;
      final result = await ref.read(adminQueueRepositoryProvider).listQueue(
            type: _typeFilter,
            status: _statusFilter,
            city: _cityCtrl.text.trim(),
            query: _searchCtrl.text.trim(),
            from: _dateRange?.start,
            to: _dateRange == null
                ? null
                : DateTime(
                    _dateRange!.end.year,
                    _dateRange!.end.month,
                    _dateRange!.end.day,
                    23,
                    59,
                    59,
                  ),
            sortKey: _sortKey,
            sortAscending: _sortAscending,
            limit: exportCount,
            offset: 0,
          );
      if (!mounted) return;
      downloadCsv(
        'admin_queue_${_stamp()}.csv',
        _buildQueueCsv(context.l10n, result.items),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.adminQueueExportReady(result.items.length),
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
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _toggleAssignment(AdminQueueItem item) async {
    try {
      await ref.read(adminQueueRepositoryProvider).setAssignment(
            type: item.type,
            itemId: item.id,
            assignToMe: item.assignedTo == null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.assignedTo == null
                ? context.l10n.adminQueueAssignedToMe
                : context.l10n.adminQueueUnassigned,
          ),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _bulkAssign({required bool assignToMe}) async {
    var applied = 0;
    for (final item in _selectedItems) {
      try {
        await ref.read(adminQueueRepositoryProvider).setAssignment(
              type: item.type,
              itemId: item.id,
              assignToMe: assignToMe,
            );
        applied++;
      } catch (_) {
        // Continue with remaining rows.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminQueueBulkAssignmentResult(applied, _selectedIds.length),
        ),
      ),
    );
    _load();
  }

  Future<void> _approveItem(AdminQueueItem item) async {
    try {
      await _runApprove(item);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.approved)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _rejectItem(AdminQueueItem item) async {
    final note = await _promptRejectNote(
      requiredNote: item.type == AdminQueueItemType.priceSuggestion,
    );
    if (!mounted || note == null) return;
    try {
      await _runReject(item, note);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.rejected)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    }
  }

  Future<void> _bulkApproveSelected() async {
    var applied = 0;
    var skipped = 0;
    for (final item in _selectedItems) {
      if (!item.canApprove) {
        skipped++;
        continue;
      }
      try {
        await _runApprove(item);
        applied++;
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminQueueBulkDecisionResult(applied, skipped),
        ),
      ),
    );
    _load();
  }

  Future<void> _bulkRejectSelected() async {
    final requireNote = _selectedItems.any(
      (item) => item.type == AdminQueueItemType.priceSuggestion && item.canReject,
    );
    final note = await _promptRejectNote(requiredNote: requireNote);
    if (!mounted || note == null) return;
    var applied = 0;
    var skipped = 0;
    for (final item in _selectedItems) {
      if (!item.canReject) {
        skipped++;
        continue;
      }
      try {
        await _runReject(item, note);
        applied++;
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminQueueBulkDecisionResult(applied, skipped),
        ),
      ),
    );
    _load();
  }

  Future<void> _runApprove(AdminQueueItem item) async {
    switch (item.type) {
      case AdminQueueItemType.businessSubmission:
        await ref
            .read(adminBusinessSubmissionsRepositoryProvider)
            .approve(item.id);
        return;
      case AdminQueueItemType.claim:
        await ref.read(adminClaimsRepositoryProvider).decideClaim(
              claimId: item.id,
              decision: 'approved',
            );
        return;
      case AdminQueueItemType.priceSuggestion:
        await ref.read(adminPriceSuggestionsRepositoryProvider).approve(item.id);
        return;
      case AdminQueueItemType.report:
      case AdminQueueItemType.mediaFlag:
        throw Exception('unsupported_queue_approve');
    }
  }

  Future<void> _runReject(AdminQueueItem item, String note) async {
    switch (item.type) {
      case AdminQueueItemType.businessSubmission:
        await ref
            .read(adminBusinessSubmissionsRepositoryProvider)
            .reject(item.id, note: note);
        return;
      case AdminQueueItemType.claim:
        await ref.read(adminClaimsRepositoryProvider).decideClaim(
              claimId: item.id,
              decision: 'rejected',
              note: note,
            );
        return;
      case AdminQueueItemType.priceSuggestion:
        await ref.read(adminPriceSuggestionsRepositoryProvider).reject(
              suggestionId: item.id,
              note: note,
            );
        return;
      case AdminQueueItemType.report:
      case AdminQueueItemType.mediaFlag:
        throw Exception('unsupported_queue_reject');
    }
  }

  Future<String?> _promptRejectNote({required bool requiredNote}) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.adminQueueRejectDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: ctx.l10n.adminQueueRejectDialogLabel,
            hintText: requiredNote
                ? ctx.l10n.adminQueueRejectDialogRequiredHint
                : ctx.l10n.adminQueueRejectDialogOptionalHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (requiredNote && text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: Text(ctx.l10n.rejected),
          ),
        ],
      ),
    );
    controller.dispose();
    if (requiredNote && (result ?? '').trim().isEmpty) return null;
    return result;
  }

  void _openDetails(AdminQueueItem item, bool wideLayout) {
    if (wideLayout) {
      setState(() => _selectedDetailId = item.id);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: _QueueDetailPanel(
            item: item,
            userId: ref.read(userProvider)?.id,
            onClose: () => Navigator.pop(ctx),
            onOpenSource: () {
              Navigator.pop(ctx);
              _goToSource(item);
            },
            onToggleAssignment: () async {
              Navigator.pop(ctx);
              await _toggleAssignment(item);
            },
            onApprove: item.canApprove
                ? () async {
                    Navigator.pop(ctx);
                    await _approveItem(item);
                  }
                : null,
            onReject: item.canReject
                ? () async {
                    Navigator.pop(ctx);
                    await _rejectItem(item);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  void _goToSource(AdminQueueItem item) {
    switch (item.type) {
      case AdminQueueItemType.businessSubmission:
        context.go('/admin/business-submissions');
        return;
      case AdminQueueItemType.report:
      case AdminQueueItemType.mediaFlag:
        context.go('/admin/reports');
        return;
      case AdminQueueItemType.priceSuggestion:
        context.go('/admin/price-suggestions');
        return;
      case AdminQueueItemType.claim:
        context.go('/admin/claims');
        return;
    }
  }
}
