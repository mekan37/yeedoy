import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_monetization_repository.dart';
import 'admin_models.dart';

class AdminSponsorshipsState {
  const AdminSponsorshipsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
    required this.surfaceFilter,
  });

  final List<AdminSponsorshipItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;
  final String surfaceFilter;

  factory AdminSponsorshipsState.initial() => const AdminSponsorshipsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: '',
        surfaceFilter: '',
      );

  AdminSponsorshipsState copyWith({
    List<AdminSponsorshipItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
    String? surfaceFilter,
  }) {
    return AdminSponsorshipsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      surfaceFilter: surfaceFilter ?? this.surfaceFilter,
    );
  }
}

final adminSponsorshipsControllerProvider =
    NotifierProvider<AdminSponsorshipsController, AdminSponsorshipsState>(
  AdminSponsorshipsController.new,
);

class AdminSponsorshipsController extends Notifier<AdminSponsorshipsState> {
  static const int pageSize = 50;
  Timer? _debounce;

  @override
  AdminSponsorshipsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadInitial);
    return AdminSponsorshipsState.initial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminMonetizationRepositoryProvider);
      final items = await repo.listSponsorships(
        status: state.statusFilter,
        surface: state.surfaceFilter,
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
      final items = await repo.listSponsorships(
        status: state.statusFilter,
        surface: state.surfaceFilter,
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

  void setSurfaceFilter(String v) {
    state = state.copyWith(surfaceFilter: v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), loadInitial);
  }
}
