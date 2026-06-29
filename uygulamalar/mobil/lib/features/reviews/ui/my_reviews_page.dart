import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../auth/domain/auth_providers.dart';
import '../../shared/ui/components/app_scaffold.dart';
import '../domain/my_review_entry.dart';
import '../domain/reviews_provider.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Yorumlarım')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yorumlarını görmek için giriş yap.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/login?redirect=/my-reviews'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    final reviewsAsync = ref.watch(myReviewsProvider(user.id));

    return AppScaffold(
      appBar: AppBar(title: const Text('Yorumlarım')),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppErrorMapper.message(e),
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myReviewsProvider(user.id)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Henüz yorum yapmadın.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reviews.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) =>
                _MyReviewTile(entry: reviews[index]),
          );
        },
      ),
    );
  }
}

class _MyReviewTile extends StatelessWidget {
  const _MyReviewTile({required this.entry});

  final MyReviewEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/b/${entry.businessId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.businessName.isNotEmpty
                  ? entry.businessName
                  : entry.businessId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < entry.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < entry.rating
                        ? AppColors.star
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtDate(entry.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            if ((entry.title ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
