import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_suggestions_repository.dart';
import 'admin_models.dart';

class AdminSuggestionsState {
  const AdminSuggestionsState({
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
    required this.duplicatesLoading,
    required this.duplicates,
    required this.duplicatesError,
  });

  final List<AdminSuggestionItem> items;
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
  final bool duplicatesLoading;
  final List<DuplicateBusiness> duplicates;
  final Object? duplicatesError;

  factory AdminSuggestionsState.initial() => const AdminSuggestionsState(
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
        duplicatesLoading: false,
        duplicates: [],
        duplicatesError: null,
      );

  AdminSuggestionsState copyWith({
    List<AdminSuggestionItem>? items,
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
    bool? duplicatesLoading,
    List<DuplicateBusiness>? duplicates,
    Object? duplicatesError,
  }) {
    return AdminSuggestionsState(
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
      duplicatesLoading: duplicatesLoading ?? this.duplicatesLoading,
      duplicates: duplicates ?? this.duplicates,
      duplicatesError: duplicatesError,
    );
  }
}

final adminSuggestionsControllerProvider =
    NotifierProvider<AdminSuggestionsController, AdminSuggestionsState>(AdminSuggestionsController.new);

class AdminSuggestionsController extends Notifier<AdminSuggestionsState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminSuggestionsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminSuggestionsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
      duplicates: [],
      duplicatesError: null,
      duplicatesLoading: false,
    );
    try {
      final repo = ref.read(adminSuggestionsRepositoryProvider);
      final items = await repo.listSuggestions(
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
      final repo = ref.read(adminSuggestionsRepositoryProvider);
      final items = await repo.listSuggestions(
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
      duplicates: [],
      duplicatesError: null,
      duplicatesLoading: false,
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
      for (final s in state.items) {
        next.add(s.id);
      }
    } else {
      for (final s in state.items) {
        next.remove(s.id);
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

  Future<void> approve({
    required String suggestionId,
    String? adminNote,
  }) async {
    final prev = state.items;
    final updated = prev
        .map((s) => s.id == suggestionId ? _copySuggestion(s, status: 'approved', adminNote: adminNote) : s)
        .toList();
    final next = _maybeRemoveAfterStatus(updated, suggestionId, 'approved');
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).approveSuggestion(
            suggestionId: suggestionId,
            adminNote: adminNote,
          );
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> reject({
    required String suggestionId,
    String? adminNote,
  }) async {
    final prev = state.items;
    final updated = prev
        .map((s) => s.id == suggestionId ? _copySuggestion(s, status: 'rejected', adminNote: adminNote) : s)
        .toList();
    final next = _maybeRemoveAfterStatus(updated, suggestionId, 'rejected');
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).rejectSuggestion(
            suggestionId: suggestionId,
            adminNote: adminNote,
          );
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> bulkReject({String? adminNote}) async {
    if (state.selectedIds.isEmpty) return;
    final prev = state.items;
    final updated = prev
        .map((s) => state.selectedIds.contains(s.id)
            ? _copySuggestion(s, status: 'rejected', adminNote: adminNote)
            : s)
        .toList();
    final next = _maybeRemoveBulkAfterStatus(updated, 'rejected', state.selectedIds);
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).bulkRejectSuggestions(
            suggestionIds: state.selectedIds.toList(),
            adminNote: adminNote,
          );
      state = state.copyWith(selectedIds: <String>{});
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> assignToMe(String suggestionId, {required String adminId}) async {
    final prev = state.items;
    final next = prev
        .map((s) => s.id == suggestionId ? _copySuggestion(s, assignedTo: adminId, assignedAt: DateTime.now()) : s)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).assignSuggestion(suggestionId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> unassign(String suggestionId) async {
    final prev = state.items;
    final next = prev
        .map((s) => s.id == suggestionId ? _copySuggestion(s, assignedTo: null, assignedAt: null) : s)
        .toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).unassignSuggestion(suggestionId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> loadDuplicates(String suggestionId) async {
    state = state.copyWith(duplicatesLoading: true, duplicatesError: null, duplicates: []);
    try {
      final repo = ref.read(adminSuggestionsRepositoryProvider);
      final list = await repo.findDuplicates(suggestionId: suggestionId);
      state = state.copyWith(duplicates: list, duplicatesLoading: false);
    } catch (e) {
      state = state.copyWith(duplicatesLoading: false, duplicatesError: e, duplicates: []);
    }
  }

  Future<void> linkToExisting({
    required String suggestionId,
    required String businessId,
    String? adminNote,
  }) async {
    final prev = state.items;
    final next = prev.where((s) => s.id != suggestionId).toList();
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuggestionsRepositoryProvider).linkToExisting(
            suggestionId: suggestionId,
            businessId: businessId,
            adminNote: adminNote,
          );
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  void _reconcileSelection(List<AdminSuggestionItem> items) {
    state = state.copyWith(
      selectedIndex: _resolveIndex(items, state.selectedId),
      selectedId: _resolveSelectedId(items, state.selectedId),
    );
  }

  List<AdminSuggestionItem> _maybeRemoveAfterStatus(
    List<AdminSuggestionItem> items,
    String suggestionId,
    String status,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((s) => s.id != suggestionId).toList();
  }

  List<AdminSuggestionItem> _maybeRemoveBulkAfterStatus(
    List<AdminSuggestionItem> items,
    String status,
    Set<String> ids,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((s) => !ids.contains(s.id)).toList();
  }
}

int? _resolveIndex(List<AdminSuggestionItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final idx = items.indexWhere((s) => s.id == selectedId);
    if (idx >= 0) return idx;
  }
  return 0;
}

String? _resolveSelectedId(List<AdminSuggestionItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final exists = items.any((s) => s.id == selectedId);
    if (exists) return selectedId;
  }
  return items.first.id;
}

AdminSuggestionItem _copySuggestion(
  AdminSuggestionItem s, {
  String? status,
  String? adminNote,
  String? assignedTo,
  DateTime? assignedAt,
}) {
  return AdminSuggestionItem(
    id: s.id,
    name: s.name,
    status: status ?? s.status,
    createdAt: s.createdAt,
    city: s.city,
    district: s.district,
    category: s.category,
    adminNote: adminNote ?? s.adminNote,
    approvedBusinessId: s.approvedBusinessId,
    assignedTo: assignedTo ?? s.assignedTo,
    assignedAt: assignedAt ?? s.assignedAt,
    ageDays: s.ageDays,
    slaBreached: s.slaBreached,
  );
}
