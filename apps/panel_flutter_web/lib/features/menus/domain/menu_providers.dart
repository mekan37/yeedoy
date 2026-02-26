import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/offline_cache_prefs.dart';
import '../data/menu_repository.dart';
import 'menu_models.dart';

final businessMenusProvider = FutureProvider.family<List<BusinessMenu>, String>(
  (ref, businessId) async {
    return ref.watch(menuRepositoryProvider).getBusinessMenus(businessId);
  },
);

final menuSectionsProvider = FutureProvider.family<List<MenuSection>, String>((
  ref,
  menuId,
) async {
  return ref.watch(menuRepositoryProvider).getMenuSections(menuId);
});

final menuItemsProvider = FutureProvider.family<List<MenuItem>, String>((
  ref,
  menuId,
) async {
  final sections = await ref.watch(menuSectionsProvider(menuId).future);
  return ref
      .watch(menuRepositoryProvider)
      .getMenuItems(menuId, sections: sections, allowV1Fallback: true);
});

final businessPriceTrustProvider =
    FutureProvider.family<BusinessPriceTrust, String>((ref, businessId) async {
      return ref
          .watch(menuRepositoryProvider)
          .getBusinessPriceTrust(businessId);
    });

final menuItemsCacheUpdatedAtProvider =
    FutureProvider.family<DateTime?, String>((ref, menuId) async {
      return OfflineCachePrefs.loadMenuItemsCachedAt(menuId);
    });
