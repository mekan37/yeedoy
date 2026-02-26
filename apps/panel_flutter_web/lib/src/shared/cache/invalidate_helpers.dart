import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/menus/domain/menu_item_context_controller.dart';
import '../../../features/menus/domain/menu_controllers.dart';
import '../../../features/menus/domain/menu_providers.dart';

void invalidateMenu(WidgetRef ref, {required String businessId, required String menuId}) {
  if (businessId.isNotEmpty) {
    ref.invalidate(businessMenusProvider(businessId));
  }
  if (menuId.isNotEmpty) {
    ref.invalidate(menuSectionsProvider(menuId));
    ref.invalidate(menuItemsProvider(menuId));
  }
}

void invalidateSection(WidgetRef ref, {required String menuId, required String sectionId}) {
  if (menuId.isNotEmpty) {
    ref.invalidate(menuSectionsProvider(menuId));
    ref.invalidate(menuItemsProvider(menuId));
  }
}

void invalidateItem(WidgetRef ref, {required String itemId, required String sectionId}) {
  if (itemId.isNotEmpty) {
    ref.invalidate(menuItemContextProvider(itemId));
    ref.invalidate(menuItemPriceStatusProvider(itemId));
    ref.invalidate(menuItemPriceHistoryProvider(itemId));
  }
}
