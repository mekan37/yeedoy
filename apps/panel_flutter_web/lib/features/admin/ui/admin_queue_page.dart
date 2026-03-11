import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/admin_table_saved_views_prefs.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
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
              Text(
                l10n.adminQueueTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.adminQueueDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
