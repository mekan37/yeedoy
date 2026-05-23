import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/collab_list_models.dart';
import '../domain/collab_list_providers.dart';

class CollabListDetailPage extends ConsumerWidget {
  const CollabListDetailPage({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final detailAsync = ref.watch(collabListDetailProvider(listId));
    final session = ref.watch(sessionProvider);
    final userId = session?.user.id ?? '';

    return AppScaffold(
      appBar: AppAppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.list.name),
          orElse: () => Text(t.collabListsTitle),
        ),
        actions: [
          if (detailAsync.hasValue)
            PopupMenuButton<String>(
              onSelected: (action) =>
                  _handleMenuAction(context, ref, action, detailAsync.value!, userId),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  child: Text(t.collabListShare),
                ),
                if (detailAsync.value?.list.ownerId == userId)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      t.collabListDelete,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'leave',
                    child: Text(t.collabListLeave),
                  ),
              ],
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppErrorMapper.message(e)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(collabListDetailProvider(listId).notifier).refresh(),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
        data: (detail) => _DetailBody(
          detail: detail,
          listId: listId,
          userId: userId,
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    CollabListDetail detail,
    String userId,
  ) async {
    final t = AppLocalizations.of(context);
    switch (action) {
      case 'share':
        final token = detail.list.inviteToken;
        final link = 'yeedoy://collab-lists/join?token=$token';
        await Clipboard.setData(ClipboardData(text: link));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.collabListLinkCopied)),
          );
        }
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.collabListDelete),
            content: Text(t.collabListDeleteConfirm),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.delete,
                    style: const TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await ref.read(myCollabListsProvider.notifier).deleteList(listId);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorMapper.message(e))),
              );
            }
          }
        }
      case 'leave':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.collabListLeave),
            content: Text(t.collabListLeaveConfirm),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.collabListLeave),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await ref.read(myCollabListsProvider.notifier).leaveList(listId);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorMapper.message(e))),
              );
            }
          }
        }
    }
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.detail,
    required this.listId,
    required this.userId,
  });

  final CollabListDetail detail;
  final String listId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final items = detail.items;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(collabListDetailProvider(listId).notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (detail.list.description?.isNotEmpty == true) ...[
            Text(
              detail.list.description!,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
          ],
          if (items.isEmpty)
            Center(
              child: AppEmptyState(
                icon: Icons.restaurant_menu_outlined,
                title: t.collabListItemsEmpty,
                description: t.collabListItemsEmptyDesc,
              ),
            )
          else
            for (final item in items) ...[
              RepaintBoundary(
                child: _ItemCard(
                  item: item,
                  listId: listId,
                  isOwner: detail.list.ownerId == userId,
                  isAdder: item.addedBy == userId,
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({
    required this.item,
    required this.listId,
    required this.isOwner,
    required this.isAdder,
  });

  final CollabListItem item;
  final String listId;
  final bool isOwner;
  final bool isAdder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final notifier = ref.read(collabListDetailProvider(listId).notifier);

    return AppCard(
      onTap: () => context.push('/b/${item.businessId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName ?? item.businessId,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (item.businessCategory != null ||
                        item.businessDistrict != null)
                      Text(
                        [
                          if (item.businessCategory != null)
                            item.businessCategory,
                          if (item.businessDistrict != null &&
                              item.businessCity != null)
                            '${item.businessDistrict}, ${item.businessCity}',
                        ].join(' • '),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    if (item.note?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.note!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              if (isOwner || isAdder)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.muted),
                  tooltip: t.remove,
                  onPressed: () async {
                    try {
                      await notifier.removeItem(item.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppErrorMapper.message(e))),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _VoteButton(
                icon: Icons.thumb_up_outlined,
                activeIcon: Icons.thumb_up,
                active: item.myVote == 1,
                onTap: () async {
                  try {
                    await notifier.vote(item.id, item.myVote == 1 ? 0 : 1);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppErrorMapper.message(e))),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 4),
              Text(
                item.score > 0
                    ? '+${item.score}'
                    : item.score.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: item.score > 0
                      ? AppColors.success
                      : item.score < 0
                          ? AppColors.danger
                          : AppColors.muted,
                ),
              ),
              const SizedBox(width: 4),
              _VoteButton(
                icon: Icons.thumb_down_outlined,
                activeIcon: Icons.thumb_down,
                active: item.myVote == -1,
                onTap: () async {
                  try {
                    await notifier.vote(
                        item.id, item.myVote == -1 ? 0 : -1);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppErrorMapper.message(e))),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          active ? activeIcon : icon,
          size: 20,
          color: active ? AppColors.primary : AppColors.muted,
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const AppSkeletonCard(),
    );
  }
}
