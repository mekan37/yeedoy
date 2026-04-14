import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/admin_table_saved_views_prefs.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../data/admin_business_submissions_repository.dart';
import '../domain/admin_business_submission.dart';
import 'widgets/admin_table.dart';

class AdminBusinessSubmissionsPage extends ConsumerStatefulWidget {
  const AdminBusinessSubmissionsPage({super.key});

  @override
  ConsumerState<AdminBusinessSubmissionsPage> createState() =>
      _AdminBusinessSubmissionsPageState();
}

class _AdminBusinessSubmissionsPageState
    extends ConsumerState<AdminBusinessSubmissionsPage> {
  static const _savedViewScope = 'admin_business_submissions';

  static const _columns = <AdminVirtualTableColumn>[
    AdminVirtualTableColumn(width: 56, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 260, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 180, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 180, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 180, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 180, label: SizedBox.shrink()),
  ];

  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _statusFilter = '';
  bool _loading = true;
  Object? _error;
  List<AdminBusinessSubmission> _items = const [];
  int _totalCount = 0;
  final Set<String> _selectedIds = <String>{};
  DateTimeRange? _dateRange;
  String _sortKey = 'created_at';
  bool _sortAscending = false;
  int _page = 0;
  int _rowsPerPage = 20;
  List<AdminSavedViewRecord> _savedViews = const [];
  String? _selectedSavedViewId;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _loadSavedViews();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminBusinessSubmissionsRepositoryProvider);
      final res = await repo.listSubmissions(
        status: _statusFilter.isEmpty ? null : _statusFilter,
        limit: _rowsPerPage,
        offset: _page * _rowsPerPage,
        query: _searchCtrl.text.trim(),
        dateFrom: _dateRange?.start,
        dateTo: _dateRange == null
            ? null
            : DateTime(
                _dateRange!.end.year,
                _dateRange!.end.month,
                _dateRange!.end.day,
                23,
                59,
                59,
                999,
              ),
        sortKey: _sortKey,
        sortAscending: _sortAscending,
      );
      if (!mounted) return;
      setState(() {
        _items = res;
        _totalCount = res.isEmpty ? 0 : res.first.totalCount;
        _loading = false;
        _selectedIds.clear();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return const Center(child: OwnerPanelFeedback.loading(cardCount: 4));
    }
    if (_error != null) {
      return Center(
        child: OwnerPanelFeedback.error(
          title: l10n.adminShellBusinessSubmissionsLabel,
          description: AppErrorMapper.message(_error),
          onRetry: _loadPage,
        ),
      );
    }

    final allPageSelected =
        _items.isNotEmpty &&
        _items.every((item) => _selectedIds.contains(item.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminShellBusinessSubmissionsLabel),
            description: l10n.adminShellBusinessSubmissionsDescription,
            actions: [
              OutlinedButton.icon(
                onPressed: _loadPage,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminTableFilterBar(
            searchController: _searchCtrl,
            searchHint: l10n.adminBusinessSubmissionsSearchHint,
            statusValue: _statusFilter,
            statusOptions: [
              AdminTableStatusOption(value: '', label: l10n.tumu),
              AdminTableStatusOption(
                value: 'new',
                label: l10n.adminBusinessSubmissionsNewStatus,
              ),
              AdminTableStatusOption(value: 'approved', label: l10n.approved),
              AdminTableStatusOption(value: 'rejected', label: l10n.rejected),
            ],
            onSearchChanged: (_) => _onSearchChanged(),
            onStatusChanged: (value) {
              setState(() {
                _statusFilter = value;
                _selectedSavedViewId = null;
                _page = 0;
              });
              _loadPage();
            },
            dateRange: _dateRange,
            onPickDateRange: _pickDateRange,
            onClearDateRange: () {
              setState(() {
                _dateRange = null;
                _page = 0;
                _selectedSavedViewId = null;
              });
              _loadPage();
            },
            savedViews: _savedViews,
            selectedSavedViewId: _selectedSavedViewId,
            onSavedViewSelected: _applySavedView,
            onSaveCurrentView: _saveCurrentView,
            onDeleteSavedView: _deleteSavedView,
          ),
          const SizedBox(height: 12),
          AdminTableBulkBar(
            selectedCount: _selectedIds.length,
            onClear: () => setState(() => _selectedIds.clear()),
            actions: [
              AdminTableBulkAction(
                label: l10n.adminTableApproveSelectedAction,
                icon: Icons.check_circle_outline,
                onPressed: _selectedIds.isEmpty ? null : _approveSelected,
                primary: true,
              ),
              AdminTableBulkAction(
                label: l10n.adminTableRejectSelectedAction,
                icon: Icons.cancel_outlined,
                onPressed: _selectedIds.isEmpty ? null : _rejectSelected,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: AdminVirtualTableCard(
                    emptyLabel: l10n.adminBusinessSubmissionsEmpty,
                    columns: [
                      AdminVirtualTableColumn(
                        width: 56,
                        label: Checkbox(
                          value: allPageSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                for (final item in _items) {
                                  _selectedIds.add(item.id);
                                }
                              } else {
                                for (final item in _items) {
                                  _selectedIds.remove(item.id);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 260,
                        label: _HeaderSortLabel(
                          label: l10n.adminBusinessSubmissionsBusinessColumn,
                          active: _sortKey == 'name',
                          ascending: _sortAscending,
                          onTap: () => _sortBy(
                            'name',
                            _sortKey == 'name' ? !_sortAscending : true,
                          ),
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 140,
                        label: _HeaderSortLabel(
                          label: l10n.adminCommonStatusLabel,
                          active: _sortKey == 'status',
                          ascending: _sortAscending,
                          onTap: () => _sortBy(
                            'status',
                            _sortKey == 'status' ? !_sortAscending : true,
                          ),
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 180,
                        label: _HeaderSortLabel(
                          label: l10n.adminBusinessSubmissionsCategoryColumn,
                          active: _sortKey == 'category',
                          ascending: _sortAscending,
                          onTap: () => _sortBy(
                            'category',
                            _sortKey == 'category' ? !_sortAscending : true,
                          ),
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 180,
                        label: _HeaderSortLabel(
                          label: l10n.adminBusinessSubmissionsApplicantColumn,
                          active: _sortKey == 'submitted_by',
                          ascending: _sortAscending,
                          onTap: () => _sortBy(
                            'submitted_by',
                            _sortKey == 'submitted_by'
                                ? !_sortAscending
                                : true,
                          ),
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 180,
                        label: Text(l10n.adminCommonLocationLabel),
                      ),
                      AdminVirtualTableColumn(
                        width: 140,
                        label: _HeaderSortLabel(
                          label: l10n.adminReportsCreatedAtColumn,
                          active: _sortKey == 'created_at',
                          ascending: _sortAscending,
                          onTap: () => _sortBy(
                            'created_at',
                            _sortKey == 'created_at'
                                ? !_sortAscending
                                : false,
                          ),
                        ),
                      ),
                      AdminVirtualTableColumn(
                        width: 180,
                        label: Text(l10n.adminCommonActionsLabel),
                      ),
                    ],
                    rowCount: _items.length,
                    rowBuilder: (context, index) {
                      final item = _items[index];
                      return AdminVirtualTableRowView(
                        columns: _columns,
                        row: AdminVirtualTableRow(
                          key: ValueKey(item.id),
                          selected: _selectedIds.contains(item.id),
                          cells: [
                            Checkbox(
                              value: _selectedIds.contains(item.id),
                              onChanged: (value) => setState(() {
                                if (value ?? false) {
                                  _selectedIds.add(item.id);
                                } else {
                                  _selectedIds.remove(item.id);
                                }
                              }),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  item.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            _StatusPill(
                              rawStatus: item.status,
                              label: _submissionStatusLabel(l10n, item.status),
                            ),
                            Text(item.category),
                            Text(item.submittedBy),
                            Text('${item.district}, ${item.city}'),
                            Text(_fmtDate(item.createdAt)),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: item.status == 'new'
                                      ? () => _approve(item)
                                      : null,
                                  child: Text(l10n.approved),
                                ),
                                TextButton(
                                  onPressed: item.status == 'new'
                                      ? () => _reject(item)
                                      : null,
                                  child: Text(l10n.rejected),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                AdminTablePaginationBar(
                  page: _page,
                  rowsPerPage: _rowsPerPage,
                  totalCount: _totalCount,
                  onPageChanged: (value) {
                    setState(() => _page = value);
                    _loadPage();
                  },
                  onRowsPerPageChanged: (value) {
                    setState(() {
                      _rowsPerPage = value;
                      _page = 0;
                    });
                    _loadPage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sortBy(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAscending = ascending;
      _page = 0;
      _selectedSavedViewId = null;
    });
    _loadPage();
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
    _loadPage();
  }

  Future<void> _saveCurrentView() async {
    final label = await promptAdminTableSavedViewLabel(context);
    if (label == null) return;
    await AdminTableSavedViewsPrefs.upsert(
      scope: _savedViewScope,
      label: label,
      payload: {
        'query': _searchCtrl.text.trim(),
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

  void _applySavedView(String? id) {
    if (id == null) {
      setState(() => _selectedSavedViewId = null);
      return;
    }
    final savedView = _savedViews.where((item) => item.id == id).firstOrNull;
    if (savedView == null) return;
    final payload = savedView.payload;
    _searchCtrl.text = (payload['query'] ?? '').toString();
    setState(() {
      _selectedSavedViewId = id;
      _statusFilter = (payload['status'] ?? '').toString();
      _sortKey = (payload['sort_key'] ?? 'created_at').toString();
      _sortAscending = payload['sort_ascending'] == true;
      _rowsPerPage =
          int.tryParse((payload['rows_per_page'] ?? '20').toString()) ?? 20;
      final start = DateTime.tryParse((payload['date_start'] ?? '').toString());
      final end = DateTime.tryParse((payload['date_end'] ?? '').toString());
      _dateRange = start == null || end == null
          ? null
          : DateTimeRange(start: start, end: end);
      _page = 0;
    });
    _loadPage();
  }

  Future<void> _approve(AdminBusinessSubmission item) async {
    final ok = await _confirm(
      context,
      context.l10n.adminBusinessSubmissionsApproveConfirm,
    );
    if (!ok) return;
    try {
      await ref.read(adminBusinessSubmissionsRepositoryProvider).approve(item.id);
      if (mounted) _loadPage();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _reject(AdminBusinessSubmission item) async {
    final note = await _promptRejectNote();
    if (note == null) return;
    try {
      await ref
          .read(adminBusinessSubmissionsRepositoryProvider)
          .reject(item.id, note: note);
      if (mounted) _loadPage();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _approveSelected() async {
    final ok = await _confirm(
      context,
      context.l10n.adminBusinessSubmissionsApproveConfirm,
    );
    if (!ok) return;
    try {
      final repo = ref.read(adminBusinessSubmissionsRepositoryProvider);
      for (final id in _selectedIds.toList()) {
        await repo.approve(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminTableApproveSelectedAction)),
      );
      _loadPage();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _rejectSelected() async {
    final note = await _promptRejectNote();
    if (note == null) return;
    try {
      final repo = ref.read(adminBusinessSubmissionsRepositoryProvider);
      for (final id in _selectedIds.toList()) {
        await repo.reject(id, note: note);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminTableRejectSelectedAction)),
      );
      _loadPage();
    } catch (e) {
      _showError(e);
    }
  }

  Future<String?> _promptRejectNote() async {
    final noteCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.adminAppealRejectAction),
        content: TextField(
          controller: noteCtrl,
          decoration: InputDecoration(
            labelText: ctx.l10n.adminBusinessSubmissionsOptionalNoteLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            child: Text(ctx.l10n.adminAppealRejectAction),
          ),
        ],
      ),
    );
    noteCtrl.dispose();
    return result;
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
  }

  void _onSearchChanged() {
    setState(() {
      _page = 0;
      _selectedSavedViewId = null;
    });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadPage);
  }
}

class _HeaderSortLabel extends StatelessWidget {
  const _HeaderSortLabel({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 4),
          Icon(
            active
                ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.rawStatus,
    required this.label,
  });

  final String rawStatus;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (rawStatus.toLowerCase()) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.ownerAreYouSure),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.ownerConfirm),
        ),
      ],
    ),
  );
  return res ?? false;
}

String _submissionStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'new' => l10n.adminBusinessSubmissionsNewStatus,
      'approved' => l10n.approved,
      'rejected' => l10n.rejected,
      _ => status,
    };

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
