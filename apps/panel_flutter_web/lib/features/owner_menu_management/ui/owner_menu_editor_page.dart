import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/navigation/public_menu_url.dart';
import '../../owner_businesses/domain/owner_business_models.dart';
import '../../owner_businesses/domain/owner_business_providers.dart';
import '../domain/owner_menu_controller.dart';
import '../domain/owner_menu_models.dart';
import '../domain/owner_menu_safety_models.dart';
import '../../../shared/cache/invalidate_helpers.dart';
import 'owner_menu_error_mapper.dart';
import 'menu_editor_embed_flow.dart' deferred as embed_flow;
import 'menu_editor_share_flow.dart' deferred as share_flow;
import 'owner_section_editor_page.dart';
import 'widgets/menu_versions_sheet.dart';
import 'widgets/section_list_tile.dart';
import '../../../shared/ui/components/app_scaffold.dart';
import '../../../shared/ui/components/deferred_page_loader.dart';

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
  ProviderSubscription<AsyncValue<List<OwnerMenuSection>>>? _sectionsSub;

  @override
  void initState() {
    super.initState();
    _sectionsSub = ref.listenManual<AsyncValue<List<OwnerMenuSection>>>(
      ownerMenuSectionsProvider(widget.menu.id),
      (_, next) {
        if (next.hasValue && mounted) {
          setState(() => _optimisticSections = null);
        }
      },
      fireImmediately: true,
    );
    if (widget.openShareOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openSharePanel(widget.menu);
      });
    }
  }

  @override
  void dispose() {
    _sectionsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final l10n = context.l10n;
    final sectionsAsync = ref.watch(ownerMenuSectionsProvider(menu.id));
    final ownerBusinesses = ref.watch(ownerBusinessesProvider).maybeWhen(
      data: (items) => items,
      orElse: () => const <OwnerBusiness>[],
    );
    final currentBusiness = _findOwnerBusiness(ownerBusinesses, menu.businessId);
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
            icon: const Icon(Icons.qr_code_2_outlined),
            label: Text(context.l10n.adminBusinessesQrMenuAction),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _openVersionsPanel,
            icon: const Icon(Icons.history_outlined),
            label: Text(context.l10n.ownerMenuVersionsAction),
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
              onOpenQrStudio: () => _openSharePanel(menu),
              onOpenPublicMenu: () => _openPublicMenu(
                menu.businessId,
                publicSlug: currentBusiness?.publicSlug,
                slug: currentBusiness?.slug,
              ),
              onOpenVersions: _openVersionsPanel,
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
      context.l10n,
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
        builder: (_) => DeferredPageLoader(
          loadLibrary: embed_flow.loadLibrary,
          fullscreen: true,
          builder: (_) => embed_flow.MenuEditorPreviewPage(
            menuId: widget.menu.id,
          ),
        ),
      ),
    );
  }

  Future<void> _openSharePanel(OwnerMenu menu) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: DeferredPageLoader(
          loadLibrary: share_flow.loadLibrary,
          builder: (_) => share_flow.MenuEditorShareSheet(menu: menu),
        ),
      ),
    );
  }

  Future<void> _openVersionsPanel() async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: MenuVersionsSheet(menu: widget.menu),
      ),
    );
    if (result is! OwnerRestoreVersionResult || !mounted) return;
    invalidateMenu(
      ref,
      businessId: widget.menu.businessId,
      menuId: widget.menu.id,
    );
    ref.read(ownerMenusProvider(widget.menu.businessId).notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.ownerMenuVersionRestoreSuccess)),
    );
    Navigator.pop(context, true);
  }

  Future<void> _openPublicMenu(
    String businessId, {
    String? publicSlug,
    String? slug,
  }) async {
    final uri = Uri.parse(
      buildPublicMenuUrl(
        businessId: businessId,
        businessPublicSlug: publicSlug,
        businessSlug: slug,
      ),
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    required this.onOpenQrStudio,
    required this.onOpenPublicMenu,
    required this.onOpenVersions,
  });

  final OwnerMenu menu;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback? onPublish;
  final VoidCallback onOpenQrStudio;
  final VoidCallback onOpenPublicMenu;
  final VoidCallback onOpenVersions;

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
                OutlinedButton.icon(
                  onPressed: onOpenQrStudio,
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: Text(context.l10n.adminBusinessesQrMenuAction),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpenPublicMenu,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(context.l10n.ownerPublicMenuLinkAction),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenVersions,
                  icon: const Icon(Icons.history_outlined),
                  label: Text(context.l10n.ownerMenuVersionsAction),
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

OwnerBusiness? _findOwnerBusiness(
  List<OwnerBusiness> businesses,
  String businessId,
) {
  for (final business in businesses) {
    if (business.businessId == businessId) return business;
  }
  return null;
}
