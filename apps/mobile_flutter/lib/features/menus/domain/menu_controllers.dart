import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_provider.dart';
import '../data/menu_repository.dart';
import '../data/wp_upload.dart';
import 'menu_models.dart';

final menuItemPhotosProvider =
    AsyncNotifierProvider.family<
      MenuItemPhotosController,
      List<MenuItemPhoto>,
      String
    >(MenuItemPhotosController.new);

class MenuItemPhotosController extends AsyncNotifier<List<MenuItemPhoto>> {
  MenuItemPhotosController(this.menuItemId);
  final String menuItemId;

  @override
  Future<List<MenuItemPhoto>> build() async {
    return ref.read(menuRepositoryProvider).getMenuItemPhotos(menuItemId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(menuRepositoryProvider).getMenuItemPhotos(menuItemId);
    });
  }

  Future<void> votePhoto({required String photoId, required int vote}) async {
    final current = state.value ?? const <MenuItemPhoto>[];
    final index = current.indexWhere((photo) => photo.id == photoId);
    if (index == -1) return;
    final updated = [...current];
    updated[index] = updated[index].withVote(vote);
    state = AsyncValue.data(updated);

    try {
      await ref
          .read(menuRepositoryProvider)
          .voteMenuItemPhoto(photoId: photoId, vote: vote);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<WpUploadResult?> uploadAndAddPhoto() async {
    final client = ref.read(supabaseProvider);
    final upload = await pickAndUploadWpImage(
      client: client,
      title: 'menu_item_$menuItemId',
      menuItemId: menuItemId,
    );
    if (upload == null) return null;

    await ref
        .read(menuRepositoryProvider)
        .addMenuItemPhoto(
          menuItemId: menuItemId,
          url: upload.url,
          urlLarge: upload.urlLarge,
          urlThumb: upload.urlThumb,
          provider: 'supabase_storage',
        );

    await refresh(force: true);
    return upload;
  }
}

final menuItemPriceStatusProvider =
    AsyncNotifierProvider.family<
      MenuItemPriceStatusController,
      MenuItemPriceStatus,
      String
    >(MenuItemPriceStatusController.new);

final menuItemValueScoreProvider =
    AsyncNotifierProvider.family<
      MenuItemValueScoreController,
      MenuItemValueScore,
      String
    >(MenuItemValueScoreController.new);

final menuItemPriceHistoryProvider =
    AsyncNotifierProvider.family<
      MenuItemPriceHistoryController,
      List<MenuItemPriceHistoryEntry>,
      String
    >(MenuItemPriceHistoryController.new);

class MenuItemPriceStatusController extends AsyncNotifier<MenuItemPriceStatus> {
  MenuItemPriceStatusController(this.menuItemId);
  final String menuItemId;

  @override
  Future<MenuItemPriceStatus> build() async {
    return ref.read(menuRepositoryProvider).getMenuItemPriceStatus(menuItemId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(menuRepositoryProvider)
          .getMenuItemPriceStatus(menuItemId);
    });
  }

  Future<void> votePrice({required int vote}) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.withVote(vote));
    }
    try {
      await ref
          .read(menuRepositoryProvider)
          .voteMenuItemPrice(menuItemId: menuItemId, vote: vote);
      await refresh(force: true);
    } catch (e) {
      if (current != null) {
        state = AsyncValue.data(current);
      }
      rethrow;
    }
  }
}

class MenuItemValueScoreController extends AsyncNotifier<MenuItemValueScore> {
  MenuItemValueScoreController(this.menuItemId);
  final String menuItemId;

  @override
  Future<MenuItemValueScore> build() async {
    return ref.read(menuRepositoryProvider).getMenuItemValueScore(menuItemId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(menuRepositoryProvider).getMenuItemValueScore(menuItemId);
    });
  }
}

class MenuItemPriceHistoryController
    extends AsyncNotifier<List<MenuItemPriceHistoryEntry>> {
  MenuItemPriceHistoryController(this.menuItemId);
  final String menuItemId;

  @override
  Future<List<MenuItemPriceHistoryEntry>> build() async {
    return ref.read(menuRepositoryProvider).getMenuItemPriceHistory(menuItemId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(menuRepositoryProvider)
          .getMenuItemPriceHistory(menuItemId);
    });
  }
}
