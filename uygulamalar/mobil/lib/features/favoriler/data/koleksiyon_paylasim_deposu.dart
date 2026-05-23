import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';

class CollectionShare {
  const CollectionShare({
    required this.slug,
    required this.collectionKey,
    required this.name,
    required this.businessIds,
  });

  final String slug;
  final String collectionKey;
  final String name;
  final List<String> businessIds;

  factory CollectionShare.fromMap(Map<String, dynamic> map) {
    return CollectionShare(
      slug: (map['slug'] ?? '').toString(),
      collectionKey: (map['collection_key'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      businessIds:
          (map['business_ids'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
    );
  }
}

final collectionShareRepositoryProvider = Provider<CollectionShareRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  return CollectionShareRepository(client);
});

class CollectionShareRepository {
  CollectionShareRepository(this.client);

  final SupabaseClient client;

  Future<String> upsertShare({
    required String collectionKey,
    required String name,
    required List<String> businessIds,
  }) async {
    final res = await client.rpc(
      'upsert_collection_share_v1',
      params: {
        'p_collection_key': collectionKey,
        'p_name': name,
        'p_business_ids': businessIds,
      },
    );
    if (res is List && res.isNotEmpty && res.first is Map) {
      final map = res.first as Map<String, dynamic>;
      return (map['slug'] ?? '').toString();
    }
    if (res is Map<String, dynamic>) {
      return (res['slug'] ?? '').toString();
    }
    return '';
  }

  Future<CollectionShare?> fetchBySlug(String slug) async {
    if (slug.trim().isEmpty) return null;
    final res = await client.rpc(
      'get_collection_share_by_slug_v1',
      params: {'p_slug': slug},
    );
    if (res is List && res.isNotEmpty && res.first is Map) {
      return CollectionShare.fromMap(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) {
      return CollectionShare.fromMap(res);
    }
    return null;
  }
}
