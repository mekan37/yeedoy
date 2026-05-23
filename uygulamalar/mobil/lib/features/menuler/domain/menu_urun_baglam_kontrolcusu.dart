import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/menu_urun_baglam_deposu.dart';
import 'menu_urun_baglam.dart';

final menuItemContextProvider =
    AsyncNotifierProvider.family<MenuItemContextController, MenuItemContext, String>(
  MenuItemContextController.new,
);

class MenuItemContextController extends AsyncNotifier<MenuItemContext> {
  MenuItemContextController(this.menuItemId);
  final String menuItemId;

  int _requestId = 0;

  @override
  Future<MenuItemContext> build() async {
    return _load();
  }

  Future<void> refresh({bool force = false}) async {
    final reqId = ++_requestId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ref
          .read(menuItemContextRepositoryProvider)
          .fetchMenuItemContext(menuItemId, force: force);
      if (reqId != _requestId) return data;
      return data;
    });
  }

  Future<MenuItemContext> _load({bool force = false}) async {
    final reqId = ++_requestId;
    final data = await ref
        .read(menuItemContextRepositoryProvider)
        .fetchMenuItemContext(menuItemId, force: force);
    if (reqId != _requestId) return data;
    return data;
  }
}

