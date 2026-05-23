import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/baglanti/yeedoy_rota_cozucu.dart';
import '../../../features/kimlik/domain/kimlik_saglayicilari.dart';
import '../../../features/kesif/data/kesif_deposu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../menuler/domain/menu_modelleri.dart';
import '../../menuler/domain/menu_saglayicilari.dart';
import '../data/gecici_yukleme_deposu.dart';

class ContributeFab extends ConsumerStatefulWidget {
  const ContributeFab({super.key, this.businessId});

  final String? businessId;

  @override
  ConsumerState<ContributeFab> createState() => _ContributeFabState();
}

class _ContributeFabState extends ConsumerState<ContributeFab> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      heroTag: widget.businessId == null
          ? 'contribute_discovery_fab'
          : 'contribute_business_${widget.businessId}',
      onPressed: () => _openContributeSheet(context),
      icon: const Icon(Icons.add_a_photo_outlined),
      label: Text(t.contribute),
    );
  }

  Future<void> _openContributeSheet(BuildContext context) async {
    final t = AppLocalizations.of(context);
    var businessName = t.contributeDefaultBusinessName;
    final businessId = widget.businessId;
    if (businessId != null && businessId.trim().isNotEmpty) {
      try {
        final business = await ref
            .read(discoveryRepositoryProvider)
            .fetchBusiness(businessId);
        final resolved = business.name.trim();
        if (resolved.isNotEmpty) {
          businessName = resolved;
        }
      } catch (_) {}
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: this.context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t.updateBusinessTitle(businessName),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.contributeSheetSubtitle,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                _EntryActionTile(
                  icon: Icons.qr_code_scanner_outlined,
                  title: t.scanMenuQr,
                  subtitle: t.scanMenuQrSubtitle,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _captureQrAndSmartRoute();
                  },
                ),
                _EntryActionTile(
                  icon: Icons.add_a_photo_outlined,
                  title: t.uploadPhoto,
                  subtitle: t.uploadPhotoSubtitle,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _captureAndUpload(
                      kind: 'menu_page',
                      allowMultiple: true,
                    );
                  },
                ),
                _EntryActionTile(
                  icon: Icons.price_change_outlined,
                  title: t.confirmPriceChange,
                  subtitle: t.confirmPriceChangeSubtitle,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openVerifyFlow();
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      t.cancel,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _captureAndUpload({
    required String kind,
    required bool allowMultiple,
  }) async {
    final t = context.l10n;
    final businessId = widget.businessId;
    if (businessId == null || businessId.trim().isEmpty) {
      _toast(t.contributeOpenBusinessFirst);
      return;
    }

    final source = await _pickSource();
    if (!mounted || source == null) return;

    List<XFile> files = const [];
    if (allowMultiple && source == ImageSource.gallery) {
      files = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
    } else {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null) files = [file];
    }
    if (!mounted || files.isEmpty) return;

    _showProgress(t.contributeUploadingProgress);
    try {
      final userId = ref.read(userProvider)?.id;
      final count = await ref
          .read(tempUploadsRepositoryProvider)
          .uploadTempFiles(
            businessId: businessId,
            kind: kind,
            files: files,
            userId: userId,
          );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (count <= 1) {
        _toast(t.contributeUploadSentSingle);
      } else {
        _toast(t.contributeUploadSentMultiple(count));
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(t.contributeUploadFailed);
    }
  }

  Future<void> _captureQrAndSmartRoute() async {
    final t = context.l10n;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    _showProgress(t.contributeQrDecodingProgress);
    try {
      final decoded = await _decodeQrText(file.path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (decoded == null || decoded.trim().isEmpty) {
        _toast(t.contributeQrUnreadableSentReview);
        await _uploadQrForReview(file);
        return;
      }

      final targetRoute = resolveYeedoyRouteFromQr(decoded);
      if (targetRoute != null) {
        _toast(t.contributeQrVerifiedRedirecting);
        if (!mounted) return;
        context.go(targetRoute);
        return;
      }

      await _uploadQrForReview(file, scannedText: decoded);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(t.contributeQrProcessFailed);
    }
  }

  Future<String?> _decodeQrText(String path) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final input = InputImage.fromFilePath(path);
      final barcodes = await scanner.processImage(input);
      for (final barcode in barcodes) {
        final value = barcode.rawValue?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    } finally {
      await scanner.close();
    }
  }

  Future<void> _uploadQrForReview(XFile file, {String? scannedText}) async {
    final t = context.l10n;
    final businessId = widget.businessId;
    if (businessId == null || businessId.trim().isEmpty) {
      _toast(t.contributeExternalQrUseBusinessPage);
      return;
    }
    _showProgress(t.contributeSendingForReviewProgress);
    try {
      final userId = ref.read(userProvider)?.id;
      await ref
          .read(tempUploadsRepositoryProvider)
          .uploadTempFiles(
            businessId: businessId,
            kind: 'qr',
            files: [file],
            userId: userId,
          );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(
        scannedText == null
            ? t.contributeQrImageSentForReview
            : t.contributeExternalLinkSentForReview,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(t.contributeUploadFailed);
    }
  }

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.l10n.contributeSourceCamera),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.contributeSourceGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openVerifyFlow() async {
    final t = context.l10n;
    final businessId = widget.businessId;
    if (businessId == null || businessId.trim().isEmpty) {
      _toast(t.contributeSelectBusinessForPriceVerification);
      return;
    }

    try {
      final menus = await ref.read(businessMenusProvider(businessId).future);
      if (!mounted) return;
      final menuId = _selectDefaultMenuId(menus);
      if (menuId == null || menuId.isEmpty) {
        _toast(t.noMenuProductsYet);
        return;
      }
      context.go('/isletme/$businessId/menu/$menuId');
      _toast(t.contributeSelectMenuItemToVerifyPrice);
    } catch (_) {
      if (!mounted) return;
      _toast(t.menuDataUnavailable);
    }
  }

  String? _selectDefaultMenuId(List<BusinessMenu> menus) {
    if (menus.isEmpty) return null;
    final now = DateTime.now();
    for (final menu in menus) {
      if (menu.id.isEmpty) continue;
      final status = menu.status.toLowerCase();
      if (status == 'archived' || status == 'passive') continue;
      final from = DateTime.tryParse(menu.activeFrom ?? '');
      final to = DateTime.tryParse(menu.activeTo ?? '');
      final windowOk =
          (from == null || !from.isAfter(now)) &&
          (to == null || !to.isBefore(now));
      if (windowOk) return menu.id;
    }
    return menus.first.id;
  }

  void _showProgress(String text) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
            ],
          ),
        );
      },
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EntryActionTile extends StatelessWidget {
  const _EntryActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
