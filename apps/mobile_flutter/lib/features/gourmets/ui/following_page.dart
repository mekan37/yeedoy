import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/gourmet_controllers.dart';
import '../domain/gourmet_user.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';

class FollowingPage extends ConsumerStatefulWidget {
  const FollowingPage({super.key});

  @override
  ConsumerState<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends ConsumerState<FollowingPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(gourmetFollowingProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final st = ref.watch(gourmetFollowingProvider);
    final user = ref.watch(userProvider);

    return AppScaffold(
      appBar: AppBar(title: Text(t.followingPageTitle)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(gourmetFollowingProvider.notifier).loadInitial(),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppErrorMapper.message(st.error),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(gourmetFollowingProvider.notifier)
                          .loadInitial(),
                      child: Text(t.retry),
                    ),
                  ],
                ),
              ),
            if (st.loading && st.items.isEmpty)
              const _GourmetSkeleton()
            else if (!st.loading && st.items.isEmpty)
              _EmptyState(message: t.followingPageEmpty)
            else ...[
              for (final g in st.items) ...[
                _GourmetTile(
                  user: g,
                  onUnfollow: () async {
                    if (user == null) {
                      context.go('/login?redirect=/following');
                      return;
                    }
                    try {
                      await ref
                          .read(gourmetFollowingProvider.notifier)
                          .toggleFollow(g);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppErrorMapper.message(e))),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (st.isLoadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _GourmetTile extends StatelessWidget {
  const _GourmetTile({required this.user, required this.onUnfollow});

  final GourmetUser user;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl.isEmpty
                  ? null
                  : NetworkImage(user.avatarUrl),
              child: user.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.favoritesFollowersChip(user.followerCount),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onUnfollow,
              child: Text(t.followingPageUnfollowAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _GourmetSkeleton extends StatelessWidget {
  const _GourmetSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (i) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        );
      }),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 10, color: AppColors.card),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 120, color: AppColors.card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: AppColors.muted)),
    );
  }
}

