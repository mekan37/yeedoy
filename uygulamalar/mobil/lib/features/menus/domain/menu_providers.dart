import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/offline_cache_prefs.dart';
import '../data/menu_repository.dart';
import 'menu_models.dart';

final businessMenusProvider = FutureProvider.autoDispose.family<List<BusinessMenu>, String>(
  (ref, businessId) async {
    return ref.watch(menuRepositoryProvider).fetchBusinessMenus(businessId);
  },
);

final menuSectionsProvider = FutureProvider.autoDispose.family<List<MenuSection>, String>((
  ref,
  menuId,
) async {
  return ref.watch(menuRepositoryProvider).fetchMenuSections(menuId);
});

final menuItemsProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>((
  ref,
  menuId,
) async {
  final sections = await ref.watch(menuSectionsProvider(menuId).future);
  return ref
      .watch(menuRepositoryProvider)
      .fetchMenuItems(menuId, sections: sections, allowV1Fallback: true);
});

final menuItemsCacheUpdatedAtProvider =
    FutureProvider.autoDispose.family<DateTime?, String>((ref, menuId) async {
      return OfflineCachePrefs.loadMenuItemsCachedAt(menuId);
    });

final menuOfflineSavedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, menuId) async {
      return OfflineCachePrefs.isMenuSavedForOffline(menuId);
    });

/// Key: '${itemName}|${city}|${excludeBusinessId ?? ''}'
final menuItemPriceBenchmarkProvider =
    FutureProvider.autoDispose.family<MenuItemPriceBenchmark?, String>((ref, key) async {
      final parts = key.split('|');
      if (parts.length < 2) return null;
      final itemName = parts[0];
      final city = parts[1];
      final excludeId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
      return ref.watch(menuRepositoryProvider).fetchCategoryPriceBenchmark(
        itemName: itemName,
        city: city,
        excludeBusinessId: excludeId,
      );
    });
