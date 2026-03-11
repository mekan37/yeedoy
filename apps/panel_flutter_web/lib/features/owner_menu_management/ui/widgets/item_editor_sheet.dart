import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../menus/domain/food_catalog_models.dart';
import '../../../menus/domain/food_catalog_search_controller.dart';
import '../../../menus/domain/menu_models.dart';
import '../../domain/owner_menu_controller.dart';
import '../../domain/owner_menu_models.dart';
import '../owner_menu_error_mapper.dart';

class ItemEditorSheet extends ConsumerStatefulWidget {
  const ItemEditorSheet({
    super.key,
    required this.title,
    required this.onSave,
    this.initial,
    this.onArchive,
  });

  final String title;
  final OwnerMenuItem? initial;
  final Future<void> Function(ItemEditorPayload payload) onSave;
  final Future<void> Function()? onArchive;

  @override
  ConsumerState<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends ConsumerState<ItemEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _currencyCtrl;
  final TextEditingController _catalogQueryCtrl = TextEditingController();
  int? _catalogItemId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.initial?.priceCents == null
          ? ''
          : (widget.initial!.priceCents! / 100.0).toStringAsFixed(0),
    );
    _currencyCtrl = TextEditingController(
      text: widget.initial?.currency ?? 'TRY',
    );
    _catalogItemId = widget.initial?.catalogItemId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
    _catalogQueryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(foodCatalogSearchProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.ownerItemName,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.ownerDescriptionOptional,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.l10n.ownerPriceTl),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currencyCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.ownerCurrency,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catalogQueryCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.ownerCatalogSearch,
                hintText: context.l10n.ownerCatalogSearchHint,
              ),
              onChanged: (value) =>
                  ref.read(foodCatalogSearchProvider.notifier).setQuery(value),
            ),
            if (searchState.isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (searchState.results.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  itemCount: searchState.results.length,
                  itemBuilder: (context, index) {
                    final hit = searchState.results[index];
                    return ListTile(
                      title: Text(hit.name),
                      subtitle: Text(hit.categoryName),
                      onTap: () => _selectCatalog(hit),
                    );
                  },
                ),
              ),
            ],
            if (_catalogItemId != null) ...[
              const SizedBox(height: 6),
              Text(context.l10n.ownerSelectedCatalogId(_catalogItemId!)),
            ],
            if (widget.initial != null) ...[
              const SizedBox(height: 12),
              _OwnerItemVariantsSection(itemId: widget.initial!.id),
              const SizedBox(height: 12),
              _OwnerItemPhotosSection(itemId: widget.initial!.id),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _onSave,
                    child: Text(
                      _saving ? context.l10n.saving : context.l10n.save,
                    ),
                  ),
                ),
                if (widget.onArchive != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _saving ? null : widget.onArchive,
                    child: Text(context.l10n.ownerArchiveAction),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectCatalog(FoodCatalogHit hit) {
    setState(() {
      _catalogItemId = hit.id;
      _catalogQueryCtrl.text = hit.name;
    });
    ref.read(foodCatalogSearchProvider.notifier).clear();
  }

  Future<void> _onSave() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = context.l10n.ownerItemNameMin2);
      return;
    }
    final priceText = _priceCtrl.text.trim();
    int? priceCents;
    if (priceText.isNotEmpty) {
      final parsed = double.tryParse(priceText.replaceAll(',', '.'));
      if (parsed == null) {
        setState(() => _error = context.l10n.ownerInvalidPrice);
        return;
      }
      priceCents = (parsed * 100).round();
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        ItemEditorPayload(
          name: name,
          description: _descCtrl.text.trim(),
          priceCents: priceCents,
          currency: _currencyCtrl.text.trim().isEmpty
              ? 'TRY'
              : _currencyCtrl.text.trim(),
          catalogItemId: _catalogItemId,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ownerMenuErrorMessage(
            context.l10n,
            e,
            fallback: AppErrorMapper.message(e),
          );
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _OwnerItemVariantsSection extends ConsumerStatefulWidget {
  const _OwnerItemVariantsSection({required this.itemId});
  final String itemId;

  @override
  ConsumerState<_OwnerItemVariantsSection> createState() =>
      _OwnerItemVariantsSectionState();
}

class _OwnerItemVariantsSectionState
    extends ConsumerState<_OwnerItemVariantsSection> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final variantsAsync = ref.watch(
      ownerMenuItemVariantsProvider(widget.itemId),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.ownerVariants,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _saving ? null : _openCreateVariantSheet,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.ownerAddVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            variantsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                ownerMenuErrorMessage(
                  context.l10n,
                  e,
                  fallback: AppErrorMapper.message(e),
                ),
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (variants) {
                if (variants.isEmpty) {
                  return Text(
                    context.l10n.ownerNoVariantsHint,
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                return Column(
                  children: [
                    for (final variant in variants)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(variant.label),
                        subtitle: Text(
                          '${(variant.priceCents / 100).toStringAsFixed(2)} ${variant.currency}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (variant.isDefault)
                              Chip(
                                label: Text(context.l10n.ownerDefaultVariant),
                              ),
                            if (!variant.isDefault)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => _setDefaultVariant(variant.id),
                                child: Text(context.l10n.ownerSetDefault),
                              ),
                            IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => _deleteVariant(variant.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateVariantSheet() async {
    final labelCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'TRY');
    var isDefault = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.ownerAddVariant,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerLabelExample,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerPriceTl,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: currencyCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.ownerCurrency,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isDefault,
                  onChanged: (v) => setModalState(() => isDefault = v),
                  title: Text(context.l10n.ownerDefaultVariantSwitch),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(context.l10n.ownerAddVariant),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    final label = labelCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
    if (label.isEmpty || price == null || price < 0) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerMenuItemVariantsProvider(widget.itemId).notifier)
          .createVariant(
            label: label,
            priceCents: (price * 100).round(),
            currency: currencyCtrl.text.trim().isEmpty
                ? 'TRY'
                : currencyCtrl.text.trim(),
            isDefault: isDefault,
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDefaultVariant(String variantId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerMenuItemVariantsProvider(widget.itemId).notifier)
          .setDefault(variantId: variantId);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteVariant(String variantId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(ownerMenuItemVariantsProvider(widget.itemId).notifier)
          .deleteVariant(variantId: variantId);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ItemEditorPayload {
  ItemEditorPayload({
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.catalogItemId,
  });

  final String name;
  final String description;
  final int? priceCents;
  final String currency;
  final int? catalogItemId;
}

class _OwnerItemPhotosSection extends ConsumerStatefulWidget {
  const _OwnerItemPhotosSection({required this.itemId});
  final String itemId;

  @override
  ConsumerState<_OwnerItemPhotosSection> createState() =>
      _OwnerItemPhotosSectionState();
}

class _OwnerItemPhotosSectionState
    extends ConsumerState<_OwnerItemPhotosSection> {
  bool _uploading = false;
  String _precacheKey = '';
  ProviderSubscription<AsyncValue<List<MenuItemPhoto>>>? _photosSub;

  @override
  void initState() {
    super.initState();
    _photosSub = ref.listenManual<AsyncValue<List<MenuItemPhoto>>>(
      ownerMenuItemPhotosProvider(widget.itemId),
      (_, next) {
        final photos = next.asData?.value ?? const <MenuItemPhoto>[];
        _precacheVisiblePhotos(photos);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _photosSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(ownerMenuItemPhotosProvider(widget.itemId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.ownerPhotos,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _uploading ? null : _handleUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _uploading
                        ? context.l10n.ownerUploading
                        : context.l10n.ownerAddPhoto,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            photosAsync.when(
              loading: () => const _PhotoGridSkeleton(),
              error: (e, _) => _PhotoError(
                message: AppErrorMapper.message(e),
                onRetry: () => ref
                    .read(ownerMenuItemPhotosProvider(widget.itemId).notifier)
                    .refresh(force: true),
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return Text(
                    context.l10n.ownerNoPhotoYet,
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return _OwnerPhotoTile(
                          photo: photo,
                          onTap: () => _openPhotoViewer(context, photos, index),
                          onDelete: () => _confirmDelete(photo),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _openPhotoViewer(context, photos, 0),
                        child: Text(context.l10n.ownerViewAll),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    setState(() => _uploading = true);
    try {
      final res = await ref
          .read(ownerMenuItemPhotosProvider(widget.itemId).notifier)
          .uploadPhoto();
      if (res == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerPhotoUploaded)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(_uploadErrorMessageWithContext(e, context))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _confirmDelete(MenuItemPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.ownerDeletePhoto),
        content: Text(context.l10n.ownerDeletePhotoToTrashConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.ownerDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(ownerMenuItemPhotosProvider(widget.itemId).notifier)
          .deletePhoto(photoId: photo.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerPhotoMovedToTrash)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    }
  }

  void _precacheVisiblePhotos(List<MenuItemPhoto> photos) {
    final urls = photos
        .take(5)
        .map(
          (p) => p.urlThumb.isEmpty
              ? (p.urlLarge.isEmpty ? p.url : p.urlLarge)
              : p.urlThumb,
        )
        .where((u) => u.trim().isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    final key = urls.join('|');
    if (key == _precacheKey) return;
    _precacheKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        precacheImageUrls(
          context,
          urls,
          variant: AppImageVariant.thumb,
          take: 5,
        ),
      );
    });
  }
}

class _OwnerPhotoTile extends StatelessWidget {
  const _OwnerPhotoTile({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final MenuItemPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = photo.urlThumb.isEmpty ? photo.urlLarge : photo.urlThumb;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: AppNetworkImage(
                url: thumb.isEmpty ? photo.url : thumb,
                variant: AppImageVariant.thumb,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGridSkeleton extends StatelessWidget {
  const _PhotoGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.danger)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
      ],
    );
  }
}

class _PhotoViewerPage extends StatelessWidget {
  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  final List<MenuItemPhoto> photos;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return InteractiveViewer(
            child: Center(
              child: AppNetworkImage(
                url: photo.urlLarge.isEmpty ? photo.url : photo.urlLarge,
                variant: AppImageVariant.medium,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

void _openPhotoViewer(
  BuildContext context,
  List<MenuItemPhoto> photos,
  int initialIndex,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _PhotoViewerPage(photos: photos, initialIndex: initialIndex),
    ),
  );
}

String _uploadErrorMessageWithContext(Object error, BuildContext? context) {
  final msg = AppErrorMapper.message(error).toLowerCase();
  if (msg.contains('not_owner')) {
    return context?.l10n.ownerUploadRequiresOwnership ??
        'Bu işlem için işletme sahibi olmalısın';
  }
  if (msg.contains('rate')) {
    return context?.l10n.ownerUploadRateLimited ??
        'Çok sık denedin, lütfen biraz sonra tekrar dene';
  }
  return context?.l10n.ownerUploadFailed ?? 'Yükleme başarısız';
}
