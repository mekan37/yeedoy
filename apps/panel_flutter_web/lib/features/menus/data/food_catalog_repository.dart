import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/food_catalog_models.dart';
import 'local_food_catalog_data_source.dart';

final foodCatalogRepositoryProvider = Provider<FoodCatalogRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FoodCatalogRepository(client, const LocalFoodCatalogDataSource());
});

class FoodCatalogRepository {
  FoodCatalogRepository(this.client, this._local);
  final SupabaseClient client;
  final LocalFoodCatalogDataSource _local;

  Future<List<FoodCatalogHit>> search(String query, {int limit = 12}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    try {
      final res = await client.rpc(
        'search_food_catalog_v1',
        params: {'p_q': trimmed, 'p_limit': limit},
      );
      final remote = (res as List)
          .map(
            (row) =>
                FoodCatalogHit.fromMap((row as Map).cast<String, dynamic>()),
          )
          .toList();
      if (remote.length >= limit) return remote;

      final local = await _local.search(trimmed, limit: limit);
      final seen = remote.map((e) => e.name.toLowerCase()).toSet();
      final merged = [...remote];
      for (final hit in local) {
        if (seen.contains(hit.name.toLowerCase())) continue;
        merged.add(hit);
        if (merged.length >= limit) break;
      }
      return merged;
    } catch (e) {
      final local = await _local.search(trimmed, limit: limit);
      if (local.isNotEmpty) return local;
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<void> bump(int id) async {
    try {
      await client.rpc('bump_food_catalog_popularity_v1', params: {'p_id': id});
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
