import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../discovery/domain/business_card.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return FavoritesRepository(client);
});

class PaginatedFavorites {
  const PaginatedFavorites({required this.ids, required this.items});

  final List<String> ids;
  final List<BusinessCardModel> items;
}

class FavoritesRepository {
  FavoritesRepository(this.client);
  final SupabaseClient client;

  static const String _businessSelect =
      'id,name,category,address,city,district,lat,lng,is_open_now,recent_price_verified_count';

  Future<bool> toggleFavorite(String businessId) async {
    final res = await client.rpc(
      'toggle_favorite_v1',
      params: {'p_business_id': businessId},
    );
    if (res is Map && res['is_favorited'] is bool) {
      return res['is_favorited'] as bool;
    }
    if (res is List && res.isNotEmpty) {
      final first = res.first;
      if (first is Map && first['is_favorited'] is bool) {
        return first['is_favorited'] as bool;
      }
    }
    if (res is bool) return res;
    throw Exception('Favori islemi basarisiz.');
  }

  Future<bool> isFavorited(String businessId) async {
    final res = await client
        .from('favorites')
        .select('business_id')
        .eq('business_id', businessId)
        .maybeSingle();
    return res != null;
  }

  Future<BusinessCardModel?> getBusinessById(String businessId) async {
    final res = await client
        .from('businesses_with_stats')
        .select(_businessSelect)
        .eq('id', businessId)
        .maybeSingle();
    if (res == null) return null;
    return BusinessCardModel.fromMap(res);
  }

  Future<List<BusinessCardModel>> getBusinessesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final businesses = await client
        .from('businesses_with_stats')
        .select(_businessSelect)
        .inFilter('id', ids);
    final byId = <String, BusinessCardModel>{};
    for (final row in (businesses as List)) {
      final model = BusinessCardModel.fromMap(row as Map<String, dynamic>);
      byId[model.id] = model;
    }
    final ordered = <BusinessCardModel>[];
    for (final id in ids) {
      final item = byId[id];
      if (item != null) ordered.add(item);
    }
    return ordered;
  }

  Future<List<String>> getMyFavoriteBusinessIds({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await client.rpc(
      'get_my_favorites_v1',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return (res as List)
        .map((e) => (e as Map<String, dynamic>)['business_id'] as String)
        .toList();
  }

  Future<PaginatedFavorites> getMyFavoritesWithBusinesses({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await client.rpc(
      'get_my_favorites_v1',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    final rows = (res as List).cast<Map<String, dynamic>>();
    final ids = rows.map((e) => e['business_id'] as String).toList();

    if (ids.isEmpty) {
      return const PaginatedFavorites(ids: [], items: []);
    }

    final businesses = await client
        .from('businesses_with_stats')
        .select(_businessSelect)
        .inFilter('id', ids);

    final byId = <String, BusinessCardModel>{};
    for (final row in (businesses as List)) {
      final model = BusinessCardModel.fromMap(row as Map<String, dynamic>);
      byId[model.id] = model;
    }

    final ordered = <BusinessCardModel>[];
    for (final id in ids) {
      final item = byId[id];
      if (item != null) ordered.add(item);
    }

    final page = PaginatedFavorites(ids: ids, items: ordered);
    if (offset == 0) {
      await OfflineCachePrefs.saveFavoriteIds(ids);
      await OfflineCachePrefs.saveFavoriteBusinesses(
        ordered.map((e) => e.toMap()).toList(),
      );
    }
    return page;
  }

  Future<PaginatedFavorites?> getCachedFavorites() async {
    final ids = await OfflineCachePrefs.loadFavoriteIds();
    final rows = await OfflineCachePrefs.loadFavoriteBusinesses();
    if (ids.isEmpty || rows == null || rows.isEmpty) return null;
    final items = rows.map(BusinessCardModel.fromMap).toList();
    return PaginatedFavorites(ids: ids, items: items);
  }
}
