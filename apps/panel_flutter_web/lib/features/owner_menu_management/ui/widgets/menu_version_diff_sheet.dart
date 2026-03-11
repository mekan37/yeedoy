import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/ui/components/owner_panel_feedback.dart';
import '../../data/owner_menu_safety_repository.dart';
import '../../domain/owner_menu_models.dart';
import '../../domain/owner_menu_safety_models.dart';

class MenuVersionDiffSheet extends ConsumerWidget {
  const MenuVersionDiffSheet({
    super.key,
    required this.menu,
    required this.snapshot,
  });

  final OwnerMenu menu;
  final OwnerMenuVersionSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_MenuVersionDiffData>(
      future: _load(ref),
      builder: (context, snapshotState) {
        if (snapshotState.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: OwnerPanelFeedback.loading(cardCount: 4),
          );
        }
        if (snapshotState.hasError || !snapshotState.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OwnerPanelFeedback.error(
              title: context.l10n.ownerMenuVersionDiffLoadErrorTitle,
              description: snapshotState.error.toString(),
              onRetry: () => Navigator.of(context).pop(),
              retryLabel: context.l10n.close,
            ),
          );
        }

        final data = snapshotState.data!;
        final sectionAdded = _added(data.current.sectionTitles, data.version.sectionTitles);
        final sectionRemoved = _added(data.version.sectionTitles, data.current.sectionTitles);
        final itemAdded = _added(data.current.itemNames, data.version.itemNames);
        final itemRemoved = _added(data.version.itemNames, data.current.itemNames);
        final hasAnyDiff =
            data.current.menuTitle.trim() != data.version.menuTitle.trim() ||
            (data.current.menuKind ?? '') != (data.version.menuKind ?? '') ||
            sectionAdded.isNotEmpty ||
            sectionRemoved.isNotEmpty ||
            itemAdded.isNotEmpty ||
            itemRemoved.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.ownerMenuVersionDiffTitle(snapshot.menuVersion),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.ownerMenuVersionDiffDescription,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              title: context.l10n.ownerMenuVersionDiffMenuMetaTitle,
              lines: [
                context.l10n.ownerMenuVersionDiffMenuTitleLine(
                  data.current.menuTitle,
                  data.version.menuTitle,
                ),
                context.l10n.ownerMenuVersionDiffMenuKindLine(
                  data.current.menuKind ?? context.l10n.ownerMenuVersionDiffEmptyValue,
                  data.version.menuKind ?? context.l10n.ownerMenuVersionDiffEmptyValue,
                ),
                context.l10n.ownerMenuVersionDiffCountLine(
                  context.l10n.ownerSections,
                  data.current.sectionCount,
                  data.version.sectionCount,
                ),
                context.l10n.ownerMenuVersionDiffCountLine(
                  context.l10n.ownerTrashFilterItems,
                  data.current.itemCount,
                  data.version.itemCount,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasAnyDiff)
              OwnerPanelFeedback.empty(
                icon: Icons.check_circle_outline,
                title: context.l10n.ownerMenuVersionDiffNoChangesTitle,
                description: context.l10n.ownerMenuVersionDiffNoChangesDescription,
              )
            else ...[
              _DiffListCard(
                title: context.l10n.ownerMenuVersionDiffSectionsAddedTitle,
                items: sectionAdded,
              ),
              const SizedBox(height: 12),
              _DiffListCard(
                title: context.l10n.ownerMenuVersionDiffSectionsRemovedTitle,
                items: sectionRemoved,
              ),
              const SizedBox(height: 12),
              _DiffListCard(
                title: context.l10n.ownerMenuVersionDiffItemsAddedTitle,
                items: itemAdded,
              ),
              const SizedBox(height: 12),
              _DiffListCard(
                title: context.l10n.ownerMenuVersionDiffItemsRemovedTitle,
                items: itemRemoved,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<_MenuVersionDiffData> _load(WidgetRef ref) async {
    final repo = ref.read(ownerMenuSafetyRepositoryProvider);
    final results = await Future.wait([
      repo.getMenuVersionDetail(snapshotId: snapshot.snapshotId),
      repo.getCurrentMenuStructure(menuId: menu.id),
    ]);
    return _MenuVersionDiffData(
      version: results[0] as OwnerMenuVersionDetail,
      current: results[1] as OwnerMenuStructureSummary,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final line in lines) ...[
            Text(
              line,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _DiffListCard extends StatelessWidget {
  const _DiffListCard({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              context.l10n.ownerMenuVersionDiffEmptyList,
              style: const TextStyle(color: AppColors.muted),
            )
          else
            for (final item in items.take(8)) ...[
              Text('• $item'),
              const SizedBox(height: 4),
            ],
          if (items.length > 8) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.ownerMenuVersionDiffMoreItems(items.length - 8),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuVersionDiffData {
  const _MenuVersionDiffData({
    required this.version,
    required this.current,
  });

  final OwnerMenuVersionDetail version;
  final OwnerMenuStructureSummary current;
}

List<String> _added(List<String> baseline, List<String> comparison) {
  final baselineSet = baseline.map((item) => item.trim().toLowerCase()).toSet();
  return comparison
      .where((item) => !baselineSet.contains(item.trim().toLowerCase()))
      .toList(growable: false);
}
