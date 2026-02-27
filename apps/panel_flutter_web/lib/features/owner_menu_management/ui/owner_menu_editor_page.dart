import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/web/download_utils.dart';
import '../data/owner_menu_repository.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import '../../owner_dashboard/domain/owner_moat_provider.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import 'owner_menu_error_mapper.dart';
import 'owner_section_editor_page.dart';
import 'widgets/section_list_tile.dart';
import '../../menus/ui/public_menu_share_page.dart';
import '../../../shared/ui/components/app_scaffold.dart';

class OwnerMenuEditorPage extends ConsumerStatefulWidget {
  const OwnerMenuEditorPage({
    super.key,
    required this.menu,
    this.openShareOnStart = false,
  });
  final OwnerMenu menu;
  final bool openShareOnStart;

  @override
  ConsumerState<OwnerMenuEditorPage> createState() =>
      _OwnerMenuEditorPageState();
}

class _OwnerMenuEditorPageState extends ConsumerState<OwnerMenuEditorPage> {
  List<OwnerMenuSection>? _optimisticSections;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<OwnerMenuSection>>>(
      ownerMenuSectionsProvider(widget.menu.id),
      (_, next) {
        if (next.hasValue && mounted) {
          setState(() => _optimisticSections = null);
        }
      },
    );
    if (widget.openShareOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openSharePanel(widget.menu);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final l10n = context.l10n;
    final sectionsAsync = ref.watch(ownerMenuSectionsProvider(menu.id));
    return AppScaffold(
      appBar: AppBar(
        title: Text(menu.title),
        actions: [
          TextButton.icon(
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.preview),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _openSharePanel(menu),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.share),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                ref.read(ownerMenuSectionsProvider(menu.id).notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(ownerMenuSectionsProvider(menu.id).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _MenuHeader(
              menu: menu,
              onEdit: _editMenu,
              onArchive: _archiveMenu,
              onPublish: menu.status == 'published' ? null : _publishMenu,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  context.l10n.ownerSections,
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openCreateSection,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.ownerAddSection),
                ),
              ],
            ),
            const SizedBox(height: 8),
            sectionsAsync.when(
              loading: () => const _SectionSkeleton(),
              error: (e, _) => _ErrorBox(
                message: AppErrorMapper.message(e),
                onRetry: () => ref
                    .read(ownerMenuSectionsProvider(menu.id).notifier)
                    .refresh(),
              ),
              data: (sections) {
                final effectiveSections = _optimisticSections ?? sections;
                if (sections.isEmpty) {
                  return _EmptyBox(message: context.l10n.ownerSectionNotFound);
                }
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: effectiveSections.length,
                  onReorder: (oldIndex, newIndex) =>
                      _onReorder(oldIndex, newIndex, effectiveSections),
                  itemBuilder: (context, index) {
                    final section = effectiveSections[index];
                    return Padding(
                      key: ValueKey('section_${section.id}'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SectionListTile(
                        section: section,
                        onEdit: () => _editSection(section),
                        onDelete: () => _deleteSection(section),
                        onOpenItems: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => OwnerSectionEditorPage(
                                    menu: menu,
                                    section: section,
                                  ),
                                ),
                              );
                          if (updated == true && mounted) {
                            ref
                                .read(
                                  ownerMenuSectionsProvider(menu.id).notifier,
                                )
                                .refresh();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateSection() async {
    final l10n = context.l10n;
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.ownerAddSection),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(labelText: context.l10n.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.ownerAddSection),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(ownerMenuSectionsProvider(widget.menu.id).notifier)
          .createSection(title: titleCtrl.text.trim());
      invalidateSection(ref, menuId: widget.menu.id, sectionId: '');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.ownerSectionAdded)));
      }
    } catch (e) {
      _showError(e);
    } finally {
      titleCtrl.dispose();
    }
  }

  Future<void> _editSection(OwnerMenuSection section) async {
    final l10n = context.l10n;
    final titleCtrl = TextEditingController(text: section.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.ownerEditSection),
        content: TextField(
          controller: titleCtrl,
          decoration: InputDecoration(labelText: context.l10n.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(ownerMenuSectionsProvider(widget.menu.id).notifier)
          .updateSection(sectionId: section.id, title: titleCtrl.text.trim());
      invalidateSection(ref, menuId: widget.menu.id, sectionId: section.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerSectionUpdated)),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      titleCtrl.dispose();
    }
  }

  Future<void> _deleteSection(OwnerMenuSection section) async {
    final l10n = context.l10n;
    var deleteItems = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: Text(context.l10n.ownerDeleteSection),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.ownerSectionWillBeDeleted),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: deleteItems,
                  onChanged: (value) {
                    setModalState(() => deleteItems = value ?? true);
                  },
                  title: Text(context.l10n.ownerArchiveItemsInSection),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.ownerDeleteSection),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(ownerMenuSectionsProvider(widget.menu.id).notifier)
          .deleteSection(sectionId: section.id, deleteItems: deleteItems);
      invalidateSection(ref, menuId: widget.menu.id, sectionId: section.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ownerSectionDeleted)),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _editMenu() async {
    final l10n = context.l10n;
    final titleCtrl = TextEditingController(text: widget.menu.title);
    final kindCtrl = TextEditingController(text: widget.menu.kind ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
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
                context.l10n.ownerEditMenu,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: context.l10n.title),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kindCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.ownerMenuTypeOptional,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true) return;
    try {
      await ref
          .read(ownerMenusProvider(widget.menu.businessId).notifier)
          .updateMenu(
            menuId: widget.menu.id,
            title: titleCtrl.text.trim(),
            kind: kindCtrl.text.trim(),
          );
      invalidateMenu(
        ref,
        businessId: widget.menu.businessId,
        menuId: widget.menu.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.ownerMenuUpdated)));
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      titleCtrl.dispose();
      kindCtrl.dispose();
    }
  }

  Future<void> _archiveMenu() async {
    final ok = await _confirm(context, context.l10n.ownerArchiveMenuConfirm);
    if (!ok) return;
    try {
      await ref
          .read(ownerMenusProvider(widget.menu.businessId).notifier)
          .archiveMenu(menuId: widget.menu.id);
      invalidateMenu(
        ref,
        businessId: widget.menu.businessId,
        menuId: widget.menu.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _publishMenu() async {
    final ok = await _confirm(context, context.l10n.ownerPublishMenuConfirm);
    if (!ok) return;
    try {
      await ref
          .read(ownerMenusProvider(widget.menu.businessId).notifier)
          .publishMenu(menuId: widget.menu.id);
      invalidateMenu(
        ref,
        businessId: widget.menu.businessId,
        menuId: widget.menu.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    final msg = ownerMenuErrorMessage(
      error,
      fallback: AppErrorMapper.message(error),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openPreview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicMenuSharePage(menuId: widget.menu.id),
      ),
    );
  }

  Future<void> _openSharePanel(OwnerMenu menu) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MenuSharePanel(menu: menu),
    );
  }

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<OwnerMenuSection> current,
  ) async {
    if (_reordering) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final previous = List<OwnerMenuSection>.from(current);
    final updated = List<OwnerMenuSection>.from(current);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    setState(() => _optimisticSections = updated);
    _reordering = true;
    try {
      await ref
          .read(ownerMenuSectionsProvider(widget.menu.id).notifier)
          .reorderSections(sectionIds: updated.map((e) => e.id).toList());
      invalidateSection(ref, menuId: widget.menu.id, sectionId: '');
    } catch (e) {
      if (!mounted) return;
      setState(() => _optimisticSections = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      await ref
          .read(ownerMenuSectionsProvider(widget.menu.id).notifier)
          .refresh();
    } finally {
      _reordering = false;
    }
  }
}

String _buildShareLink(String menuId) {
  if (kIsWeb) {
    final origin = Uri.base.origin;
    final base = origin.isEmpty ? AppConfig.webBaseUrl : origin;
    return '$base/menu/$menuId';
  }
  return AppConfig.menuWebUrl(menuId);
}

String _withSrc(String link, String src) {
  final uri = Uri.parse(link);
  final qp = Map<String, String>.from(uri.queryParameters);
  qp['src'] = src;
  return uri.replace(queryParameters: qp).toString();
}

class _MenuSharePanel extends ConsumerStatefulWidget {
  const _MenuSharePanel({required this.menu});
  final OwnerMenu menu;

  @override
  ConsumerState<_MenuSharePanel> createState() => _MenuSharePanelState();
}

class _MenuSharePanelState extends ConsumerState<_MenuSharePanel> {
  final _qrKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final link = _buildShareLink(widget.menu.id);
    final qrLink = _withSrc(link, 'qr');
    final ownerDashboardLink = AppConfig.ownerDashboardWebUrl(
      businessId: widget.menu.businessId,
    );
    final repo = ref.read(ownerMenuRepositoryProvider);
    final moatAsync = ref.watch(
      ownerMoatSummaryProvider(widget.menu.businessId),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: repo.getPublicMenuShare(menuId: widget.menu.id),
      builder: (context, snap) {
        final data = (snap.data ?? const {});
        final business = data['business'] as Map?;
        final menu = data['menu'] as Map?;
        final businessName = (business?['name'] ?? '').toString().trim();
        final safeName = businessName.isEmpty
            ? widget.menu.title
            : businessName;
        final openNow = _readBool(
          menu,
          business,
          keys: const ['open_now', 'is_open_now', 'isOpenNow'],
        );
        final nearbyViews = _readInt(
          menu,
          business,
          keys: const [
            'nearby_views',
            'nearby_view_count',
            'nearby_menu_views',
            'menu_views_48h',
            'view_count_48h',
          ],
        );

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                context.l10n.ownerSharePanel,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(safeName, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: link),
                decoration: InputDecoration(
                  labelText: context.l10n.ownerMenuLink,
                  suffixIcon: IconButton(
                    onPressed: () => _copyText(link),
                    icon: const Icon(Icons.copy),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: QrImageView(
                      data: qrLink,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _downloadQrPng(qrLink, safeName),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(context.l10n.ownerQrPng),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _downloadQrPdf(qrLink, safeName, isA6: false),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(context.l10n.ownerQrPdf),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _downloadQrPdf(qrLink, safeName, isA6: true),
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: Text(context.l10n.ownerA6Pdf),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.ownerFieldGainCardTitle,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.ownerFieldGainCardLine1,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.ownerFieldGainCardLine2,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    _CopyRow(
                      label: context.l10n.ownerCopyMiniDashboard,
                      text: ownerDashboardLink,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: moatAsync.when(
                    loading: () => const LinearProgressIndicator(minHeight: 6),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (moat) {
                      if (moat == null) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.ownerMoatTitle,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.ownerMoatSummary(
                              moat.businessTrustScore,
                              moat.menuFreshnessScore,
                              moat.priceAccuracyScore,
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.ownerMoatSignal(
                              moat.uniqueValidators,
                              (moat.evidenceRate * 100).round(),
                              moat.menuViewsToday,
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CopyRow(
                            label: context.l10n.ownerCopyMoatText,
                            text: _moatPitchText(
                              link,
                              businessName: safeName,
                              moat: moat,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ShareSectionLabel(
                icon: FontAwesomeIcons.whatsapp,
                text: context.l10n.ownerWhatsappText,
              ),
              const SizedBox(height: 6),
              _CopyRow(
                label: context.l10n.ownerCopyWhatsapp,
                text: _whatsAppText(
                  link,
                  businessName: safeName,
                  openNow: openNow,
                  nearbyViews: nearbyViews,
                ),
              ),
              const SizedBox(height: 12),
              _ShareSectionLabel(
                icon: FontAwesomeIcons.xTwitter,
                text: context.l10n.ownerXText,
              ),
              const SizedBox(height: 6),
              _CopyRow(
                label: context.l10n.ownerCopyX,
                text: _twitterText(
                  link,
                  businessName: safeName,
                  openNow: openNow,
                  nearbyViews: nearbyViews,
                ),
              ),
              const SizedBox(height: 12),
              _ShareSectionLabel(
                icon: FontAwesomeIcons.instagram,
                text: context.l10n.ownerInstagramBio,
              ),
              const SizedBox(height: 6),
              _CopyRow(
                label: context.l10n.ownerCopyInstagram,
                text: _instagramText(
                  link,
                  businessName: safeName,
                  openNow: openNow,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  bool _readBool(Map? menu, Map? business, {required List<String> keys}) {
    for (final key in keys) {
      final mv = menu?[key];
      if (mv is bool) return mv;
      final bv = business?[key];
      if (bv is bool) return bv;
    }
    return false;
  }

  int? _readInt(Map? menu, Map? business, {required List<String> keys}) {
    for (final key in keys) {
      final mv = menu?[key];
      if (mv is num) return mv.toInt();
      final bv = business?[key];
      if (bv is num) return bv.toInt();
    }
    return null;
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.ownerCopied)));
  }

  Future<void> _downloadQrPng(String link, String businessName) async {
    setState(() => _busy = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (kIsWeb) {
        await downloadBytes(
          bytes: bytes,
          fileName: '${businessName}_menu_qr.png',
          mimeType: 'image/png',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                name: '${businessName}_menu_qr.png',
                mimeType: 'image/png',
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadQrPdf(
    String link,
    String businessName, {
    required bool isA6,
  }) async {
    setState(() => _busy = true);
    try {
      final pdf = pw.Document();
      final pageFormat = isA6 ? PdfPageFormat.a6 : PdfPageFormat.a4;
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: link,
                  width: isA6 ? 140 : 220,
                  height: isA6 ? 140 : 220,
                ),
              ],
            ),
          ),
        ),
      );
      final bytes = await pdf.save();
      final fileName = '${businessName}_menu_qr_${isA6 ? 'a6' : 'a4'}.pdf';
      if (kIsWeb) {
        await downloadBytes(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                name: fileName,
                mimeType: 'application/pdf',
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _whatsAppText(
    String link, {
    required String businessName,
    bool? openNow,
    int? nearbyViews,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      if (nearbyViews != null && nearbyViews > 0)
        context.l10n.ownerNearbyViewed(nearbyViews),
      context.l10n.ownerCurrentMenuVerifiedPrices,
      link,
    ];
    return lines.join('\n');
  }

  String _twitterText(
    String link, {
    required String businessName,
    bool? openNow,
    int? nearbyViews,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      if (nearbyViews != null && nearbyViews > 0)
        context.l10n.ownerViewed(nearbyViews),
      context.l10n.ownerCurrentMenuVerifiedPricesColon,
      link,
    ];
    return lines.join('\n');
  }

  String _instagramText(
    String link, {
    required String businessName,
    bool? openNow,
  }) {
    final lines = <String>[
      businessName,
      if (openNow == true) context.l10n.openNow,
      context.l10n.ownerCurrentMenuVerifiedPrices,
      link,
    ];
    return lines.join('\n');
  }

  String _moatPitchText(
    String link, {
    required String businessName,
    required OwnerMoatSummary moat,
  }) {
    final evidencePct = (moat.evidenceRate * 100).round();
    final isTr = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('tr');
    if (isTr) {
      return '$businessName | Guven skoru ${moat.businessTrustScore}/100 | '
          'Menu guncellik ${moat.menuFreshnessScore}/100 | '
          'Fiyat dogruluk ${moat.priceAccuracyScore}/100 | '
          '${moat.uniqueValidators} dogrulayici | Kanit orani %$evidencePct | '
          'Bugun menu bakma ${moat.menuViewsToday}\n$link';
    }
    return '$businessName | Trust score ${moat.businessTrustScore}/100 | '
        'Menu freshness ${moat.menuFreshnessScore}/100 | '
        'Price accuracy ${moat.priceAccuracyScore}/100 | '
        '${moat.uniqueValidators} validators | Evidence rate %$evidencePct | '
        'Menu views today ${moat.menuViewsToday}\n$link';
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 6),
            Container(height: 10, width: 160, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.ownerAreYouSure),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.l10n.ownerConfirm),
        ),
      ],
    ),
  );
  return res ?? false;
}

String _localizedStatus(BuildContext context, String rawStatus) {
  return switch (rawStatus.trim().toLowerCase()) {
    'published' => context.l10n.ownerStatusPublished,
    'archived' => context.l10n.ownerStatusArchived,
    _ => context.l10n.ownerStatusDraft,
  };
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.menu,
    required this.onEdit,
    required this.onArchive,
    required this.onPublish,
  });

  final OwnerMenu menu;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menu.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.ownerMenuStatus(
                _localizedStatus(context, menu.status),
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  child: Text(context.l10n.duzenle),
                ),
                OutlinedButton(
                  onPressed: onArchive,
                  child: Text(context.l10n.ownerArchiveAction),
                ),
                FilledButton(
                  onPressed: onPublish,
                  child: Text(context.l10n.ownerPublishAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          child: Text(label),
        ),
      ],
    );
  }
}

class _ShareSectionLabel extends StatelessWidget {
  const _ShareSectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
