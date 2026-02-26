import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';

class CollectionSocialState {
  const CollectionSocialState({
    required this.followers,
    required this.engagement,
    required this.isFollowing,
  });

  final int followers;
  final int engagement;
  final bool isFollowing;

  CollectionSocialState copyWith({
    int? followers,
    int? engagement,
    bool? isFollowing,
  }) {
    return CollectionSocialState(
      followers: followers ?? this.followers,
      engagement: engagement ?? this.engagement,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  factory CollectionSocialState.fromMap(Map<String, dynamic> map) {
    return CollectionSocialState(
      followers: (map['followers_count'] as num?)?.toInt() ?? 0,
      engagement: (map['engagement_count'] as num?)?.toInt() ?? 0,
      isFollowing: (map['is_following'] as bool?) ?? false,
    );
  }
}

final collectionSocialRepositoryProvider = Provider<CollectionSocialRepository>(
  (ref) {
    final client = ref.watch(supabaseProvider);
    return CollectionSocialRepository(client);
  },
);

class CollectionSocialRepository {
  CollectionSocialRepository(this.client);

  final SupabaseClient client;

  Future<Map<String, CollectionSocialState>> getStats(List<String> keys) async {
    if (keys.isEmpty) return {};
    final res = await client.rpc(
      'get_collection_social_batch_v1',
      params: {'p_keys': keys},
    );
    final out = <String, CollectionSocialState>{};
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final key = (row['collection_key'] ?? '').toString();
      if (key.isEmpty) continue;
      out[key] = CollectionSocialState.fromMap(row);
    }
    return out;
  }

  Future<CollectionSocialState> toggleFollow(String key) async {
    final res = await client.rpc(
      'toggle_collection_follow_v1',
      params: {'p_collection_key': key},
    );
    if (res is List && res.isNotEmpty && res.first is Map) {
      final map = res.first as Map<String, dynamic>;
      return CollectionSocialState(
        followers: (map['followers_count'] as num?)?.toInt() ?? 0,
        engagement: 0,
        isFollowing: (map['is_following'] as bool?) ?? false,
      );
    }
    if (res is Map<String, dynamic>) {
      return CollectionSocialState(
        followers: (res['followers_count'] as num?)?.toInt() ?? 0,
        engagement: 0,
        isFollowing: (res['is_following'] as bool?) ?? false,
      );
    }
    return const CollectionSocialState(
      followers: 0,
      engagement: 0,
      isFollowing: false,
    );
  }

  Future<int> bumpEngagement(String key, {int delta = 1}) async {
    final res = await client.rpc(
      'bump_collection_engagement_v1',
      params: {'p_collection_key': key, 'p_delta': delta},
    );
    if (res is List && res.isNotEmpty && res.first is Map) {
      final map = res.first as Map<String, dynamic>;
      return (map['engagement_count'] as num?)?.toInt() ?? 0;
    }
    if (res is Map<String, dynamic>) {
      return (res['engagement_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
