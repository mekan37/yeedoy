import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_audit_repository.dart';
import 'admin_audit_models.dart';

class AdminAuditState {
  const AdminAuditState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.actionFilter,
    required this.targetTypeFilter,
    required this.actorFilter,
    required this.targetId,
    required this.businessId,
    required this.from,
    required this.to,
    required this.query,
  });

  final List<AdminAuditLogItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String actionFilter;
  final String targetTypeFilter;
  final String actorFilter;
  final String targetId;
  final String businessId;
  final DateTime? from;
  final DateTime? to;
  final String query;

  factory AdminAuditState.initial() => const AdminAuditState(
    items: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: true,
    error: null,
    actionFilter: '',
    targetTypeFilter: '',
    actorFilter: '',
    targetId: '',
    businessId: '',
    from: null,
    to: null,
    query: '',
  );

  AdminAuditState copyWith({
    List<AdminAuditLogItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? actionFilter,
    String? targetTypeFilter,
    String? actorFilter,
    String? targetId,
    String? businessId,
    Object? from = _unset,
    Object? to = _unset,
    String? query,
  }) {
    return AdminAuditState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      actionFilter: actionFilter ?? this.actionFilter,
      targetTypeFilter: targetTypeFilter ?? this.targetTypeFilter,
      actorFilter: actorFilter ?? this.actorFilter,
      targetId: targetId ?? this.targetId,
      businessId: businessId ?? this.businessId,
      from: identical(from, _unset) ? this.from : from as DateTime?,
      to: identical(to, _unset) ? this.to : to as DateTime?,
      query: query ?? this.query,
    );
  }
}

const Object _unset = Object();

final adminAuditControllerProvider =
    NotifierProvider<AdminAuditController, AdminAuditState>(
      AdminAuditController.new,
    );

class AdminAuditController extends Notifier<AdminAuditState> {
  static const int pageSize = 50;

  @override
  AdminAuditState build() => AdminAuditState.initial();

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(adminAuditRepositoryProvider);
      final items = await repo.fetchLogs(
        limit: pageSize,
        offset: 0,
        actionFilter: state.actionFilter,
        targetTypeFilter: state.targetTypeFilter,
        actorFilter: state.actorFilter,
        targetId: state.targetId,
        businessId: state.businessId,
        from: state.from,
        to: state.to,
        query: state.query,
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
      final repo = ref.read(adminAuditRepositoryProvider);
      final items = await repo.fetchLogs(
        limit: pageSize,
        offset: state.items.length,
        actionFilter: state.actionFilter,
        targetTypeFilter: state.targetTypeFilter,
        actorFilter: state.actorFilter,
        targetId: state.targetId,
        businessId: state.businessId,
        from: state.from,
        to: state.to,
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

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    await loadInitial();
  }

  void setFilters({
    String? actionFilter,
    String? targetTypeFilter,
    String? actorFilter,
    String? targetId,
    String? businessId,
    Object? from = _unset,
    Object? to = _unset,
    String? query,
  }) {
    state = state.copyWith(
      actionFilter: actionFilter ?? state.actionFilter,
      targetTypeFilter: targetTypeFilter ?? state.targetTypeFilter,
      actorFilter: actorFilter ?? state.actorFilter,
      targetId: targetId ?? state.targetId,
      businessId: businessId ?? state.businessId,
      from: from,
      to: to,
      query: query ?? state.query,
    );
  }
}
