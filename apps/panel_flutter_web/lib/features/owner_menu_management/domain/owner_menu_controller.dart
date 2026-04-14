import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_menu_repository.dart';
import '../data/owner_menu_photo_repository.dart';
import '../../menus/domain/menu_models.dart';
import '../../../core/media/media_upload_client.dart';
import 'owner_menu_models.dart';

final ownerMenusProvider =
    AsyncNotifierProvider.family<OwnerMenusController, List<OwnerMenu>, String>(
      OwnerMenusController.new,
    );

class OwnerMenusController extends AsyncNotifier<List<OwnerMenu>> {
  OwnerMenusController(this.businessId);
  final String businessId;

  @override
  Future<List<OwnerMenu>> build() async {
    if (businessId.isEmpty) return [];
    return ref
        .read(ownerMenuRepositoryProvider)
        .listMenus(businessId: businessId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (businessId.isEmpty) return Future.value(<OwnerMenu>[]);
      return ref
          .read(ownerMenuRepositoryProvider)
          .listMenus(businessId: businessId);
    });
  }

  Future<void> createMenu({
    required String title,
    String? kind,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .createMenu(
          businessId: businessId,
          title: title,
          kind: kind,
          activeFrom: activeFrom,
          activeTo: activeTo,
        );
    await refresh();
  }

  Future<void> updateMenu({
    required String menuId,
    String? title,
    String? kind,
    DateTime? activeFrom,
    DateTime? activeTo,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .updateMenu(
          menuId: menuId,
          title: title,
          kind: kind,
          activeFrom: activeFrom,
          activeTo: activeTo,
        );
    await refresh();
  }

  Future<void> archiveMenu({required String menuId}) async {
    await ref.read(ownerMenuRepositoryProvider).archiveMenu(menuId: menuId);
    await refresh();
  }

  Future<void> publishMenu({required String menuId}) async {
    await ref.read(ownerMenuRepositoryProvider).publishMenu(menuId: menuId);
    await refresh();
  }
}

final ownerMenuSectionsProvider =
    AsyncNotifierProvider.family<
      OwnerMenuSectionsController,
      List<OwnerMenuSection>,
      String
    >(OwnerMenuSectionsController.new);

class OwnerMenuSectionsController
    extends AsyncNotifier<List<OwnerMenuSection>> {
  OwnerMenuSectionsController(this.menuId);
  final String menuId;

  @override
  Future<List<OwnerMenuSection>> build() async {
    if (menuId.isEmpty) return [];
    final sections = await ref
        .read(ownerMenuRepositoryProvider)
        .listSections(menuId: menuId);
    sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sections;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (menuId.isEmpty) return <OwnerMenuSection>[];
      final sections = await ref
          .read(ownerMenuRepositoryProvider)
          .listSections(menuId: menuId);
      sections.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return sections;
    });
  }

  Future<void> createSection({required String title}) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .createSection(menuId: menuId, title: title);
    await refresh();
  }

  Future<void> updateSection({
    required String sectionId,
    required String title,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .updateSection(sectionId: sectionId, title: title);
    await refresh();
  }

  Future<void> deleteSection({
    required String sectionId,
    required bool deleteItems,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .deleteSection(sectionId: sectionId, deleteItems: deleteItems);
    await refresh();
  }

  Future<void> reorderSections({required List<String> sectionIds}) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .reorderSections(menuId: menuId, sectionIds: sectionIds);
    await refresh();
  }
}

class OwnerSectionKey {
  const OwnerSectionKey(this.menuId, this.sectionId);
  final String menuId;
  final String sectionId;
}

class OwnerSectionItemsState {
  const OwnerSectionItemsState({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
  });

  final List<OwnerMenuItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  factory OwnerSectionItemsState.initial() => const OwnerSectionItemsState(
    items: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: true,
    error: null,
  );

  OwnerSectionItemsState copyWith({
    List<OwnerMenuItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return OwnerSectionItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

final ownerSectionItemsProvider =
    NotifierProvider.family<
      OwnerSectionItemsController,
      OwnerSectionItemsState,
      OwnerSectionKey
    >(OwnerSectionItemsController.new);

class OwnerSectionItemsController extends Notifier<OwnerSectionItemsState> {
  OwnerSectionItemsController(this.key);
  final OwnerSectionKey key;
  static const int pageSize = 40;
  int _requestId = 0;

  @override
  OwnerSectionItemsState build() {
    Future.microtask(() => loadInitial());
    return OwnerSectionItemsState.initial();
  }

  Future<void> loadInitial({bool force = false}) async {
    if (state.isLoading && !force) return;
    final reqId = ++_requestId;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: null);
    try {
      final items = await ref
          .read(ownerMenuRepositoryProvider)
          .listItems(sectionId: key.sectionId, limit: pageSize, offset: 0);
      if (reqId != _requestId) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final reqId = _requestId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final items = await ref
          .read(ownerMenuRepositoryProvider)
          .listItems(
            sectionId: key.sectionId,
            limit: pageSize,
            offset: state.items.length,
          );
      if (reqId != _requestId) return;
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    _requestId++;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      items: [],
      error: null,
    );
    await loadInitial(force: true);
  }

  Future<void> createItem({
    required String name,
    String? description,
    int? priceCents,
    String currency = 'TRY',
    int? catalogItemId,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .createItem(
          sectionId: key.sectionId,
          name: name,
          description: description,
          priceCents: priceCents,
          currency: currency,
          catalogItemId: catalogItemId,
        );
    await refresh();
  }

  Future<void> updateItem({
    required String itemId,
    String? name,
    String? description,
    int? priceCents,
    String? currency,
    int? catalogItemId,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .updateItem(
          itemId: itemId,
          name: name,
          description: description,
          priceCents: priceCents,
          currency: currency,
          catalogItemId: catalogItemId,
        );
    await refresh();
  }

  Future<void> archiveItem({required String itemId}) async {
    await ref.read(ownerMenuRepositoryProvider).archiveItem(itemId: itemId);
    await refresh();
  }
}

final ownerMenuItemPhotosProvider =
    AsyncNotifierProvider.family<
      OwnerMenuItemPhotosController,
      List<MenuItemPhoto>,
      String
    >(OwnerMenuItemPhotosController.new);

final ownerMenuItemVariantsProvider =
    AsyncNotifierProvider.family<
      OwnerMenuItemVariantsController,
      List<OwnerMenuItemVariant>,
      String
    >(OwnerMenuItemVariantsController.new);

class OwnerMenuItemPhotosController extends AsyncNotifier<List<MenuItemPhoto>> {
  OwnerMenuItemPhotosController(this.menuItemId);
  final String menuItemId;

  @override
  Future<List<MenuItemPhoto>> build() async {
    return ref
        .read(ownerMenuPhotoRepositoryProvider)
        .listMenuItemPhotos(menuItemId);
  }

  Future<void> refresh({bool force = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(ownerMenuPhotoRepositoryProvider)
          .listMenuItemPhotos(menuItemId);
    });
  }

  Future<MediaUploadResult?> uploadPhoto() async {
    final upload = await ref
        .read(ownerMenuPhotoRepositoryProvider)
        .uploadMenuItemPhoto(menuItemId);
    if (upload == null) return null;
    await refresh(force: true);
    return upload;
  }

  Future<String?> addPhotoFromUrl({required String url}) async {
    final photoId = await ref
        .read(ownerMenuPhotoRepositoryProvider)
        .addMenuItemPhotoFromUrl(menuItemId: menuItemId, url: url);
    await refresh(force: true);
    return photoId;
  }

  Future<void> deletePhoto({required String photoId}) async {
    await ref
        .read(ownerMenuPhotoRepositoryProvider)
        .deleteMenuItemPhoto(photoId);
    await refresh(force: true);
  }
}

class OwnerMenuItemVariantsController
    extends AsyncNotifier<List<OwnerMenuItemVariant>> {
  OwnerMenuItemVariantsController(this.menuItemId);
  final String menuItemId;

  @override
  Future<List<OwnerMenuItemVariant>> build() async {
    if (menuItemId.isEmpty) return const [];
    return ref
        .read(ownerMenuRepositoryProvider)
        .listItemVariants(itemId: menuItemId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (menuItemId.isEmpty) return Future.value(<OwnerMenuItemVariant>[]);
      return ref
          .read(ownerMenuRepositoryProvider)
          .listItemVariants(itemId: menuItemId);
    });
  }

  Future<void> createVariant({
    required String label,
    required int priceCents,
    String currency = 'TRY',
    bool isDefault = false,
  }) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .createItemVariant(
          itemId: menuItemId,
          label: label,
          priceCents: priceCents,
          currency: currency,
          isDefault: isDefault,
        );
    await refresh();
  }

  Future<void> setDefault({required String variantId}) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .setDefaultItemVariant(itemId: menuItemId, variantId: variantId);
    await refresh();
  }

  Future<void> deleteVariant({required String variantId}) async {
    await ref
        .read(ownerMenuRepositoryProvider)
        .deleteItemVariant(variantId: variantId);
    await refresh();
  }
}
