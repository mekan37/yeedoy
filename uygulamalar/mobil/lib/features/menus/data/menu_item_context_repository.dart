import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/network/supabase_provider.dart';
import '../domain/menu_item_context.dart';

final menuItemContextRepositoryProvider = Provider<MenuItemContextRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return MenuItemContextRepository(client);
});

class _CacheEntry {
  const _CacheEntry({required this.data, required this.fetchedAt});
  final MenuItemContext data;
  final DateTime fetchedAt;
}

class MenuItemContextRepository {
  MenuItemContextRepository(this.client);
  final SupabaseClient client;

  static const Duration _ttl = Duration(minutes: 10);
  static final Map<String, _CacheEntry> _cache = {};

  Future<MenuItemContext> fetchMenuItemContext(
    String menuItemId, {
    bool force = false,
  }) async {
    final cached = _cache[menuItemId];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.data;
    }
    try {
      final results = await Future.wait<dynamic>([
        client.rpc('get_menu_item_context_v1', params: {
          'p_menu_item_id': menuItemId,
        }),
        client
            .from('menu_item_allergens')
            .select('allergen')
            .eq('item_id', menuItemId),
        client
            .from('menu_items')
            .select('calories_min, portion_size, portion_unit')
            .eq('id', menuItemId)
            .maybeSingle(),
        client
            .from('menu_item_ingredients')
            .select('name')
            .eq('item_id', menuItemId)
            .order('sort_order'),
      ]);
      final context = MenuItemContext.fromMap(
        (results[0] as Map).cast<String, dynamic>(),
      );
      final allergens = (results[1] as List)
          .map((r) => (r as Map<dynamic, dynamic>)['allergen'] as String)
          .toList();
      final nutritionRow = results[2] as Map<dynamic, dynamic>?;
      final caloriesMin = nutritionRow?['calories_min'] as int?;
      final portionSizeRaw = nutritionRow?['portion_size'] as int?;
      final portionUnitRaw =
          (nutritionRow?['portion_unit'] as String? ?? '').trim();
      final portionSize = portionSizeRaw != null
          ? portionUnitRaw.isNotEmpty
                ? '$portionSizeRaw $portionUnitRaw'
                : '$portionSizeRaw'
          : null;
      final ingredients = (results[3] as List)
          .map((r) => (r as Map<dynamic, dynamic>)['name'] as String)
          .toList();
      final enriched = context.copyWith(
        allergens: allergens,
        caloriesMin: caloriesMin,
        portionSize: portionSize,
        ingredients: ingredients,
      );
      _cache[menuItemId] = _CacheEntry(
        data: enriched,
        fetchedAt: DateTime.now(),
      );
      return enriched;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
