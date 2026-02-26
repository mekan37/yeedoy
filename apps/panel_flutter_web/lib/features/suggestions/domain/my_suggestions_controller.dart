import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/my_suggestions_repository.dart';
import 'suggestion.dart';

class MySuggestionsPagingState {
  const MySuggestionsPagingState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
  });

  final List<BusinessSuggestion> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  factory MySuggestionsPagingState.initial() => const MySuggestionsPagingState(
        items: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
      );

  MySuggestionsPagingState copyWith({
    List<BusinessSuggestion>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return MySuggestionsPagingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

final mySuggestionsControllerProvider =
    NotifierProvider<MySuggestionsController, MySuggestionsPagingState>(
        MySuggestionsController.new);

class MySuggestionsController extends Notifier<MySuggestionsPagingState> {
  static const int pageSize = 20;

  @override
  MySuggestionsPagingState build() {
    final user = ref.watch(userProvider);
    if (user == null) {
      return MySuggestionsPagingState.initial().copyWith(hasMore: false);
    }
    Future.microtask(loadInitial);
    return MySuggestionsPagingState.initial();
  }

  Future<void> loadInitial() async {
    final user = ref.read(userProvider);
    if (user == null || state.isLoading) return;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);

    try {
      final repo = ref.read(mySuggestionsRepositoryProvider);
      final list = await repo.getMySuggestions(
        userId: user.id,
        limit: pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: list,
        isLoading: false,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    final user = ref.read(userProvider);
    if (user == null || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final repo = ref.read(mySuggestionsRepositoryProvider);
      final list = await repo.getMySuggestions(
        userId: user.id,
        limit: pageSize,
        offset: state.items.length,
      );
      state = state.copyWith(
        items: [...state.items, ...list],
        isLoadingMore: false,
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    await loadInitial();
  }
}
