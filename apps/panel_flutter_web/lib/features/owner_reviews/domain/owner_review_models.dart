class OwnerReviewItem {
  OwnerReviewItem({
    required this.id,
    required this.rating,
    this.title,
    required this.content,
    required this.helpfulCount,
    required this.qualityScore,
    required this.createdAt,
    required this.status,
    this.replyId,
    this.replyContent,
    this.replyAt,
  });

  final String id;
  final int rating;
  final String? title;
  final String content;
  final int helpfulCount;
  final double qualityScore;
  final DateTime createdAt;
  final String status;
  final String? replyId;
  final String? replyContent;
  final DateTime? replyAt;

  bool get hasReply => replyId != null;

  factory OwnerReviewItem.fromMap(Map<String, dynamic> m) => OwnerReviewItem(
    id: m['id'] as String,
    rating: m['rating'] as int,
    title: m['title'] as String?,
    content: m['content'] as String,
    helpfulCount: (m['helpful_count'] as int?) ?? 0,
    qualityScore: (m['quality_score'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
    status: m['status'] as String,
    replyId: m['reply_id'] as String?,
    replyContent: m['reply_content'] as String?,
    replyAt: m['reply_at'] != null
        ? DateTime.parse(m['reply_at'] as String)
        : null,
  );

  OwnerReviewItem withReply({
    required String replyId,
    required String replyContent,
    required DateTime replyAt,
  }) => OwnerReviewItem(
    id: id,
    rating: rating,
    title: title,
    content: content,
    helpfulCount: helpfulCount,
    qualityScore: qualityScore,
    createdAt: createdAt,
    status: status,
    replyId: replyId,
    replyContent: replyContent,
    replyAt: replyAt,
  );

  OwnerReviewItem withoutReply() => OwnerReviewItem(
    id: id,
    rating: rating,
    title: title,
    content: content,
    helpfulCount: helpfulCount,
    qualityScore: qualityScore,
    createdAt: createdAt,
    status: status,
  );
}

class OwnerReviewsState {
  const OwnerReviewsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.sort = 'newest',
    this.hasMore = true,
  });

  final List<OwnerReviewItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final String sort;
  final bool hasMore;

  OwnerReviewsState copyWith({
    List<OwnerReviewItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    String? sort,
    bool? hasMore,
  }) => OwnerReviewsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error,
    sort: sort ?? this.sort,
    hasMore: hasMore ?? this.hasMore,
  );
}
