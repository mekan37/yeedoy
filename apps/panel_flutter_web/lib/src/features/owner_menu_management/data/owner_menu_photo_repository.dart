import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/network/supabase_provider.dart';
import '../../../../core/security/write_gatekeeper_client.dart';
import '../../../../features/menus/data/menu_repository.dart';
import '../../../../features/menus/data/wp_upload.dart';
import '../../../../features/menus/domain/menu_models.dart';

final ownerMenuPhotoRepositoryProvider = Provider<OwnerMenuPhotoRepository>((
  ref,
) {
  final client = ref.watch(supabaseProvider);
  final menuRepository = ref.watch(menuRepositoryProvider);
  return OwnerMenuPhotoRepository(
    client: client,
    menuRepository: menuRepository,
  );
});

class OwnerMenuPhotoRepository {
  OwnerMenuPhotoRepository({
    required this.client,
    required this.menuRepository,
  });

  final SupabaseClient client;
  final MenuRepository menuRepository;

  Future<List<MenuItemPhoto>> listMenuItemPhotos(String menuItemId) async {
    return menuRepository.getMenuItemPhotos(menuItemId);
  }

  Future<WpUploadResult?> uploadMenuItemPhoto(String menuItemId) async {
    final upload = await pickAndUploadWpImage(
      client: client,
      title: 'menu_item_$menuItemId',
      menuItemId: menuItemId,
    );
    if (upload == null) return null;

    await menuRepository.addMenuItemPhoto(
      menuItemId: menuItemId,
      url: upload.url,
      urlLarge: upload.urlLarge,
      urlThumb: upload.urlThumb,
      provider: 'supabase_storage',
    );
    return upload;
  }

  Future<void> deleteMenuItemPhoto(String photoId) async {
    try {
      await invokeWriteGatekeeper(
        client,
        action: 'menu_photo_delete',
        payload: {'photo_id': photoId},
      );
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
