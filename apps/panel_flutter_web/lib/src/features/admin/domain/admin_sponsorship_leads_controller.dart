import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_monetization_repository.dart';
import 'admin_models.dart';

class AdminSponsorshipLeadsState {
  const AdminSponsorshipLeadsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
  });

  final List<AdminSponsorshipLead> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;

  factory AdminSponsorshipLeadsState.initial() => const AdminSponsorshipLeadsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: '',
      );

  AdminSponsorshipLeadsState copyWith({
    List<AdminSponsorshipLead>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
  }) {
    return AdminSponsorshipLeadsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final adminSponsorshipLeadsControllerProvider =
    NotifierProvider<AdminSponsorshipLeadsController, AdminSponsorshipLeadsState>(
  AdminSponsorshipLeadsController.new,
);

class AdminSponsorshipLeadsController extends Notifier<AdminSponsorshipLeadsState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminSponsorshipLeadsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminSponsorshipLeadsState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final items = await repo.listLeads(
        status: state.statusFilter,
        limit: pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final items = await repo.listLeads(
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

  Future<void> refresh() async {
    state = state.copyWith(
      items: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      error: null,
    );
    await loadInitial();
  }

  void setStatusFilter(String v) {
    state = state.copyWith(statusFilter: v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), loadInitial);
  }
}
