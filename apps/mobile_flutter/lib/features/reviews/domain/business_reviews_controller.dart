import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reviews_repository.dart';
import 'review.dart';

class BusinessReviewsState {
  const BusinessReviewsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.sort,
    required this.error,
  });

  final List<Review> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String sort;
  final Object? error;

  factory BusinessReviewsState.initial(String sort) => BusinessReviewsState(
        items: const [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        sort: sort,
        error: null,
      );

  BusinessReviewsState copyWith({
    List<Review>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? sort,
    Object? error,
  }) {
    return BusinessReviewsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      error: error,
    );
  }
}

final businessReviewsProvider = NotifierProvider.family<BusinessReviewsController, BusinessReviewsState, String>(
  BusinessReviewsController.new,
);

class BusinessReviewsController extends Notifier<BusinessReviewsState> {
  BusinessReviewsController(this.businessId);
  final String businessId;
  static const int pageSize = 20;

  int _requestId = 0;
  int _loadMoreId = 0;

  @override
  BusinessReviewsState build() {
    Future.microtask(loadInitial);
    return BusinessReviewsState.initial('newest');
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      items: [],
      hasMore: true,
      error: null,
    );

    try {
      final repo = ref.read(reviewsRepositoryProvider);
      final list = await repo.getBusinessReviews(
        businessId: businessId,
        sort: state.sort,
        limit: pageSize,
        offset: 0,
      );
      if (reqId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        items: list,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repo = ref.read(reviewsRepositoryProvider);
      final list = await repo.getBusinessReviews(
        businessId: businessId,
        sort: state.sort,
        limit: pageSize,
        offset: state.items.length,
      );
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...list],
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> setSort(String sort) async {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    await loadInitial();
  }
}

