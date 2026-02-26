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

  Future<MenuItemContext> getMenuItemContext(
    String menuItemId, {
    bool force = false,
  }) async {
    final cached = _cache[menuItemId];
    if (!force && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _ttl) return cached.data;
    }
    try {
      final res = await client.rpc('get_menu_item_context_v1', params: {
        'p_menu_item_id': menuItemId,
      });
      final context = MenuItemContext.fromMap((res as Map).cast<String, dynamic>());
      _cache[menuItemId] = _CacheEntry(data: context, fetchedAt: DateTime.now());
      return context;
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
