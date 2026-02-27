import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_risk_repository.dart';
import 'admin_risk_models.dart';

class AdminRiskState {
  const AdminRiskState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.error,
    required this.minScore,
    required this.busyUserId,
  });

  final List<AdminRiskQueueItem> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Object? error;
  final int minScore;
  final String? busyUserId;

  factory AdminRiskState.initial() => const AdminRiskState(
    items: [],
    loading: false,
    loadingMore: false,
    hasMore: true,
    error: null,
    minScore: 20,
    busyUserId: null,
  );

  AdminRiskState copyWith({
    List<AdminRiskQueueItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    Object? error,
    int? minScore,
    String? busyUserId,
  }) {
    return AdminRiskState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      minScore: minScore ?? this.minScore,
      busyUserId: busyUserId,
    );
  }
}

final adminRiskControllerProvider =
    NotifierProvider<AdminRiskController, AdminRiskState>(
      AdminRiskController.new,
    );

class AdminRiskController extends Notifier<AdminRiskState> {
  static const _pageSize = 30;

  @override
  AdminRiskState build() => AdminRiskState.initial();

  Future<void> loadInitial() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, loadingMore: false, error: null);
    try {
      final repo = ref.read(adminRiskRepositoryProvider);
      final items = await repo.listRiskyUsers(
        limit: _pageSize,
        offset: 0,
        minScore: state.minScore,
      );
      state = state.copyWith(
        items: items,
        loading: false,
        hasMore: items.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true, error: null);
    try {
      final repo = ref.read(adminRiskRepositoryProvider);
      final items = await repo.listRiskyUsers(
        limit: _pageSize,
        offset: state.items.length,
        minScore: state.minScore,
      );
      state = state.copyWith(
        items: [...state.items, ...items],
        loadingMore: false,
        hasMore: items.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      loading: true,
      loadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    await loadInitial();
  }

  void setMinScore(int score) {
    state = state.copyWith(minScore: score);
    loadInitial();
  }

  Future<void> applyAction({
    required String userId,
    required String action,
    int minutes = 60,
    required String reason,
  }) async {
    if (state.busyUserId != null) return;
    state = state.copyWith(busyUserId: userId, error: null);
    try {
      await ref
          .read(adminRiskRepositoryProvider)
          .applyAction(
            userId: userId,
            action: action,
            minutes: minutes,
            reason: reason,
          );
      await refresh();
    } catch (e) {
      state = state.copyWith(busyUserId: null, error: e);
    } finally {
      if (state.busyUserId == userId) {
        state = state.copyWith(busyUserId: null);
      }
    }
  }
}
