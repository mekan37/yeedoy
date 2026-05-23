import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../domain/ortak_liste_modelleri.dart';
import '../domain/ortak_liste_saglayicilari.dart';

class CollabListsPage extends ConsumerWidget {
  const CollabListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(myCollabListsProvider);
    return AppScaffold(
      appBar: AppAppBar(
        title: Text(t.collabListsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t.collabListCreate,
            onPressed: () => _showCreateSheet(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const _ListsSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppErrorMapper.message(e)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(myCollabListsProvider.notifier).refresh(),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
        data: (lists) {
          if (lists.isEmpty) {
            return AppEmptyState(
              icon: Icons.checklist_rounded,
              title: t.collabListsEmpty,
              description: t.collabListsEmptyDesc,
              ctaLabel: t.collabListCreate,
              onCta: () => _showCreateSheet(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myCollabListsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: lists.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => RepaintBoundary(
                child: _CollabListTile(
                  list: lists[index],
                  onTap: () => context.push('/ortak-listeler/${lists[index].id}'),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).collabListCreate),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.collabListCreate,
                  style: context.sectionTitleStyle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: t.collabListNameLabel),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? t.required : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  maxLength: 280,
                  maxLines: 2,
                  decoration:
                      InputDecoration(labelText: t.collabListDescLabel),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: t.cancel,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: t.create,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            await ref
                                .read(myCollabListsProvider.notifier)
                                .createList(
                                  name: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                );
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(AppErrorMapper.message(e))),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollabListTile extends StatelessWidget {
  const _CollabListTile({required this.list, required this.onTap});

  final CollabList list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (list.description != null && list.description!.isNotEmpty)
                  Text(
                    list.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _ListsSkeleton extends StatelessWidget {
  const _ListsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const AppSkeletonCard(),
    );
  }
}




