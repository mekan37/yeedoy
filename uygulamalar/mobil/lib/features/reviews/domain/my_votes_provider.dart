import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repository.dart';

final myVotesProvider = FutureProvider.autoDispose.family<Set<String>, MyVotesKey>((ref, key) async {
  if (key.userId.isEmpty) return <String>{};
  final ids = key.reviewIdsKey.isEmpty ? <String>[] : key.reviewIdsKey.split(',');
  return ref.read(reviewsRepositoryProvider).listMyVotedReviewIds(
        userId: key.userId,
        reviewIds: ids,
      );
});

class MyVotesKey {
  const MyVotesKey({
    required this.userId,
    required this.reviewIdsKey,
  });

  final String userId;        // auth uid
  final String reviewIdsKey;  // "id1,id2,id3"

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyVotesKey && runtimeType == other.runtimeType && userId == other.userId && reviewIdsKey == other.reviewIdsKey;

  @override
  int get hashCode => Object.hash(userId, reviewIdsKey);
}

