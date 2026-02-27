import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_suspended_repository.dart';
import 'owner_suspended_models.dart';

class OwnerSuspendedClaimsState {
  const OwnerSuspendedClaimsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
  });

  final List<OwnerSuspendedClaimItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;

  factory OwnerSuspendedClaimsState.initial() => const OwnerSuspendedClaimsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: 'pending',
      );

  OwnerSuspendedClaimsState copyWith({
    List<OwnerSuspendedClaimItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
  }) {
    return OwnerSuspendedClaimsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final ownerSuspendedClaimsControllerProvider = NotifierProvider.family<
    OwnerSuspendedClaimsController, OwnerSuspendedClaimsState, String>(
  OwnerSuspendedClaimsController.new,
);

class OwnerSuspendedClaimsController extends Notifier<OwnerSuspendedClaimsState> {
  OwnerSuspendedClaimsController(this.businessId);
  final String businessId;
  static const int pageSize = 20;

  @override
  OwnerSuspendedClaimsState build() {
    Future.microtask(loadInitial);
    return OwnerSuspendedClaimsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(ownerSuspendedRepositoryProvider);
      final items = await repo.listClaims(
        businessId: businessId,
        status: state.statusFilter,
        limit: pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
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
      final repo = ref.read(ownerSuspendedRepositoryProvider);
      final items = await repo.listClaims(
        businessId: businessId,
        status: state.statusFilter,
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
    );
    return loadInitial(force: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadInitial();
  }

  Future<String> approve(String claimId) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != claimId) return c;
      return _copyClaim(c, status: 'approved');
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, claimId, 'approved');
    state = state.copyWith(items: next);
    try {
      final code = await ref.read(ownerSuspendedRepositoryProvider).approve(claimId);
      return code;
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> fulfill({required String claimId, required String code}) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != claimId) return c;
      return _copyClaim(c, status: 'fulfilled');
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, claimId, 'fulfilled');
    state = state.copyWith(items: next);
    try {
      await ref.read(ownerSuspendedRepositoryProvider).fulfill(
            claimId: claimId,
            code: code,
          );
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  List<OwnerSuspendedClaimItem> _maybeRemoveAfterStatus(
    List<OwnerSuspendedClaimItem> items,
    String claimId,
    String status,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((c) => c.id != claimId).toList();
  }
}

OwnerSuspendedClaimItem _copyClaim(
  OwnerSuspendedClaimItem c, {
  String? status,
}) {
  return OwnerSuspendedClaimItem(
    id: c.id,
    status: status ?? c.status,
    claimantName: c.claimantName,
    amountCents: c.amountCents,
    currency: c.currency,
    mealMessage: c.mealMessage,
    createdAt: c.createdAt,
    ageHours: c.ageHours,
  );
}
