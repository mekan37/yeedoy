import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_price_suggestions_repository.dart';
import 'owner_price_suggestion_models.dart';

class OwnerPriceSuggestionsState {
  const OwnerPriceSuggestionsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.statusFilter,
  });

  final List<OwnerPriceSuggestionItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String statusFilter;

  factory OwnerPriceSuggestionsState.initial() =>
      const OwnerPriceSuggestionsState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        statusFilter: 'pending',
      );

  OwnerPriceSuggestionsState copyWith({
    List<OwnerPriceSuggestionItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? statusFilter,
  }) {
    return OwnerPriceSuggestionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final ownerPriceSuggestionsControllerProvider =
    NotifierProvider.family<
      OwnerPriceSuggestionsController,
      OwnerPriceSuggestionsState,
      String
    >(OwnerPriceSuggestionsController.new);

class OwnerPriceSuggestionsController
    extends Notifier<OwnerPriceSuggestionsState> {
  OwnerPriceSuggestionsController(this.businessId);
  final String businessId;
  static const int pageSize = 20;
  int _requestId = 0;

  @override
  OwnerPriceSuggestionsState build() {
    Future.microtask(loadInitial);
    return OwnerPriceSuggestionsState.initial();
  }

  Future<bool> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return false;
    final reqId = ++_requestId;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(ownerPriceSuggestionsRepositoryProvider);
      final items = await repo.listSuggestions(
        businessId: businessId,
        status: state.statusFilter,
        limit: pageSize,
        offset: 0,
      );
      if (reqId != _requestId) return false;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
      );
      return true;
    } catch (e) {
      if (reqId != _requestId) return false;
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final reqId = _requestId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final repo = ref.read(ownerPriceSuggestionsRepositoryProvider);
      final items = await repo.listSuggestions(
        businessId: businessId,
        status: state.statusFilter,
        limit: pageSize,
        offset: state.items.length,
      );
      if (reqId != _requestId) return;
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<bool> refresh({bool force = false}) async {
    _requestId++;
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

  Future<void> approve(String suggestionId) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != suggestionId) return c;
      return _copyItem(c, status: 'approved');
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, suggestionId, 'approved');
    state = state.copyWith(items: next);
    try {
      await ref
          .read(ownerPriceSuggestionsRepositoryProvider)
          .approve(suggestionId);
      await _refreshPreservePaging();
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  Future<void> reject({
    required String suggestionId,
    required String note,
  }) async {
    final prev = state.items;
    final updated = prev.map((c) {
      if (c.id != suggestionId) return c;
      return _copyItem(c, status: 'rejected');
    }).toList();
    final next = _maybeRemoveAfterStatus(updated, suggestionId, 'rejected');
    state = state.copyWith(items: next);
    try {
      await ref
          .read(ownerPriceSuggestionsRepositoryProvider)
          .reject(suggestionId: suggestionId, note: note);
      await _refreshPreservePaging();
    } catch (e) {
      state = state.copyWith(items: prev);
      rethrow;
    }
  }

  List<OwnerPriceSuggestionItem> _maybeRemoveAfterStatus(
    List<OwnerPriceSuggestionItem> items,
    String suggestionId,
    String status,
  ) {
    if (state.statusFilter.isEmpty) return items;
    if (status == state.statusFilter) return items;
    return items.where((c) => c.id != suggestionId).toList();
  }

  Future<void> _refreshPreservePaging() async {
    if (state.isLoading) return;
    final reqId = ++_requestId;
    final limit = state.items.isEmpty ? pageSize : state.items.length;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final repo = ref.read(ownerPriceSuggestionsRepositoryProvider);
      final items = await repo.listSuggestions(
        businessId: businessId,
        status: state.statusFilter,
        limit: limit,
        offset: 0,
      );
      if (reqId != _requestId) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == limit,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

OwnerPriceSuggestionItem _copyItem(
  OwnerPriceSuggestionItem c, {
  String? status,
}) {
  return OwnerPriceSuggestionItem(
    id: c.id,
    status: status ?? c.status,
    menuItemId: c.menuItemId,
    menuItemName: c.menuItemName,
    currentPriceCents: c.currentPriceCents,
    suggestedPriceCents: c.suggestedPriceCents,
    createdAt: c.createdAt,
    ageHours: c.ageHours,
    qualityConfidence: c.qualityConfidence,
    anomalyScore: c.anomalyScore,
    anomalyFlags: c.anomalyFlags,
    conflictState: c.conflictState,
    conflictVariants24h: c.conflictVariants24h,
  );
}
