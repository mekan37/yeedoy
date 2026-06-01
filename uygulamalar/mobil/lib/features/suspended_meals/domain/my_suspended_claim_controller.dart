import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/my_suspended_claim_repository.dart';
import 'my_suspended_claim_models.dart';

class MySuspendedClaimsState {
  const MySuspendedClaimsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
  });

  final List<MySuspendedClaimItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;

  factory MySuspendedClaimsState.initial() => const MySuspendedClaimsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: '',
      );

  MySuspendedClaimsState copyWith({
    List<MySuspendedClaimItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
  }) {
    return MySuspendedClaimsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final mySuspendedClaimsControllerProvider =
    NotifierProvider.autoDispose<MySuspendedClaimsController, MySuspendedClaimsState>(
  MySuspendedClaimsController.new,
);

final mySuspendedBadgeProvider =
    AsyncNotifierProvider.autoDispose<MySuspendedBadgeController, MySuspendedBadge>(
  MySuspendedBadgeController.new,
);

class MySuspendedClaimsController extends Notifier<MySuspendedClaimsState> {
  static const int pageSize = 20;

  @override
  MySuspendedClaimsState build() {
    Future.microtask(loadInitial);
    return MySuspendedClaimsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(mySuspendedClaimRepositoryProvider);
      final items = await repo.listClaims(
        status: state.statusFilter,
        limit: pageSize,
        offset: 0,
        force: force,
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
      final repo = ref.read(mySuspendedClaimRepositoryProvider);
      final items = await repo.listClaims(
        status: state.statusFilter,
        limit: pageSize,
        offset: state.items.length,
        force: false,
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
}

class MySuspendedBadgeController extends AsyncNotifier<MySuspendedBadge> {
  @override
  Future<MySuspendedBadge> build() async {
    return ref.read(mySuspendedClaimRepositoryProvider).fetchBadge(force: false);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(mySuspendedClaimRepositoryProvider)
          .fetchBadge(force: force);
    });
  }
}
