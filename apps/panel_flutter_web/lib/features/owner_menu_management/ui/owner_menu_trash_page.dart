import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/business_rbac.dart';
import '../../../shared/ui/components/app_card.dart';
import '../../../shared/ui/components/app_filter_chip.dart';
import '../../../shared/ui/components/owner_business_guard.dart';
import '../../../shared/ui/components/panel_page_header.dart';
import '../../../shared/ui/components/owner_panel_feedback.dart';
import '../../owner_businesses/domain/owner_business_state.dart';
import '../data/owner_menu_safety_repository.dart';
import '../domain/owner_menu_safety_models.dart';

final _ownerTrashProvider =
    FutureProvider.autoDispose.family<List<OwnerTrashEntry>, String>((
      ref,
      businessId,
    ) {
      return ref.read(ownerMenuSafetyRepositoryProvider).listTrash(
            businessId: businessId,
          );
    });

class OwnerMenuTrashPage extends ConsumerStatefulWidget {
  const OwnerMenuTrashPage({super.key, this.businessId});

  final String? businessId;

  @override
  ConsumerState<OwnerMenuTrashPage> createState() => _OwnerMenuTrashPageState();
}

class _OwnerMenuTrashPageState extends ConsumerState<OwnerMenuTrashPage> {
  @override
  Widget build(BuildContext context) {
    final selectedBusinessId = widget.businessId?.trim().isNotEmpty == true
        ? widget.businessId!.trim()
        : (ref.watch(selectedOwnerBusinessIdProvider) ?? '');
    if (selectedBusinessId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OwnerPanelFeedback.empty(
          icon: Icons.delete_sweep_outlined,
          title: context.l10n.ownerTrashMissingBusinessTitle,
          description: context.l10n.ownerTrashMissingBusinessDescription,
        ),
      );
    }

    return OwnerBusinessGuard(
      businessId: selectedBusinessId,
      permission: BusinessPermission.businessRead,
      builder: (context, ref) =>
          OwnerMenuTrashPanel(businessId: selectedBusinessId),
    );
  }
}

enum OwnerTrashSortMode { newest, oldest, title, type }

class OwnerMenuTrashPanel extends ConsumerStatefulWidget {
  const OwnerMenuTrashPanel({
    super.key,
    required this.businessId,
    this.title,
    this.description,
  });

  final String businessId;
  final String? title;
  final String? description;

  @override
  ConsumerState<OwnerMenuTrashPanel> createState() => _OwnerMenuTrashPanelState();
}

class _OwnerMenuTrashPanelState extends ConsumerState<OwnerMenuTrashPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  OwnerTrashEntityType? _filter;
  OwnerTrashSortMode _sortMode = OwnerTrashSortMode.newest;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trashAsync = ref.watch(_ownerTrashProvider(widget.businessId));
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_ownerTrashProvider(widget.businessId)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          PanelPageHeader(
            eyebrow: 'Owner',
            title: Text(widget.title ?? l10n.ownerTrashTitle),
            description: widget.description ?? l10n.ownerTrashDescription,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.ownerTrashSearchLabel,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppFilterChip(
                            label: l10n.ownerTrashFilterAll,
                            selected: _filter == null,
                            onTap: () => setState(() => _filter = null),
                          ),
                          AppFilterChip(
                            label: l10n.ownerTrashFilterMenus,
                            selected: _filter == OwnerTrashEntityType.menu,
                            onTap: () => setState(() => _filter = OwnerTrashEntityType.menu),
                          ),
                          AppFilterChip(
                            label: l10n.ownerTrashFilterItems,
                            selected: _filter == OwnerTrashEntityType.item,
                            onTap: () => setState(() => _filter = OwnerTrashEntityType.item),
                          ),
                          AppFilterChip(
                            label: l10n.ownerTrashFilterPhotos,
                            selected: _filter == OwnerTrashEntityType.photo,
                            onTap: () => setState(() => _filter = OwnerTrashEntityType.photo),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<OwnerTrashSortMode>(
                        initialValue: _sortMode,
                        decoration: InputDecoration(
                          labelText: l10n.ownerTrashSortLabel,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: OwnerTrashSortMode.newest,
                            child: Text(l10n.ownerTrashSortNewest),
                          ),
                          DropdownMenuItem(
                            value: OwnerTrashSortMode.oldest,
                            child: Text(l10n.ownerTrashSortOldest),
                          ),
                          DropdownMenuItem(
                            value: OwnerTrashSortMode.title,
                            child: Text(l10n.ownerTrashSortTitle),
                          ),
                          DropdownMenuItem(
                            value: OwnerTrashSortMode.type,
                            child: Text(l10n.ownerTrashSortType),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sortMode = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                trashAsync.when(
            loading: () => const OwnerPanelFeedback.loading(cardCount: 6),
            error: (error, _) => OwnerPanelFeedback.error(
              title: l10n.ownerTrashLoadErrorTitle,
              description: AppErrorMapper.message(error),
              onRetry: () => ref.invalidate(_ownerTrashProvider(widget.businessId)),
            ),
            data: (entries) {
              final visible = _visibleEntries(entries);
              if (visible.isEmpty) {
                return OwnerPanelFeedback.empty(
                  icon: Icons.delete_sweep_outlined,
                  title: l10n.ownerTrashEmptyTitle,
                  description: l10n.ownerTrashEmptyDescription,
                );
              }
              return Column(
                children: [
                  for (final entry in visible) ...[
                    _TrashCard(
                      entry: entry,
                      onRestore: () => _restore(widget.businessId, entry),
                      onDeleteForever: () => _deleteForever(widget.businessId, entry),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<OwnerTrashEntry> _visibleEntries(List<OwnerTrashEntry> entries) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = entries.where((entry) {
      if (_filter != null && entry.entityType != _filter) return false;
      if (query.isEmpty) return true;
      final haystack = '${entry.title} ${entry.subtitle}'.toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case OwnerTrashSortMode.oldest:
          return (a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        case OwnerTrashSortMode.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case OwnerTrashSortMode.type:
          return a.entityType.name.compareTo(b.entityType.name);
        case OwnerTrashSortMode.newest:
          return (b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      }
    });
    return filtered;
  }

  Future<void> _restore(String businessId, OwnerTrashEntry entry) async {
    final ok = await _confirm(
      context,
      context.l10n.ownerTrashRestoreConfirm(_trashLabel(context, entry.entityType)),
    );
    if (!ok) return;
    try {
      await ref.read(ownerMenuSafetyRepositoryProvider).restoreTrashEntry(entry);
      ref.invalidate(_ownerTrashProvider(businessId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerTrashRestoreSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    }
  }

  Future<void> _deleteForever(String businessId, OwnerTrashEntry entry) async {
    final ok = await _confirm(
      context,
      context.l10n.ownerTrashDeleteForeverConfirm(_trashLabel(context, entry.entityType)),
    );
    if (!ok) return;
    try {
      await ref.read(ownerMenuSafetyRepositoryProvider).forceDeleteTrashEntry(entry);
      ref.invalidate(_ownerTrashProvider(businessId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownerTrashDeleteForeverSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorMapper.message(error))),
      );
    }
  }

  String _trashLabel(BuildContext context, OwnerTrashEntityType type) {
    switch (type) {
      case OwnerTrashEntityType.menu:
        return context.l10n.ownerTrashEntityMenu;
      case OwnerTrashEntityType.item:
        return context.l10n.ownerTrashEntityItem;
      case OwnerTrashEntityType.photo:
        return context.l10n.ownerTrashEntityPhoto;
    }
  }
}

class _TrashCard extends StatelessWidget {
  const _TrashCard({
    required this.entry,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final OwnerTrashEntry entry;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(_iconFor(entry.entityType)),
          ),
          const SizedBox(width: 12),
          if ((entry.photoUrl ?? '').trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                entry.photoUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (entry.occurredAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.ownerTrashOccurredAt(
                      _fmt(entry.occurredAt!),
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onRestore,
                child: Text(context.l10n.ownerTrashRestoreAction),
              ),
              FilledButton.tonal(
                onPressed: onDeleteForever,
                child: Text(context.l10n.ownerTrashDeleteForeverAction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(OwnerTrashEntityType type) {
    switch (type) {
      case OwnerTrashEntityType.menu:
        return Icons.menu_book_outlined;
      case OwnerTrashEntityType.item:
        return Icons.fastfood_outlined;
      case OwnerTrashEntityType.photo:
        return Icons.photo_outlined;
    }
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
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
  return ok ?? false;
}

String _fmt(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}
