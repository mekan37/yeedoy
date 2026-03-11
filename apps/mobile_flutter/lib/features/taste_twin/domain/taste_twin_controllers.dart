// ignore_for_file: deprecated_member_use

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/taste_twin_repository.dart';
import 'taste_twin_models.dart';

final tasteMatchesProvider =
    NotifierProvider<TasteMatchesController, TasteMatchesState>(TasteMatchesController.new);
final tasteRecommendationsProvider =
    AsyncNotifierProvider.family<TasteRecommendationsController, List<TasteRecommendation>, String>(
  TasteRecommendationsController.new,
);
final tasteOverlapProvider =
    AsyncNotifierProvider.family<TasteOverlapController, List<TasteOverlapExample>, String>(
  TasteOverlapController.new,
);
final tasteSignalOverlapProvider = AsyncNotifierProvider.family<TasteSignalOverlapController,
    List<TasteSignalOverlapExample>, String>(
  TasteSignalOverlapController.new,
);
final tasteDivergenceProvider =
    AsyncNotifierProvider.family<TasteDivergenceController, List<TasteDivergenceExample>, String>(
  TasteDivergenceController.new,
);
final publicProfileProvider = FutureProvider.family<PublicProfile, String>((ref, userId) {
  return ref.read(tasteTwinRepositoryProvider).getUserPublicProfile(userId);
});

class TasteMatchesState {
  const TasteMatchesState({
    required this.items,
    required this.loading,
    this.error,
  });

  final List<TasteMatch> items;
  final bool loading;
  final Object? error;

  factory TasteMatchesState.initial() => const TasteMatchesState(
        items: [],
        loading: false,
        error: null,
      );

  TasteMatchesState copyWith({
    List<TasteMatch>? items,
    bool? loading,
    Object? error,
  }) {
    return TasteMatchesState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class TasteMatchesController extends Notifier<TasteMatchesState> {
  int _requestId = 0;

  @override
  TasteMatchesState build() {
    Future.microtask(loadInitial);
    return TasteMatchesState.initial();
  }

  Future<void> loadInitial({bool force = false}) async {
    final reqId = ++_requestId;
    state = state.copyWith(loading: true, items: [], error: null);
    try {
      final list = await ref.read(tasteTwinRepositoryProvider).getMatches(
            limit: 20,
            minOverlap: 3,
            force: force,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, items: list);
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }
}

class TasteRecommendationsController extends AsyncNotifier<List<TasteRecommendation>> {
  TasteRecommendationsController(this.matchUserId);
  final String matchUserId;

  int _requestId = 0;

  @override
  Future<List<TasteRecommendation>> build() async {
    return _load();
  }

  Future<void> refresh({bool force = false}) async {
    final reqId = ++_requestId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref
          .read(tasteTwinRepositoryProvider)
          .getRecommendations(matchUserId: matchUserId, force: force);
      if (reqId != _requestId) return data;
      return data;
    });
  }

  Future<List<TasteRecommendation>> _load() async {
    final reqId = ++_requestId;
    final data = await ref
        .read(tasteTwinRepositoryProvider)
        .getRecommendations(matchUserId: matchUserId);
    if (reqId != _requestId) return data;
    return data;
  }
}

class TasteOverlapController extends AsyncNotifier<List<TasteOverlapExample>> {
  TasteOverlapController(this.otherUserId);
  final String otherUserId;

  int _requestId = 0;

  @override
  Future<List<TasteOverlapExample>> build() async {
    return _load();
  }

  Future<void> refresh({bool force = false}) async {
    final reqId = ++_requestId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref
          .read(tasteTwinRepositoryProvider)
          .getOverlapExamples(
            otherUserId: otherUserId,
            limit: 5,
            force: force,
          );
      if (reqId != _requestId) return data;
      return data;
    });
  }

  Future<List<TasteOverlapExample>> _load() async {
    final reqId = ++_requestId;
    final data = await ref
        .read(tasteTwinRepositoryProvider)
        .getOverlapExamples(otherUserId: otherUserId, limit: 5);
    if (reqId != _requestId) return data;
    return data;
  }
}

class TasteDivergenceController extends AsyncNotifier<List<TasteDivergenceExample>> {
  TasteDivergenceController(this.otherUserId);
  final String otherUserId;

  int _requestId = 0;

  @override
  Future<List<TasteDivergenceExample>> build() async {
    return _load();
  }

  Future<void> refresh({bool force = false}) async {
    final reqId = ++_requestId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref
          .read(tasteTwinRepositoryProvider)
          .getDivergenceExamples(
            otherUserId: otherUserId,
            limit: 3,
            force: force,
          );
      if (reqId != _requestId) return data;
      return data;
    });
  }

  Future<List<TasteDivergenceExample>> _load() async {
    final reqId = ++_requestId;
    final data = await ref
        .read(tasteTwinRepositoryProvider)
        .getDivergenceExamples(otherUserId: otherUserId, limit: 3);
    if (reqId != _requestId) return data;
    return data;
  }
}

class TasteSignalOverlapController extends AsyncNotifier<List<TasteSignalOverlapExample>> {
  TasteSignalOverlapController(this.otherUserId);
  final String otherUserId;

  int _requestId = 0;

  @override
  Future<List<TasteSignalOverlapExample>> build() async {
    return _load();
  }

  Future<void> refresh({bool force = false}) async {
    final reqId = ++_requestId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref
          .read(tasteTwinRepositoryProvider)
          .getSignalOverlapExamples(
            otherUserId: otherUserId,
            limit: 5,
            force: force,
          );
      if (reqId != _requestId) return data;
      return data;
    });
  }

  Future<List<TasteSignalOverlapExample>> _load() async {
    final reqId = ++_requestId;
    final data = await ref
        .read(tasteTwinRepositoryProvider)
        .getSignalOverlapExamples(otherUserId: otherUserId, limit: 5);
    if (reqId != _requestId) return data;
    return data;
  }
}
