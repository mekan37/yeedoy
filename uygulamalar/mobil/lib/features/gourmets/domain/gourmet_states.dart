import 'gourmet_user.dart';
import 'feed_item.dart';

class GourmetListState {
  const GourmetListState({
    required this.items,
    required this.loading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
  });

  final List<GourmetUser> items;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  factory GourmetListState.initial() => const GourmetListState(
        items: [],
        loading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
      );

  GourmetListState copyWith({
    List<GourmetUser>? items,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return GourmetListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class FeedState {
  const FeedState({
    required this.items,
    required this.loading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
  });

  final List<FeedItem> items;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  factory FeedState.initial() => const FeedState(
        items: [],
        loading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
      );

  FeedState copyWith({
    List<FeedItem>? items,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return FeedState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}
