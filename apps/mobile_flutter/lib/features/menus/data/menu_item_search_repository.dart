import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/menu_item_search_model.dart';

final menuItemSearchRepositoryProvider = Provider<MenuItemSearchRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MenuItemSearchRepository(client);
});

class MenuItemSearchRepository {
  MenuItemSearchRepository(this.client);
  final SupabaseClient client;

  Future<List<MenuItemSearchResult>> searchMenuItems({
    required double userLat,
    required double userLng,
    required int radiusKm,
    required String query,
    required bool vegan,
    required bool vegetarian,
    required bool glutenFree,
    required bool lactoseFree,
    required bool halal,
    required int? maxCalories,
    required bool verifiedPriceOnly,
    required int limit,
    required int offset,
  }) async {
    try {
      final res = await client.rpc('search_menu_items_v1', params: {
        'p_user_lat': userLat,
        'p_user_lng': userLng,
        'p_radius_km': radiusKm.toDouble(),
        'p_q': query.trim().isEmpty ? null : query.trim(),
        'p_is_vegan': vegan,
        'p_is_vegetarian': vegetarian,
        'p_is_gluten_free': glutenFree,
        'p_is_lactose_free': lactoseFree,
        'p_is_halal': halal,
        'p_max_calories': maxCalories,
        'p_verified_price_only': verifiedPriceOnly,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (res as List)
          .map((row) => MenuItemSearchResult.fromMap((row as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }

  Future<MenuItemSearchResult?> pickOneMenuItem({
    required double userLat,
    required double userLng,
    required int radiusKm,
  }) async {
    try {
      final res = await client.rpc('pick_one_menu_item_v1', params: {
        'p_user_lat': userLat,
        'p_user_lng': userLng,
        'p_radius_km': radiusKm,
      });
      if (res == null) return null;
      return MenuItemSearchResult.fromMap((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
