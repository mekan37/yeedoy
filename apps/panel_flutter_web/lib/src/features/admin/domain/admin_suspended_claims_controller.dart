import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_suspended_claims_repository.dart';
import 'admin_models.dart';

class AdminSuspendedClaimsState {
  const AdminSuspendedClaimsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
    required this.slaOnly,
    required this.selectedIndex,
    required this.selectedId,
    required this.isDetailOpen,
  });

  final List<AdminSuspendedClaimItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;
  final bool slaOnly;
  final int? selectedIndex;
  final String? selectedId;
  final bool isDetailOpen;

  factory AdminSuspendedClaimsState.initial() => const AdminSuspendedClaimsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: 'pending',
        slaOnly: false,
        selectedIndex: null,
        selectedId: null,
        isDetailOpen: false,
      );

  AdminSuspendedClaimsState copyWith({
    List<AdminSuspendedClaimItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
    bool? slaOnly,
    int? selectedIndex,
    String? selectedId,
    bool? isDetailOpen,
  }) {
    return AdminSuspendedClaimsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      slaOnly: slaOnly ?? this.slaOnly,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedId: selectedId ?? this.selectedId,
      isDetailOpen: isDetailOpen ?? this.isDetailOpen,
    );
  }
}

final adminSuspendedClaimsControllerProvider =
    NotifierProvider<AdminSuspendedClaimsController, AdminSuspendedClaimsState>(
        AdminSuspendedClaimsController.new);

class AdminSuspendedClaimsController extends Notifier<AdminSuspendedClaimsState> {
  static const int pageSize = 50;

  @override
  AdminSuspendedClaimsState build() {
    Future.microtask(loadInitial);
    return AdminSuspendedClaimsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminSuspendedClaimsRepositoryProvider);
      final items = await repo.listClaims(
        status: state.statusFilter,
        slaOnly: state.slaOnly,
        limit: pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
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
      final repo = ref.read(adminSuspendedClaimsRepositoryProvider);
      final items = await repo.listClaims(
        status: state.statusFilter,
        slaOnly: state.slaOnly,
        limit: pageSize,
        offset: state.items.length,
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
      selectedIndex: null,
      selectedId: null,
      isDetailOpen: false,
    );
    return loadInitial(force: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadInitial();
  }

  void setSlaOnly(bool value) {
    state = state.copyWith(slaOnly: value);
    loadInitial();
  }

  void selectIndex(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(
      selectedIndex: index,
      selectedId: state.items[index].id,
    );
  }

  void openDetail() {
    state = state.copyWith(isDetailOpen: true);
  }

  void closeDetail() {
    state = state.copyWith(isDetailOpen: false);
  }

  Future<void> approve(String claimId) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != claimId) return c;
      return _copyClaim(c, status: 'approved');
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, claimId, 'approved');
    state = state.copyWith(items: next);
    try {
      await ref.read(adminSuspendedClaimsRepositoryProvider).approve(claimId);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> reject({required String claimId, required String note}) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != claimId) return c;
      return _copyClaim(c, status: 'rejected', note: note);
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, claimId, 'rejected');
    state = state.copyWith(items: next);
    try {
      await ref
          .read(adminSuspendedClaimsRepositoryProvider)
          .reject(claimId: claimId, note: note);
      _reconcileSelection(next);
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  void _reconcileSelection(List<AdminSuspendedClaimItem> items) {
    state = state.copyWith(
      selectedIndex: _resolveIndex(items, state.selectedId),
      selectedId: _resolveSelectedId(items, state.selectedId),
    );
  }

  List<AdminSuspendedClaimItem> _maybeRemoveAfterStatus(
    List<AdminSuspendedClaimItem> items,
    String claimId,
    String status,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((c) => c.id != claimId).toList();
  }
}

int? _resolveIndex(List<AdminSuspendedClaimItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final idx = items.indexWhere((r) => r.id == selectedId);
    if (idx >= 0) return idx;
  }
  return 0;
}

String? _resolveSelectedId(List<AdminSuspendedClaimItem> items, String? selectedId) {
  if (items.isEmpty) return null;
  if (selectedId != null) {
    final exists = items.any((r) => r.id == selectedId);
    if (exists) return selectedId;
  }
  return items.first.id;
}

AdminSuspendedClaimItem _copyClaim(
  AdminSuspendedClaimItem c, {
  String? status,
  String? note,
}) {
  return AdminSuspendedClaimItem(
    id: c.id,
    status: status ?? c.status,
    createdAt: c.createdAt,
    businessId: c.businessId,
    businessName: c.businessName,
    amountCents: c.amountCents,
    currency: c.currency,
    claimantId: c.claimantId,
    claimantName: c.claimantName,
    mealMessage: c.mealMessage,
    note: note ?? c.note,
    ageHours: c.ageHours,
    slaBreached: c.slaBreached,
  );
}
