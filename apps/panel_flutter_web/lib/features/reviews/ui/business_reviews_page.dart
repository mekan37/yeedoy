import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/reviews_repo.dart';
import '../domain/business_reviews_controller.dart';
import '../../../src/ui/widgets/report_bottom_sheet.dart';
import '../domain/my_votes_provider.dart';
import '../domain/review.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../../../src/ui/components/app_hero_header.dart';

class BusinessReviewsPage extends ConsumerStatefulWidget {
  const BusinessReviewsPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<BusinessReviewsPage> createState() =>
      _BusinessReviewsPageState();
}

class _BusinessReviewsPageState extends ConsumerState<BusinessReviewsPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref
            .read(businessReviewsProvider(widget.businessId).notifier)
            .loadMore();
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
    final t = AppLocalizations.of(context);
    final st = ref.watch(businessReviewsProvider(widget.businessId));
    final guardrails = ref.watch(productGuardrailOverridesProvider);
    final user = ref.watch(userProvider);
    final votesKey = MyVotesKey(
      userId: user?.id ?? '',
      reviewIdsKey: st.items.map((e) => e.id).join(','),
    );
    final votedIdsAsync = ref.watch(myVotesProvider(votesKey));

    return AppScaffold(
      appBar: AppBar(title: Text(t.reviewsCount(st.items.length))),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(businessReviewsProvider(widget.businessId).notifier)
            .refresh(),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            AppHeroHeader(
              title: t.reviewsCount(st.items.length),
              subtitle: 'Toplulugun deneyimleri',
              icon: Icons.rate_review_outlined,
            ),
            const SizedBox(height: 12),
            Text(
              guardrails.ownerCanDeleteReviews
                  ? 'Owner yorumlari yönetebilir.'
                  : 'Yorumlar silinmez. İşletme sahipleri sadece yanıtlayabilir.',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'newest', label: Text('En Yeni')),
                ButtonSegment(value: 'helpful', label: Text('En Faydalılar')),
              ],
              selected: {st.sort},
              onSelectionChanged: (s) => ref
                  .read(businessReviewsProvider(widget.businessId).notifier)
                  .setSort(s.first),
            ),
            const SizedBox(height: 12),
            if (st.error != null)
              Row(
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
                        .read(
                          businessReviewsProvider(widget.businessId).notifier,
                        )
                        .refresh(),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            if (st.isLoading && st.items.isEmpty) ...[
              const _ReviewsSkeleton(),
            ] else if (st.items.isEmpty) ...[
              const _EmptyReviews(),
            ] else ...[
              votedIdsAsync.when(
                loading: () => const _ReviewsSkeleton(),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(AppErrorMapper.message(e)),
                ),
                data: (votedIds) {
                  return Column(
                    children: [
                      for (final r in st.items) ...[
                        _ReviewCard(
                          review: r,
                          showQuality: st.sort == 'helpful',
                          isVoted: votedIds.contains(r.id),
                          onToggleHelpful: () => _toggleHelpful(
                            context,
                            r,
                            isVoted: votedIds.contains(r.id),
                          ),
                          onReport: () =>
                              _openReportSheet(context, reviewId: r.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
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

  Future<void> _toggleHelpful(
    BuildContext context,
    Review r, {
    required bool isVoted,
  }) async {
    final user = ref.read(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      context.go('/login?redirect=$redirect');
      return;
    }

    try {
      final repo = ref.read(reviewsRepoProvider);
      if (isVoted) {
        await repo.unvoteHelpful(reviewId: r.id, userId: user.id);
      } else {
        await repo.voteHelpful(reviewId: r.id, userId: user.id);
      }
      ref.read(businessReviewsProvider(widget.businessId).notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(e))));
      }
    }
  }

  void _openReportSheet(BuildContext context, {required String reviewId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReportBottomSheet.review(
        reviewId: reviewId,
        redirectUrl: GoRouterState.of(context).uri.toString(),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.showQuality,
    required this.isVoted,
    required this.onToggleHelpful,
    required this.onReport,
  });

  final Review review;
  final bool showQuality;
  final bool isVoted;
  final VoidCallback onToggleHelpful;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Stars(rating: review.rating),
                const Spacer(),
                Text(
                  _fmtDate(review.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'report') onReport();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'report', child: Text('Bildir')),
                  ],
                ),
              ],
            ),
            if ((review.title ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.title!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              review.content,
              style: const TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showQuality) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Kalite ${review.qualityScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                isVoted
                    ? FilledButton.icon(
                        onPressed: onToggleHelpful,
                        icon: const Icon(Icons.thumb_up_alt),
                        label: Text('Faydalı (${review.helpfulCount})'),
                      )
                    : OutlinedButton.icon(
                        onPressed: onToggleHelpful,
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                        label: Text('Faydalı (${review.helpfulCount})'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 8),
            Container(height: 10, width: 160, color: AppColors.card),
            const SizedBox(height: 8),
            Container(height: 10, width: 120, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(
        child: Text(
          'Henüz yorum yok, istersen ilk yorumu sen yaz.',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: filled ? AppColors.star : AppColors.border,
        );
      }),
    );
  }
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

