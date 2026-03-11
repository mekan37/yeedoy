import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/ui/components/owner_panel_feedback.dart';
import '../../data/owner_menu_safety_repository.dart';
import '../../domain/owner_menu_models.dart';
import '../../domain/owner_menu_safety_models.dart';
import 'menu_version_diff_sheet.dart';

final _menuVersionsProvider =
    FutureProvider.autoDispose.family<List<OwnerMenuVersionSnapshot>, String>((
      ref,
      menuId,
    ) {
      return ref.read(ownerMenuSafetyRepositoryProvider).listMenuVersions(
            menuId: menuId,
          );
    });

class MenuVersionsSheet extends ConsumerWidget {
  const MenuVersionsSheet({super.key, required this.menu});

  final OwnerMenu menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(_menuVersionsProvider(menu.id));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: versionsAsync.when(
        loading: () => const OwnerPanelFeedback.loading(cardCount: 4),
        error: (error, _) => OwnerPanelFeedback.error(
          title: context.l10n.ownerMenuVersionsLoadErrorTitle,
          description: error.toString(),
          onRetry: () => ref.invalidate(_menuVersionsProvider(menu.id)),
        ),
        data: (versions) {
          if (versions.isEmpty) {
            return OwnerPanelFeedback.empty(
              icon: Icons.history_outlined,
              title: context.l10n.ownerMenuVersionsEmptyTitle,
              description: context.l10n.ownerMenuVersionsEmptyDescription,
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              Text(
                context.l10n.ownerMenuVersionsTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.ownerMenuVersionsDescription,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              for (final version in versions) ...[
                _VersionCard(
                  version: version,
                  onViewDiff: () => _openDiff(context, version),
                  onRestore: () => _restore(context, ref, version),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    OwnerMenuVersionSnapshot version,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.ownerMenuVersionRestoreAction),
        content: Text(
          context.l10n.ownerMenuVersionRestoreConfirm(version.menuVersion),
        ),
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
    if (ok != true || !context.mounted) return;
    try {
      final result = await ref.read(ownerMenuSafetyRepositoryProvider).restoreMenuVersion(
            snapshotId: version.snapshotId,
            archiveCurrentMenuId: menu.id,
          );
      if (!context.mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _openDiff(
    BuildContext context,
    OwnerMenuVersionSnapshot version,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: MenuVersionDiffSheet(
          menu: menu,
          snapshot: version,
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.onViewDiff,
    required this.onRestore,
  });

  final OwnerMenuVersionSnapshot version;
  final VoidCallback onViewDiff;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.ownerMenuVersionLabel(version.menuVersion),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton(
                onPressed: onViewDiff,
                child: Text(context.l10n.ownerMenuVersionDiffAction),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onRestore,
                child: Text(context.l10n.ownerMenuVersionRestoreAction),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.ownerMenuVersionSummary(
              _reasonLabel(context, version.snapshotReason),
              _fmt(version.createdAt),
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.ownerMenuVersionCounts(
              version.sectionCount,
              version.itemCount,
            ),
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(BuildContext context, String reason) {
    switch (reason.trim().toLowerCase()) {
      case 'restore':
        return context.l10n.ownerMenuVersionReasonRestore;
      case 'publish':
      default:
        return context.l10n.ownerMenuVersionReasonPublish;
    }
  }
}

String _fmt(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
}
