import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_reviews_repository.dart';
import 'owner_review_models.dart';

final ownerReviewsControllerProvider = NotifierProvider.family<
    OwnerReviewsController, OwnerReviewsState, String>(
  OwnerReviewsController.new,
);

class OwnerReviewsController extends Notifier<OwnerReviewsState> {
  OwnerReviewsController(this.businessId);
  final String businessId;
  static const _pageSize = 20;

  @override
  OwnerReviewsState build() {
    Future.microtask(_loadInitial);
    return const OwnerReviewsState();
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, items: []);
    try {
      final rows = await _repo.listReviews(
        businessId: businessId,
        sort: state.sort,
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: rows,
        isLoading: false,
        hasMore: rows.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null, items: [], hasMore: true);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final rows = await _repo.listReviews(
        businessId: businessId,
        sort: state.sort,
        limit: _pageSize,
        offset: state.items.length,
      );
      state = state.copyWith(
        items: [...state.items, ...rows],
        isLoadingMore: false,
        hasMore: rows.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort);
    Future.microtask(() async {
      state = state.copyWith(isLoading: true, error: null, items: []);
      try {
        final rows = await _repo.listReviews(
          businessId: businessId,
          sort: sort,
          limit: _pageSize,
          offset: 0,
        );
        state = state.copyWith(
          items: rows,
          isLoading: false,
          hasMore: rows.length == _pageSize,
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e);
      }
    });
  }

  Future<String?> submitReply({
    required String reviewId,
    required String content,
  }) async {
    try {
      final replyId = await _repo.submitReply(
        reviewId: reviewId,
        content: content,
      );
      state = state.copyWith(
        items: state.items.map((r) {
          if (r.id != reviewId) return r;
          return r.withReply(
            replyId: replyId,
            replyContent: content,
            replyAt: DateTime.now(),
          );
        }).toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteReply({required String reviewId}) async {
    try {
      await _repo.deleteReply(reviewId: reviewId);
      state = state.copyWith(
        items: state.items
            .map((r) => r.id == reviewId ? r.withoutReply() : r)
            .toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  OwnerReviewsRepository get _repo => ref.read(ownerReviewsRepositoryProvider);
}
