import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_claims_repository.dart';
import 'admin_models.dart';

class AdminClaimsState {
  const AdminClaimsState({
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

  final List<AdminOwnerClaimItem> items;
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

  factory AdminClaimsState.initial() => const AdminClaimsState(
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

  AdminClaimsState copyWith({
    List<AdminOwnerClaimItem>? items,
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
    return AdminClaimsState(
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

final adminClaimsControllerProvider =
    NotifierProvider<AdminClaimsController, AdminClaimsState>(AdminClaimsController.new);

class AdminClaimsController extends Notifier<AdminClaimsState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminClaimsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminClaimsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminClaimsRepositoryProvider);
      final items = await repo.listClaims(
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
      final repo = ref.read(adminClaimsRepositoryProvider);
      final items = await repo.listClaims(
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
      for (final c in state.items) {
        next.add(c.id);
      }
    } else {
      for (final c in state.items) {
        next.remove(c.id);
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

  Future<void> decide({
    required String claimId,
    required String decision,
    String? note,
  }) async {
    final prev = state.items;
    final updated = prev
        .map((c) => c.id == claimId ? _copyClaim(c, status: decision, adminNote: note) : c)
        .toList();
    final next = _maybeRemoveAfterDecision(updated, claimId, decision);
    state = state.copyWith(items: next);
    try {
      await ref.read(adminClaimsRepositoryProvider).decideClaim(
            claimId: claimId,
            decision: decision,
            note: note,
          );
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> bulkDecide({
    required String decision,
    String? note,
  }) async {
    if (state.selectedIds.isEmpty) return;
    final prev = state.items;
    final updated = prev
        .map((c) => state.selectedIds.contains(c.id)
            ? _copyClaim(c, status: decision, adminNote: note)
            : c)
        .toList();
    final next = _maybeRemoveBulkAfterDecision(updated, decision, state.selectedIds);
    state = state.copyWith(items: next);
    try {
      await ref.read(adminClaimsRepositoryProvider).bulkDecideClaims(
            claimIds: state.selectedIds.toList(),
            decision: decision,
            note: note,
          );
      state = state.copyWith(selectedIds: <String>{});
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> assignToMe(String claimId, {required String adminId}) async {
    final prev = state.items;
    final next = prev
        .map((c) => c.id == claimId ? _copyClaim(c, assignedTo: adminId, assignedAt: DateTime.now()) : c)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminClaimsRepositoryProvider).assignClaim(claimId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> unassign(String claimId) async {
    final prev = state.items;
    final next = prev
        .map((c) => c.id == claimId ? _copyClaim(c, assignedTo: null, assignedAt: null) : c)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminClaimsRepositoryProvider).unassignClaim(claimId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<bool> applyRules(String claimId) async {
    final prev = state.items;
    final next = prev.where((c) => c.id != claimId).toList();
    state = state.copyWith(items: next);
    try {
      final applied = await ref.read(adminClaimsRepositoryProvider).applyAutoModerationRules(claimId);
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

  void _reconcileSelection(List<AdminOwnerClaimItem> items) {
    state = state.copyWith(
      selectedIndex: _resolveIndex(items, state.selectedId),
      selectedId: _resolveSelectedId(items, state.selectedId),
    );
  }

  List<AdminOwnerClaimItem> _maybeRemoveAfterDecision(
    List<AdminOwnerClaimItem> items,
    String claimId,
    String decision,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (decision == state.statusFilter) return items;
    return items.where((c) => c.id != claimId).toList();
  }

  List<AdminOwnerClaimItem> _maybeRemoveBulkAfterDecision(
    List<AdminOwnerClaimItem> items,
    String decision,
    Set<String> ids,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (decision == state.statusFilter) return items;
    return items.where((c) => !ids.contains(c.id)).toList();
  }
}

int? _resolveIndex(List<AdminOwnerClaimItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final idx = items.indexWhere((c) => c.id == selectedId);
    if (idx >= 0) return idx;
  }
  return 0;
}

String? _resolveSelectedId(List<AdminOwnerClaimItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final exists = items.any((c) => c.id == selectedId);
    if (exists) return selectedId;
  }
  return items.first.id;
}

AdminOwnerClaimItem _copyClaim(
  AdminOwnerClaimItem c, {
  String? status,
  String? adminNote,
  String? assignedTo,
  DateTime? assignedAt,
  bool? autoModerated,
}) {
  return AdminOwnerClaimItem(
    id: c.id,
    status: status ?? c.status,
    fullName: c.fullName,
    phone: c.phone,
    createdAt: c.createdAt,
    businessId: c.businessId,
    evidenceUrl: c.evidenceUrl,
    note: c.note,
    adminNote: adminNote ?? c.adminNote,
    assignedTo: assignedTo ?? c.assignedTo,
    assignedAt: assignedAt ?? c.assignedAt,
    autoModerated: autoModerated ?? c.autoModerated,
    ageDays: c.ageDays,
    slaBreached: c.slaBreached,
  );
}
