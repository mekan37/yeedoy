import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/media/media_upload_repository.dart';
import '../../../core/navigation/public_menu_url.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/admin_table_saved_views_prefs.dart';
import '../../../core/web/web_utils.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/components/permission_denied_view.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/admin_businesses_repository.dart';
import '../data/admin_monetization_repository.dart';
import '../domain/admin_businesses_controller.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_table.dart';

const _businessStatusVerified = 'verified';
const _businessStatusAssigned = 'assigned';
const _businessStatusNeedsReview = 'needs_review';
const _businessStatusUnassigned = 'unassigned';

class AdminBusinessesPage extends ConsumerStatefulWidget {
  const AdminBusinessesPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<AdminBusinessesPage> createState() =>
      _AdminBusinessesPageState();
}

class _AdminBusinessesPageState extends ConsumerState<AdminBusinessesPage> {
  static const _savedViewScope = 'admin_businesses';
  static const _columns = <AdminVirtualTableColumn>[
    AdminVirtualTableColumn(width: 56, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 56, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 240, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 160, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 150, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 120, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 140, label: SizedBox.shrink()),
    AdminVirtualTableColumn(width: 360, label: SizedBox.shrink()),
  ];

  final searchCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  final Map<String, BusinessRiskSignal> _riskById = {};
  String _riskKey = '';
  bool _riskLoading = false;
  String _statusFilter = '';
  DateTimeRange? _dateRange;
  String _sortKey = 'createdAt';
  bool _sortAscending = false;
  int _page = 0;
  int _rowsPerPage = 20;
  String _bulkStatus = '';
  List<AdminSavedViewRecord> _savedViews = const [];
  String? _selectedSavedViewId;

  @override
  void initState() {
    super.initState();
    _hydrateInitialQuery();
    _loadSavedViews();
  }

  @override
  void didUpdateWidget(covariant AdminBusinessesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialQuery ?? '').trim() !=
        (oldWidget.initialQuery ?? '').trim()) {
      _hydrateInitialQuery();
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    cityCtrl.dispose();
    districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedViews() async {
    final views = await AdminTableSavedViewsPrefs.read(_savedViewScope);
    if (!mounted) return;
    setState(() => _savedViews = views);
  }

  void _hydrateInitialQuery() {
    final query = (widget.initialQuery ?? '').trim();
    searchCtrl.text = query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(adminBusinessesControllerProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(adminBusinessesControllerProvider);
    final controller = ref.read(adminBusinessesControllerProvider.notifier);
    final user = ref.watch(userProvider);
    final l10n = context.l10n;
    final nextRiskKey = st.items.map((e) => e.id).join(',');
    if (nextRiskKey != _riskKey && st.items.isNotEmpty) {
      _riskKey = nextRiskKey;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshRiskSignals(st.items),
      );
    }

    final filteredItems = _filterAndSortBusinesses(st.items);
    final estimatedTotalCount =
        filteredItems.length + (st.hasMore ? _rowsPerPage : 0);
    final pageCount = estimatedTotalCount == 0
        ? 1
        : ((estimatedTotalCount - 1) ~/ _rowsPerPage) + 1;
    final safePage = _page.clamp(0, pageCount - 1).toInt();
    final start = safePage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filteredItems.length);
    final pageItems = filteredItems.sublist(start, end);
    final allPageSelected =
        pageItems.isNotEmpty &&
        pageItems.every((item) => _selectedIds.contains(item.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelPageHeader(
            padding: EdgeInsets.zero,
            title: Text(l10n.adminBusinessesTitle),
            description: l10n.adminShellBusinessesDescription,
            actions: [
              if (_riskLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _refreshBusinesses(force: true),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminTableFilterBar(
            searchController: searchCtrl,
            searchHint: l10n.adminBusinessesSearchHint,
            statusValue: _statusFilter,
            statusOptions: [
              AdminTableStatusOption(value: '', label: l10n.tumu),
              AdminTableStatusOption(
                value: _businessStatusVerified,
                label: l10n.verified,
              ),
              AdminTableStatusOption(
                value: _businessStatusAssigned,
                label: l10n.adminCommonAssigned,
              ),
              AdminTableStatusOption(
                value: _businessStatusNeedsReview,
                label: l10n.adminBusinessesStatusNeedsReview,
              ),
              AdminTableStatusOption(
                value: _businessStatusUnassigned,
                label: l10n.adminCommonUnassigned,
              ),
            ],
            onSearchChanged: (value) {
              controller.setQuery(value.trim());
              setState(() {
                _page = 0;
                _selectedIds.clear();
                _selectedSavedViewId = null;
              });
            },
            onStatusChanged: (value) {
              setState(() {
                _statusFilter = value;
                _page = 0;
                _selectedIds.clear();
                _selectedSavedViewId = null;
              });
            },
            dateRange: _dateRange,
            onPickDateRange: _pickDateRange,
            onClearDateRange: () {
              setState(() {
                _dateRange = null;
                _page = 0;
                _selectedIds.clear();
                _selectedSavedViewId = null;
              });
            },
            savedViews: _savedViews,
            selectedSavedViewId: _selectedSavedViewId,
            onSavedViewSelected: _applySavedView,
            onSaveCurrentView: _saveCurrentView,
            onDeleteSavedView: _deleteSavedView,
            extraFilters: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: cityCtrl,
                  onChanged: (value) {
                    controller.setCity(value.trim());
                    setState(() {
                      _page = 0;
                      _selectedIds.clear();
                      _selectedSavedViewId = null;
                    });
                  },
                  decoration: InputDecoration(labelText: l10n.city),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: districtCtrl,
                  onChanged: (value) {
                    controller.setDistrict(value.trim());
                    setState(() {
                      _page = 0;
                      _selectedIds.clear();
                      _selectedSavedViewId = null;
                    });
                  },
                  decoration: InputDecoration(labelText: l10n.district),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminTableBulkBar(
            selectedCount: _selectedIds.length,
            onClear: () => setState(() {
              _selectedIds.clear();
              _bulkStatus = '';
            }),
            actions: [
              AdminTableBulkAction(
                label: l10n.adminTableApproveSelectedAction,
                icon: Icons.verified_outlined,
                onPressed: _selectedIds.isEmpty ? null : _approveSelected,
                primary: true,
              ),
              AdminTableBulkAction(
                label: l10n.adminTableRejectSelectedAction,
                icon: Icons.remove_moderator_outlined,
                onPressed: _selectedIds.isEmpty ? null : _rejectSelected,
              ),
              AdminTableBulkAction(
                label: l10n.adminTableAssignToMeAction,
                icon: Icons.assignment_ind_outlined,
                onPressed: _selectedIds.isEmpty || user?.id == null
                    ? null
                    : () => _assignSelectedToMe(user!.id),
              ),
            ],
            child: _selectedIds.isEmpty
                ? null
                : _BusinessBulkStatusBar(
                    value: _bulkStatus,
                    onChanged: (value) => setState(() => _bulkStatus = value),
                    onApply: _bulkStatus.isEmpty
                        ? null
                        : () => _applyBulkStatus(userId: user?.id),
                  ),
          ),
          if (_selectedIds.isNotEmpty) const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (context) {
                if (st.isLoading && st.items.isEmpty) {
                  return const OwnerPanelFeedback.loading(cardCount: 4);
                }
                if (st.error != null && st.items.isEmpty) {
                  return _buildErrorState(context, st.error, user != null);
                }
                if (filteredItems.isEmpty) {
                  return OwnerPanelFeedback.empty(
                    icon: Icons.storefront_outlined,
                    title: l10n.adminBusinessesEmptyTitle,
                    description: l10n.adminBusinessesEmptyDescription,
                    onRetry: () => _refreshBusinesses(force: true),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: AdminVirtualTableCard(
                        emptyLabel: l10n.adminBusinessesEmpty,
                        columns: [
                          AdminVirtualTableColumn(
                            width: 56,
                            label: Checkbox(
                              value: allPageSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value ?? false) {
                                    for (final item in pageItems) {
                                      _selectedIds.add(item.id);
                                    }
                                  } else {
                                    for (final item in pageItems) {
                                      _selectedIds.remove(item.id);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const AdminVirtualTableColumn(
                            width: 56,
                            label: Text(''),
                          ),
                          AdminVirtualTableColumn(
                            width: 240,
                            label: _HeaderSortLabel(
                              label: l10n.adminBusinessesNameColumn,
                              active: _sortKey == 'name',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'name',
                                _sortKey == 'name' ? !_sortAscending : true,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 160,
                            label: _HeaderSortLabel(
                              label: l10n.adminCommonLocationLabel,
                              active: _sortKey == 'location',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'location',
                                _sortKey == 'location'
                                    ? !_sortAscending
                                    : true,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 140,
                            label: _HeaderSortLabel(
                              label: l10n.ownerCategoryLabel,
                              active: _sortKey == 'category',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'category',
                                _sortKey == 'category'
                                    ? !_sortAscending
                                    : true,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 150,
                            label: _HeaderSortLabel(
                              label: l10n.adminCommonStatusLabel,
                              active: _sortKey == 'status',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'status',
                                _sortKey == 'status' ? !_sortAscending : true,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 140,
                            label: _HeaderSortLabel(
                              label: l10n.adminBusinessesRiskColumn,
                              active: _sortKey == 'risk',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'risk',
                                _sortKey == 'risk' ? !_sortAscending : false,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 120,
                            label: _HeaderSortLabel(
                              label: l10n.adminBusinessesCreatedAtColumn,
                              active: _sortKey == 'createdAt',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'createdAt',
                                _sortKey == 'createdAt'
                                    ? !_sortAscending
                                    : false,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 140,
                            label: _HeaderSortLabel(
                              label: l10n.adminBusinessesAssignedColumn,
                              active: _sortKey == 'assigned',
                              ascending: _sortAscending,
                              onTap: () => _sortBusinessesBy(
                                'assigned',
                                _sortKey == 'assigned'
                                    ? !_sortAscending
                                    : true,
                              ),
                            ),
                          ),
                          AdminVirtualTableColumn(
                            width: 360,
                            label: Text(l10n.adminCommonActionsLabel),
                          ),
                        ],
                        rowCount: pageItems.length,
                        rowBuilder: (context, index) => _buildBusinessRow(
                          context: context,
                          item: pageItems[index],
                          currentUserId: user?.id,
                        ),
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
                      onPageChanged: (value) => _changeBusinessesPage(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error, bool hasUser) {
    final l10n = context.l10n;
    if (_looksLikePermissionError(error)) {
      return PermissionDeniedView(
        description: l10n.forbiddenDescriptionWithRoute('/admin/businesses'),
        primaryRoute: hasUser ? '/admin' : '/login',
        primaryLabel: hasUser ? l10n.forbiddenBackHomeAction : l10n.login,
      );
    }
    return OwnerPanelFeedback.error(
      title: l10n.adminBusinessesErrorTitle,
      description: AppErrorMapper.message(error),
      onRetry: () => _refreshBusinesses(force: true),
    );
  }

  Widget _buildBusinessRow({
    required BuildContext context,
    required AdminBusinessItem item,
    required String? currentUserId,
  }) {
    final l10n = context.l10n;
    final risk = _riskById[item.id];
    return AdminVirtualTableRowView(
      columns: _columns,
      row: AdminVirtualTableRow(
        key: ValueKey(item.id),
        selected: _selectedIds.contains(item.id),
        onTap: () {
          setState(() {
            if (_selectedIds.contains(item.id)) {
              _selectedIds.remove(item.id);
            } else {
              _selectedIds.add(item.id);
            }
          });
        },
        cells: [
          Checkbox(
            value: _selectedIds.contains(item.id),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selectedIds.add(item.id);
                } else {
                  _selectedIds.remove(item.id);
                }
              });
            },
          ),
          _logoPreview(item.logoUrl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if ((item.address ?? '').trim().isNotEmpty)
                  Text(
                    item.address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          Text(_locationLabel(item)),
          Text((item.category ?? '-').trim().isEmpty ? '-' : item.category!),
          _BusinessStatusBadge(
            label: _businessStatusLabel(context, item, risk),
            status: _businessStatus(item, risk),
          ),
          _riskCell(context, risk),
          Text(_fmtDate(item.createdAt)),
          Text(_assignedLabel(context, item.assignedTo, currentUserId)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TextButton(
                  onPressed: () => _openDetails(context, item),
                  child: Text(l10n.duzenle),
                ),
                TextButton(
                  onPressed: () => _openMergeFlow(context, item),
                  child: Text(l10n.adminBusinessesMergeAction),
                ),
                TextButton(
                  onPressed: () => _openQrMenu(item),
                  child: Text(l10n.adminBusinessesQrMenuAction),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/trash?businessId=${item.id}'),
                  child: Text(l10n.adminBusinessesTrashAction),
                ),
                TextButton(
                  onPressed: () => _openPublicMenu(item),
                  child: Text(l10n.adminBusinessesPublicMenuAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshBusinesses({bool force = false}) async {
    final ok = await ref
        .read(adminBusinessesControllerProvider.notifier)
        .refresh(force: force);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _selectedIds.clear();
        _bulkStatus = '';
        _page = 0;
      });
    }
  }

  Future<void> _saveCurrentView() async {
    final label = await promptAdminTableSavedViewLabel(context);
    if (label == null) return;
    await AdminTableSavedViewsPrefs.upsert(
      scope: _savedViewScope,
      label: label,
      payload: {
        'query': searchCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'district': districtCtrl.text.trim(),
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

  Future<void> _applySavedView(String? id) async {
    if (id == null) {
      setState(() => _selectedSavedViewId = null);
      return;
    }
    final view = _savedViews.where((item) => item.id == id).firstOrNull;
    if (view == null) return;
    final payload = view.payload;
    final query = (payload['query'] ?? '').toString();
    final city = (payload['city'] ?? '').toString();
    final district = (payload['district'] ?? '').toString();
    searchCtrl.text = query;
    cityCtrl.text = city;
    districtCtrl.text = district;
    setState(() {
      _selectedSavedViewId = id;
      _statusFilter = (payload['status'] ?? '').toString();
      _sortKey = (payload['sort_key'] ?? 'createdAt').toString();
      _sortAscending = payload['sort_ascending'] == true;
      _rowsPerPage =
          int.tryParse((payload['rows_per_page'] ?? '20').toString()) ?? 20;
      final start = DateTime.tryParse((payload['date_start'] ?? '').toString());
      final end = DateTime.tryParse((payload['date_end'] ?? '').toString());
      _dateRange = start == null || end == null
          ? null
          : DateTimeRange(start: start, end: end);
      _page = 0;
      _selectedIds.clear();
      _bulkStatus = '';
    });
    await ref.read(adminBusinessesControllerProvider.notifier).applyFilters(
          query: query,
          city: city,
          district: district,
        );
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

  List<AdminBusinessItem> _filterAndSortBusinesses(
    List<AdminBusinessItem> items,
  ) {
    final filtered = items.where((item) {
      if (!_matchesDateRange(item.createdAt, _dateRange)) return false;
      if (_statusFilter.isEmpty) return true;
      return _businessStatus(item, _riskById[item.id]) == _statusFilter;
    }).toList();

    filtered.sort((a, b) {
      final direction = _sortAscending ? 1 : -1;
      return switch (_sortKey) {
        'name' =>
          direction * a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        'location' => direction *
            _locationLabel(a).toLowerCase().compareTo(
                  _locationLabel(b).toLowerCase(),
                ),
        'category' => direction *
            (a.category ?? '').toLowerCase().compareTo(
                  (b.category ?? '').toLowerCase(),
                ),
        'status' => direction *
            _businessStatusSortValue(a, _riskById[a.id]).compareTo(
              _businessStatusSortValue(b, _riskById[b.id]),
            ),
        'risk' => direction *
            _businessRiskSortValue(_riskById[a.id]).compareTo(
              _businessRiskSortValue(_riskById[b.id]),
            ),
        'assigned' =>
          direction * (a.assignedTo ?? '').compareTo(b.assignedTo ?? ''),
        _ => direction * a.createdAt.compareTo(b.createdAt),
      };
    });
    return filtered;
  }

  void _sortBusinessesBy(String key, bool ascending) {
    setState(() {
      _sortKey = key;
      _sortAscending = ascending;
      _page = 0;
      _selectedSavedViewId = null;
    });
  }

  Future<void> _changeBusinessesPage(
    int value, {
    required AdminBusinessesState state,
    required int filteredCount,
  }) async {
    if (value < 0) return;
    final requiredCount = (value + 1) * _rowsPerPage;
    if (requiredCount > filteredCount && state.hasMore) {
      await ref.read(adminBusinessesControllerProvider.notifier).loadMore();
    }
    if (!mounted) return;
    setState(() => _page = value);
  }

  Future<void> _approveSelected() async {
    final ok = await _confirmAction(
      context.l10n.adminTableApproveSelectedAction,
    );
    if (!ok) return;
    final count = await _setVerificationForSelection(isVerified: true);
    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminBusinessesVerificationUpdatedCount(count),
        ),
      ),
    );
  }

  Future<void> _rejectSelected() async {
    final ok = await _confirmAction(
      context.l10n.adminTableRejectSelectedAction,
    );
    if (!ok) return;
    final count = await _setVerificationForSelection(isVerified: false);
    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminBusinessesVerificationUpdatedCount(count),
        ),
      ),
    );
  }

  Future<void> _assignSelectedToMe(String userId) async {
    final count = await _setAssignmentForSelection(userId);
    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.adminBusinessesAssignedCount(count))),
    );
  }

  Future<void> _applyBulkStatus({required String? userId}) async {
    switch (_bulkStatus) {
      case _businessStatusVerified:
        await _approveSelected();
        break;
      case _businessStatusNeedsReview:
        await _rejectSelected();
        break;
      case _businessStatusUnassigned:
        final count = await _setAssignmentForSelection(null);
        if (!mounted || count == 0) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminBusinessesAssignedCount(count))),
        );
        break;
      case _businessStatusAssigned:
        if (userId == null) return;
        await _assignSelectedToMe(userId);
        break;
    }
  }

  Future<int> _setVerificationForSelection({
    required bool isVerified,
  }) async {
    final items = ref
        .read(adminBusinessesControllerProvider)
        .items
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    if (items.isEmpty) return 0;

    var updated = 0;
    final repo = ref.read(adminMonetizationRepositoryProvider);
    for (final item in items) {
      try {
        await repo.setBusinessVerified(
          businessId: item.id,
          isVerified: isVerified,
          tier: 'verified',
        );
        updated++;
      } catch (e) {
        if (!mounted) return updated;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    }
    await _refreshBusinesses(force: true);
    return updated;
  }

  Future<int> _setAssignmentForSelection(String? userId) async {
    final items = ref
        .read(adminBusinessesControllerProvider)
        .items
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    if (items.isEmpty) return 0;

    var updated = 0;
    final repo = ref.read(adminBusinessesRepositoryProvider);
    for (final item in items) {
      try {
        await repo.setBusinessAssignment(
          businessId: item.id,
          assignedTo: userId,
        );
        updated++;
      } catch (e) {
        if (!mounted) return updated;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    }
    await _refreshBusinesses(force: true);
    return updated;
  }

  Future<bool> _confirmAction(String actionLabel) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerAreYouSure),
        content: Text(actionLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.apply),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openDetails(
    BuildContext context,
    AdminBusinessItem item,
  ) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: item.name);
    final categoryCtrl = TextEditingController(text: item.category ?? '');
    final addressCtrl = TextEditingController(text: item.address ?? '');
    final cityCtrl = TextEditingController(text: item.city ?? '');
    final districtCtrl = TextEditingController(text: item.district ?? '');
    final latCtrl = TextEditingController(text: item.lat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: item.lng?.toString() ?? '');
    final logoCtrl = TextEditingController(text: item.logoUrl ?? '');
    final coverCtrl = TextEditingController(text: item.coverUrl ?? '');
    final mediaUploadRepository = ref.read(mediaUploadRepositoryProvider);

    var logoUrl = item.logoUrl ?? '';
    var coverUrl = item.coverUrl ?? '';
    var saving = false;
    var uploadingLogo = false;
    var uploadingCover = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> save() async {
            setModalState(() => saving = true);
            try {
              await ref
                  .read(adminBusinessesControllerProvider.notifier)
                  .updateBusiness(
                    businessId: item.id,
                    name: nameCtrl.text.trim(),
                    category: categoryCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    city: cityCtrl.text.trim(),
                    district: districtCtrl.text.trim(),
                    lat: double.tryParse(latCtrl.text.trim()),
                    lng: double.tryParse(lngCtrl.text.trim()),
                    logoUrl: logoUrl.trim(),
                    coverUrl: coverUrl.trim(),
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(content: Text(l10n.adminBusinessesUpdated)),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppErrorMapper.message(e))),
                );
              }
              setModalState(() => saving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminBusinessesEditTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminBusinessesPublicMenuLinkLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          buildPublicMenuUrl(
                            businessId: item.id,
                            businessPublicSlug: item.publicSlug,
                            businessSlug: item.slug,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.adminBusinessesQrGenerationLinkLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          buildQrMenuUrl(businessId: item.id),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openQrMenu(item),
                              icon: const Icon(Icons.qr_code_2_outlined),
                              label: Text(l10n.adminBusinessesQrMenuAction),
                            ),
                            FilledButton.icon(
                              onPressed: () => _openPublicMenu(item),
                              icon: const Icon(Icons.open_in_new),
                              label: Text(l10n.adminBusinessesPublicMenuAction),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _copyPublicMenuUrl(context, item),
                              icon: const Icon(Icons.copy_outlined),
                              label: Text(l10n.adminBusinessesCopyMenuLinkAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    tabs: [
                      Tab(text: l10n.adminBusinessesInfoTab),
                      Tab(text: l10n.adminBusinessesMediaTab),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      children: [
                        ListView(
                          children: [
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.adminBusinessesNameColumn,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: categoryCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.ownerCategoryLabel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: addressCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.ownerAddressLabel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: cityCtrl,
                                    decoration: InputDecoration(
                                      labelText: l10n.city,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: districtCtrl,
                                    decoration: InputDecoration(
                                      labelText: l10n.district,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: latCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.adminBusinessesLatitudeLabel,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: lngCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.adminBusinessesLongitudeLabel,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: saving ? null : save,
                                child: Text(saving ? l10n.saving : l10n.save),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          children: [
                            Text(
                              l10n.adminBusinessesLogoColumn,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            if (logoUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: logoUrl,
                                  variant: AppImageVariant.thumb,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: uploadingLogo
                                      ? null
                                      : () async {
                                          setModalState(() => uploadingLogo = true);
                                          try {
                                            final res = await mediaUploadRepository
                                                .pickAndUploadImage(
                                              title: '${item.id}_logo',
                                            );
                                            if (res != null) {
                                              logoUrl = res.urlLarge;
                                              logoCtrl.text = logoUrl;
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
                                          }
                                          setModalState(
                                            () => uploadingLogo = false,
                                          );
                                        },
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    uploadingLogo
                                        ? l10n.ownerUploading
                                        : l10n.adminBusinessesUploadMediaAction,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: uploadingLogo
                                      ? null
                                      : () => setModalState(() {
                                          logoUrl = '';
                                          logoCtrl.text = '';
                                        }),
                                  child: Text(l10n.adminBusinessesClearAction),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: logoCtrl,
                              onChanged: (v) => logoUrl = v.trim(),
                              decoration: InputDecoration(
                                labelText: l10n.adminBusinessesLogoUrlLabel,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.adminBusinessesCoverLabel,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            if (coverUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: coverUrl,
                                  variant: AppImageVariant.medium,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: uploadingCover
                                      ? null
                                      : () async {
                                          setModalState(() => uploadingCover = true);
                                          try {
                                            final res = await mediaUploadRepository
                                                .pickAndUploadImage(
                                              title: '${item.id}_cover',
                                            );
                                            if (res != null) {
                                              coverUrl = res.urlLarge;
                                              coverCtrl.text = coverUrl;
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
                                          }
                                          setModalState(
                                            () => uploadingCover = false,
                                          );
                                        },
                                  icon: const Icon(Icons.upload),
                                  label: Text(
                                    uploadingCover
                                        ? l10n.ownerUploading
                                        : l10n.adminBusinessesUploadMediaAction,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: uploadingCover
                                      ? null
                                      : () => setModalState(() {
                                          coverUrl = '';
                                          coverCtrl.text = '';
                                        }),
                                  child: Text(l10n.adminBusinessesClearAction),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: coverCtrl,
                              onChanged: (v) => coverUrl = v.trim(),
                              decoration: InputDecoration(
                                labelText: l10n.adminBusinessesCoverUrlLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: saving ? null : save,
                                child: Text(saving ? l10n.saving : l10n.save),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshRiskSignals(List<AdminBusinessItem> items) async {
    setState(() => _riskLoading = true);
    try {
      final map = await ref
          .read(adminBusinessesRepositoryProvider)
          .fetchRiskSignals(items.map((e) => e.id).toList());
      if (!mounted) return;
      setState(() {
        _riskById
          ..clear()
          ..addAll(map);
      });
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _riskLoading = false);
    }
  }

  Future<void> _openPublicMenu(AdminBusinessItem item) async {
    final url = buildPublicMenuUrl(
      businessId: item.id,
      businessPublicSlug: item.publicSlug,
      businessSlug: item.slug,
    );
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openQrMenu(AdminBusinessItem item) async {
    final session = ref.read(supabaseProvider).auth.currentSession;
    if (session == null) {
      final loginUrl = buildQrLoginUrl(businessId: item.id);
      final uri = Uri.parse(loginUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      final url = buildQrMenuUrl(businessId: item.id);
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    submitPostRedirect(buildPanelSessionHandoffUrl(), {
      'access_token': session.accessToken,
      'refresh_token': refreshToken,
      'business_id': item.id,
      'lang': 'tr',
      'theme': 'bold',
    }, target: '_blank');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerDigitalMenuOpenedInNewTab)),
      );
    }
  }

  Future<void> _copyPublicMenuUrl(
    BuildContext context,
    AdminBusinessItem item,
  ) async {
    final url = buildPublicMenuUrl(
      businessId: item.id,
      businessPublicSlug: item.publicSlug,
      businessSlug: item.slug,
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.adminBusinessesPublicMenuCopied)),
    );
  }

  Future<void> _openMergeFlow(
    BuildContext context,
    AdminBusinessItem source,
  ) async {
    List<AdminBusinessItem> candidates = const [];
    try {
      candidates = await ref
          .read(adminBusinessesRepositoryProvider)
          .findMergeCandidates(source: source);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      return;
    }
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminBusinessesNoMergeCandidates)),
      );
      return;
    }

    String selectedId = candidates.first.id;
    bool applyNow = false;
    final noteCtrl = TextEditingController(
      text: context.l10n.adminBusinessesMergeSuggestedNote,
    );
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.adminBusinessesMergeCandidateTitle(source.name),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  for (final c in candidates)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selectedId == c.id
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selectedId == c.id
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        '${c.district ?? ''} / ${c.city ?? ''}'.trim(),
                      ),
                      onTap: () => setModalState(() => selectedId = c.id),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(labelText: context.l10n.note),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  CheckboxListTile(
                    value: applyNow,
                    onChanged: (v) => setModalState(() => applyNow = v == true),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(context.l10n.adminBusinessesMergeApplyNowTitle),
                    subtitle: Text(
                      context.l10n.adminBusinessesMergeApplyNowDescription,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final preview = await ref
                              .read(adminBusinessesRepositoryProvider)
                              .mergeBusinesses(
                                primaryBusinessId: selectedId,
                                duplicateBusinessId: source.id,
                                note: noteCtrl.text.trim(),
                                dryRun: true,
                              );
                          if (!ctx.mounted) return;
                          final summary =
                              (preview['summary'] as Map?)
                                  ?.cast<String, dynamic>() ??
                              const {};
                          final text =
                              context.l10n.adminBusinessesMergePreviewSummary(
                                (summary['menus'] ?? 0) as int,
                                (summary['menu_items'] ?? 0) as int,
                                (summary['reviews'] ?? 0) as int,
                                (summary['media'] ?? 0) as int,
                              );
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(text)),
                          );
                        },
                        child: Text(context.l10n.adminBusinessesMergePreviewAction),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          applyNow
                              ? context.l10n.adminBusinessesMergeApplyNowAction
                              : context.l10n.adminBusinessesMergeCreateProposalAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) {
      noteCtrl.dispose();
      return;
    }
    try {
      if (applyNow) {
        final res = await ref
            .read(adminBusinessesRepositoryProvider)
            .mergeBusinesses(
              primaryBusinessId: selectedId,
              duplicateBusinessId: source.id,
              note: noteCtrl.text.trim(),
              dryRun: false,
            );
        final ok = res['ok'] == true;
        if (!ok) {
          throw Exception((res['error'] ?? 'merge_failed').toString());
        }
      } else {
        await ref
            .read(adminBusinessesRepositoryProvider)
            .logMergeProposal(
              primaryBusinessId: selectedId,
              duplicateBusinessId: source.id,
              note: noteCtrl.text.trim(),
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            applyNow
                ? context.l10n.adminBusinessesMergeCompleted
                : context.l10n.adminBusinessesMergeProposalLogged,
          ),
        ),
      );
      ref.read(adminBusinessesControllerProvider.notifier).refresh(force: true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
    } finally {
      noteCtrl.dispose();
    }
  }

}

class _BusinessBulkStatusBar extends StatelessWidget {
  const _BusinessBulkStatusBar({
    required this.value,
    required this.onChanged,
    required this.onApply,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: ValueKey(value),
            initialValue: value.isEmpty ? null : value,
            decoration: InputDecoration(
              labelText: l10n.adminBusinessesBulkStatusLabel,
            ),
            items: [
              DropdownMenuItem(
                value: _businessStatusVerified,
                child: Text(l10n.adminBusinessesBulkStatusVerified),
              ),
              DropdownMenuItem(
                value: _businessStatusNeedsReview,
                child: Text(l10n.adminBusinessesBulkStatusNeedsReview),
              ),
              DropdownMenuItem(
                value: _businessStatusAssigned,
                child: Text(l10n.adminTableAssignToMeAction),
              ),
              DropdownMenuItem(
                value: _businessStatusUnassigned,
                child: Text(l10n.adminBusinessesBulkStatusUnassigned),
              ),
            ],
            onChanged: (next) => onChanged(next ?? ''),
          ),
        ),
        FilledButton(
          onPressed: onApply,
          child: Text(l10n.apply),
        ),
      ],
    );
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

class _BusinessStatusBadge extends StatelessWidget {
  const _BusinessStatusBadge({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _businessStatusVerified => AppColors.success,
      _businessStatusAssigned => AppColors.primary,
      _businessStatusNeedsReview => AppColors.warning,
      _ => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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

String _businessStatus(
  AdminBusinessItem item,
  BusinessRiskSignal? signal,
) {
  if (item.isVerified) return _businessStatusVerified;
  if ((item.assignedTo ?? '').trim().isNotEmpty) return _businessStatusAssigned;
  if (signal != null && (signal.suspicious || signal.riskScore >= 3)) {
    return _businessStatusNeedsReview;
  }
  return _businessStatusUnassigned;
}

String _businessStatusLabel(
  BuildContext context,
  AdminBusinessItem item,
  BusinessRiskSignal? signal,
) {
  final l10n = context.l10n;
  return switch (_businessStatus(item, signal)) {
    _businessStatusVerified => l10n.verified,
    _businessStatusAssigned => l10n.adminCommonAssigned,
    _businessStatusNeedsReview => l10n.adminBusinessesStatusNeedsReview,
    _ => l10n.adminCommonUnassigned,
  };
}

int _businessStatusSortValue(
  AdminBusinessItem item,
  BusinessRiskSignal? signal,
) {
  return switch (_businessStatus(item, signal)) {
    _businessStatusVerified => 3,
    _businessStatusAssigned => 2,
    _businessStatusNeedsReview => 1,
    _ => 0,
  };
}

int _businessRiskSortValue(BusinessRiskSignal? signal) {
  if (signal == null) return -1;
  if (signal.suspicious) return 100 + signal.riskScore;
  return signal.riskScore;
}

String _locationLabel(AdminBusinessItem item) {
  final city = (item.city ?? '').trim();
  final district = (item.district ?? '').trim();
  final parts = [district, city].where((value) => value.isNotEmpty).toList();
  if (parts.isEmpty) return '-';
  return parts.join(', ');
}

String _assignedLabel(
  BuildContext context,
  String? assignedTo,
  String? currentUserId,
) {
  final l10n = context.l10n;
  final normalized = (assignedTo ?? '').trim();
  if (normalized.isEmpty) return l10n.adminCommonUnassigned;
  if (currentUserId != null && normalized == currentUserId) {
    return l10n.adminCommonMine;
  }
  return normalized;
}

bool _matchesDateRange(DateTime value, DateTimeRange? range) {
  if (range == null) return true;
  final day = DateTime(value.year, value.month, value.day);
  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

bool _looksLikePermissionError(Object? error) {
  final text = AppErrorMapper.message(error).toLowerCase();
  return text.contains('403') ||
      text.contains('forbidden') ||
      text.contains('permission') ||
      text.contains('yetki') ||
      text.contains('unauthorized');
}

Widget _riskCell(BuildContext context, BusinessRiskSignal? signal) {
  if (signal == null) {
    return const Text('-', style: TextStyle(color: AppColors.muted));
  }
  final l10n = context.l10n;
  final text = signal.suspicious
      ? l10n.adminBusinessesRiskSuspicious
      : (signal.riskScore >= 2
            ? l10n.adminBusinessesRiskMedium
            : l10n.adminBusinessesRiskLow);
  final color = signal.suspicious
      ? AppColors.danger
      : (signal.riskScore >= 2 ? AppColors.warning : AppColors.success);
  return Tooltip(
    message: l10n.adminBusinessesRiskTooltip(
      signal.missingAddress
          ? l10n.adminBusinessesRiskMissing
          : l10n.adminBusinessesRiskAvailable,
      signal.missingPhone
          ? l10n.adminBusinessesRiskMissing
          : l10n.adminBusinessesRiskAvailable,
      signal.photoCount,
      signal.engagementCount,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ),
  );
}

Widget _logoPreview(String? url) {
  if (url == null || url.isEmpty) {
    return const SizedBox(
      width: 32,
      height: 32,
      child: Icon(Icons.image_not_supported),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: AppNetworkImage(
      url: url,
      variant: AppImageVariant.thumb,
      width: 32,
      height: 32,
      fit: BoxFit.cover,
    ),
  );
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
