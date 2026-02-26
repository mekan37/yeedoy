// ignore_for_file: deprecated_member_use

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';
import '../data/gourmet_repository.dart';
import '../data/feed_repository.dart';
import 'gourmet_user.dart';
import 'gourmet_states.dart';

final gourmetDiscoverProvider =
    NotifierProvider<GourmetDiscoverController, GourmetListState>(GourmetDiscoverController.new);
final gourmetFollowingProvider =
    NotifierProvider<GourmetFollowingController, GourmetListState>(GourmetFollowingController.new);
final feedProvider = NotifierProvider<FeedController, FeedState>(FeedController.new);
final followControllerProvider = NotifierProvider<FollowController, void>(FollowController.new);

class GourmetDiscoverController extends Notifier<GourmetListState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;

  @override
  GourmetListState build() {
    Future.microtask(loadInitial);
    return GourmetListState.initial();
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(loading: true, isLoadingMore: false, items: [], hasMore: true, error: null);
    try {
      final list = await ref.read(gourmetRepositoryProvider).discover(
            limit: pageSize,
            offset: 0,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(
        loading: false,
        items: list,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.isLoadingMore || !state.hasMore) return;
    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final list = await ref.read(gourmetRepositoryProvider).discover(
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

  Future<void> toggleFollow(GourmetUser user) async {
    final current = state.items;
    final idx = current.indexWhere((u) => u.id == user.id);
    if (idx == -1) return;
    final updated = [...current];
    final nowFollowing = !user.isFollowing;
    updated[idx] = user.copyWith(
      isFollowing: nowFollowing,
      followerCount: (user.followerCount + (nowFollowing ? 1 : -1)).clamp(0, 1 << 30),
    );
    state = state.copyWith(items: updated);
    try {
      await ref.read(followControllerProvider.notifier).toggle(user.id);
    } catch (e) {
      state = state.copyWith(items: current);
      rethrow;
    }
  }
}

class GourmetFollowingController extends Notifier<GourmetListState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;

  @override
  GourmetListState build() {
    Future.microtask(loadInitial);
    return GourmetListState.initial();
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(loading: true, isLoadingMore: false, items: [], hasMore: true, error: null);
    try {
      final list = await ref.read(gourmetRepositoryProvider).getMyFollowing(
            limit: pageSize,
            offset: 0,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(
        loading: false,
        items: list,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.isLoadingMore || !state.hasMore) return;
    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final list = await ref.read(gourmetRepositoryProvider).getMyFollowing(
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

  Future<void> toggleFollow(GourmetUser user) async {
    final current = state.items;
    final idx = current.indexWhere((u) => u.id == user.id);
    if (idx == -1) return;
    final updated = [...current];
    final nowFollowing = !user.isFollowing;
    if (nowFollowing) {
      updated[idx] = user.copyWith(
        isFollowing: true,
        followerCount: user.followerCount + 1,
      );
    } else {
      updated.removeAt(idx);
    }
    state = state.copyWith(items: updated);
    try {
      await ref.read(followControllerProvider.notifier).toggle(user.id);
    } catch (e) {
      state = state.copyWith(items: current);
      rethrow;
    }
  }
}

class FeedController extends Notifier<FeedState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;

  @override
  FeedState build() {
    Future.microtask(loadInitial);
    return FeedState.initial();
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(loading: true, isLoadingMore: false, items: [], hasMore: true, error: null);
    try {
      final list = await ref.read(feedRepositoryProvider).getMyFeed(
            limit: pageSize,
            offset: 0,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(
        loading: false,
        items: list,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.isLoadingMore || !state.hasMore) return;
    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final list = await ref.read(feedRepositoryProvider).getMyFeed(
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
}

class FollowController extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle(String followeeId) async {
    await ref.read(followRepositoryProvider).toggleFollow(followeeId);
  }
}
