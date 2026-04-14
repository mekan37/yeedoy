import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/media/media_upload_client.dart';
import '../../../core/media/media_upload_repository.dart';
import '../../menus/data/menu_repository.dart';
import '../../menus/domain/menu_models.dart';

final ownerMenuPhotoRepositoryProvider = Provider<OwnerMenuPhotoRepository>((
  ref,
) {
  final menuRepository = ref.watch(menuRepositoryProvider);
  return OwnerMenuPhotoRepository(
    mediaUploadRepository: ref.watch(mediaUploadRepositoryProvider),
    menuRepository: menuRepository,
  );
});

class OwnerMenuPhotoRepository {
  OwnerMenuPhotoRepository({
    required this.mediaUploadRepository,
    required this.menuRepository,
  });

  final MediaUploadRepository mediaUploadRepository;
  final MenuRepository menuRepository;

  Future<List<MenuItemPhoto>> listMenuItemPhotos(String menuItemId) async {
    return menuRepository.fetchMenuItemPhotos(menuItemId);
  }

  Future<MediaUploadResult?> uploadMenuItemPhoto(String menuItemId) async {
    final upload = await mediaUploadRepository.pickAndUploadImage(
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

  Future<String?> addMenuItemPhotoFromUrl({
    required String menuItemId,
    required String url,
    String provider = 'ai_generated',
  }) async {
    return menuRepository.addMenuItemPhoto(
      menuItemId: menuItemId,
      url: url,
      urlLarge: url,
      urlThumb: url,
      provider: provider,
    );
  }

  Future<void> deleteMenuItemPhoto(String photoId) async {
    try {
      final res = await mediaUploadRepository.client.rpc(
        'owner_soft_delete_menu_item_photo_v1',
        params: {'p_photo_id': photoId},
      );
      if (res is Map && res['ok'] == true) return;
      if (res is List && res.isNotEmpty && res.first is Map) {
        final map = (res.first as Map).cast<String, dynamic>();
        if (map['ok'] == true) return;
      }
      throw Exception('menu_photo_delete_failed');
    } catch (e) {
      throw Exception(AppErrorMapper.message(e));
    }
  }
}
