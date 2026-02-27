import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_reports_repository.dart';
import 'admin_models.dart';

class AdminReportsState {
  const AdminReportsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
    required this.query,
    required this.assignedFilter,
    required this.slaOnly,
    required this.selectedIds,
    required this.selectedIndex,
    required this.selectedId,
    required this.isDetailOpen,
  });

  final List<AdminReportItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;
  final String query;
  final String assignedFilter;
  final bool slaOnly;
  final Set<String> selectedIds;
  final int? selectedIndex;
  final String? selectedId;
  final bool isDetailOpen;

  factory AdminReportsState.initial() => const AdminReportsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: '',
        query: '',
        assignedFilter: '',
        slaOnly: false,
        selectedIds: <String>{},
        selectedIndex: null,
        selectedId: null,
        isDetailOpen: false,
      );

  AdminReportsState copyWith({
    List<AdminReportItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
    String? query,
    String? assignedFilter,
    bool? slaOnly,
    Set<String>? selectedIds,
    int? selectedIndex,
    String? selectedId,
    bool? isDetailOpen,
  }) {
    return AdminReportsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      query: query ?? this.query,
      assignedFilter: assignedFilter ?? this.assignedFilter,
      slaOnly: slaOnly ?? this.slaOnly,
      selectedIds: selectedIds ?? this.selectedIds,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedId: selectedId ?? this.selectedId,
      isDetailOpen: isDetailOpen ?? this.isDetailOpen,
    );
  }
}

final adminReportsControllerProvider =
    NotifierProvider<AdminReportsController, AdminReportsState>(AdminReportsController.new);

class AdminReportsController extends Notifier<AdminReportsState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminReportsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminReportsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminReportsRepositoryProvider);
      final items = await repo.listReports(
        status: state.statusFilter,
        assigned: state.assignedFilter,
        slaOnly: state.slaOnly,
        limit: pageSize,
        offset: 0,
        query: state.query,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
        selectedIds: <String>{},
        selectedIndex: _resolveIndex(items, state.selectedId),
        selectedId: _resolveSelectedId(items, state.selectedId),
        isDetailOpen: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(adminReportsRepositoryProvider);
      final items = await repo.listReports(
        status: state.statusFilter,
        assigned: state.assignedFilter,
        slaOnly: state.slaOnly,
        limit: pageSize,
        offset: state.items.length,
        query: state.query,
      );
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<bool> refresh({bool force = false}) async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
      selectedIds: <String>{},
      selectedIndex: null,
      selectedId: null,
      isDetailOpen: false,
    );
    return loadInitial(force: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, selectedIds: <String>{});
    loadInitial();
  }

  void setAssignedFilter(String assigned) {
    state = state.copyWith(assignedFilter: assigned, selectedIds: <String>{});
    loadInitial();
  }

  void setSlaOnly(bool value) {
    state = state.copyWith(slaOnly: value);
    loadInitial();
  }

  void setQuery(String q) {
    state = state.copyWith(query: q, selectedIds: <String>{});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadInitial);
  }

  void toggleSelection(String id, bool selected) {
    final next = {...state.selectedIds};
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void selectAllVisible(bool select) {
    final next = {...state.selectedIds};
    if (select) {
      for (final r in state.items) {
        next.add(r.id);
      }
    } else {
      for (final r in state.items) {
        next.remove(r.id);
      }
    }
    state = state.copyWith(selectedIds: next);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: <String>{});
  }

  void selectIndex(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(
      selectedIndex: index,
      selectedId: state.items[index].id,
    );
  }

  void next() {
    if (state.items.isEmpty) return;
    final current = state.selectedIndex ?? 0;
    final nextIndex = current + 1 < state.items.length ? current + 1 : state.items.length - 1;
    selectIndex(nextIndex);
  }

  void prev() {
    if (state.items.isEmpty) return;
    final current = state.selectedIndex ?? 0;
    final prevIndex = current - 1 >= 0 ? current - 1 : 0;
    selectIndex(prevIndex);
  }

  void openDetail() {
    state = state.copyWith(isDetailOpen: true);
  }

  void closeDetail() {
    state = state.copyWith(isDetailOpen: false);
  }

  void toggleDetail() {
    state = state.copyWith(isDetailOpen: !state.isDetailOpen);
  }

  Future<void> updateStatus({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    final prev = state.items;
    final updated = prev
        .map((r) => r.id == reportId ? _copyReport(r, status: status, adminNote: adminNote) : r)
        .toList();
    final next = _maybeRemoveAfterStatus(updated, reportId, status);
    state = state.copyWith(items: next);
    try {
      await ref.read(adminReportsRepositoryProvider).updateReport(
            reportId: reportId,
            status: status,
            adminNote: adminNote,
          );
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> bulkUpdateStatus({
    required String status,
    String? adminNote,
  }) async {
    if (state.selectedIds.isEmpty) return;
    final prev = state.items;
    final updated = prev
        .map((r) => state.selectedIds.contains(r.id)
            ? _copyReport(r, status: status, adminNote: adminNote)
            : r)
        .toList();
    final next = _maybeRemoveBulkAfterStatus(updated, status, state.selectedIds);
    state = state.copyWith(items: next);
    try {
      await ref.read(adminReportsRepositoryProvider).bulkUpdateStatus(
            reportIds: state.selectedIds.toList(),
            status: status,
            adminNote: adminNote,
          );
      state = state.copyWith(selectedIds: <String>{});
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> assignToMe(String reportId, {required String adminId}) async {
    final prev = state.items;
    final next = prev
        .map((r) => r.id == reportId ? _copyReport(r, assignedTo: adminId, assignedAt: DateTime.now()) : r)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminReportsRepositoryProvider).assignReport(reportId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> unassign(String reportId) async {
    final prev = state.items;
    final next = prev
        .map((r) => r.id == reportId ? _copyReport(r, assignedTo: null, assignedAt: null) : r)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminReportsRepositoryProvider).unassignReport(reportId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<bool> applyRules(String reportId) async {
    final prev = state.items;
    final next = prev.where((r) => r.id != reportId).toList();
    state = state.copyWith(items: next);
    try {
      final applied = await ref.read(adminReportsRepositoryProvider).applyAutoModerationRules(reportId);
      if (!applied) {
        state = state.copyWith(items: prev);
      } else {
        _reconcileSelection(next);
      }
      return applied;
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  void _reconcileSelection(List<AdminReportItem> items) {
    state = state.copyWith(
      selectedIndex: _resolveIndex(items, state.selectedId),
      selectedId: _resolveSelectedId(items, state.selectedId),
    );
  }

  List<AdminReportItem> _maybeRemoveAfterStatus(
    List<AdminReportItem> items,
    String reportId,
    String status,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((r) => r.id != reportId).toList();
  }

  List<AdminReportItem> _maybeRemoveBulkAfterStatus(
    List<AdminReportItem> items,
    String status,
    Set<String> ids,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((r) => !ids.contains(r.id)).toList();
  }
}

int? _resolveIndex(List<AdminReportItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final idx = items.indexWhere((r) => r.id == selectedId);
    if (idx >= 0) return idx;
  }
  return 0;
}

String? _resolveSelectedId(List<AdminReportItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final exists = items.any((r) => r.id == selectedId);
    if (exists) return selectedId;
  }
  return items.first.id;
}

AdminReportItem _copyReport(
  AdminReportItem r, {
  String? status,
  String? adminNote,
  String? assignedTo,
  DateTime? assignedAt,
  bool? autoModerated,
}) {
  return AdminReportItem(
    id: r.id,
    status: status ?? r.status,
    reason: r.reason,
    createdAt: r.createdAt,
    details: r.details,
    businessId: r.businessId,
    reviewId: r.reviewId,
    adminNote: adminNote ?? r.adminNote,
    reporterId: r.reporterId,
    assignedTo: assignedTo ?? r.assignedTo,
    assignedAt: assignedAt ?? r.assignedAt,
    autoModerated: autoModerated ?? r.autoModerated,
    ageHours: r.ageHours,
    slaBreached: r.slaBreached,
  );
}
