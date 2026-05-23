import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/config/product_guardrail_overrides.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../data/reviews_repository.dart';
import '../domain/business_reviews_controller.dart';
import '../../shared/ui/widgets/report_bottom_sheet.dart';
import '../domain/my_votes_provider.dart';
import '../domain/review.dart';
import '../domain/review_catalog.dart';
import '../domain/review_rating_summary.dart';
import '../domain/reviews_provider.dart';
import '../../auth/domain/auth_providers.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_hero_header.dart';

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
              subtitle: t.businessReviewsCommunityExperiences,
              icon: Icons.rate_review_outlined,
            ),
            const SizedBox(height: 12),
            _RatingSummarySection(businessId: widget.businessId),
            const SizedBox(height: 12),
            Text(
              guardrails.ownerCanDeleteReviews
                  ? t.businessReviewsOwnerCanModerate
                  : t.businessReviewsOwnersCanOnlyReply,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'newest', label: Text(t.sortNewest)),
                ButtonSegment(value: 'helpful', label: Text(t.sortMostHelpful)),
                ButtonSegment(
                  value: 'verified',
                  label: Text(t.sortVerified),
                  icon: const Icon(Icons.verified_rounded, size: 14),
                ),
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
                    child: Text(t.retry),
                  ),
                ],
              ),
            if (st.isLoading && st.items.isEmpty) ...[
              const _ReviewsSkeleton(),
            ] else if (st.items.isEmpty) ...[
              _EmptyReviews(),
            ] else ...[
              votedIdsAsync.when(
                loading: () => const _ReviewsSkeleton(),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(AppErrorMapper.message(e)),
                ),
                data: (votedIds) {
                  final reviewIds =
                      st.items.map((r) => r.id).toList();
                  final repliesAsync = ref.watch(
                    reviewRepliesBatchProvider(reviewIds),
                  );
                  final replies = repliesAsync.asData?.value ?? {};
                  return Column(
                    children: [
                      for (final r in st.items) ...[
                        RepaintBoundary(
                          child: _ReviewCard(
                            review: r,
                            showQuality: st.sort == 'helpful',
                            isVoted: votedIds.contains(r.id),
                            ownerReply: replies[r.id],
                            onToggleHelpful: () => _toggleHelpful(
                              context,
                              r,
                              isVoted: votedIds.contains(r.id),
                            ),
                            onReport: () =>
                                _openReportSheet(context, reviewId: r.id),
                          ),
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
      final repo = ref.read(reviewsRepositoryProvider);
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

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.review,
    required this.showQuality,
    required this.isVoted,
    required this.onToggleHelpful,
    required this.onReport,
    this.ownerReply,
  });

  final Review review;
  final bool showQuality;
  final bool isVoted;
  final VoidCallback onToggleHelpful;
  final VoidCallback onReport;
  /// Batch reply map entry: {id, content, created_at}
  final Map<String, dynamic>? ownerReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(reviewPhotosProvider(review.id));
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
                if (review.verifiedVisit) ...[
                  _BadgeChip(
                    label: 'Doğrulanmış Ziyaret',
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                ],
                if (review.qualityScore >= Review.qualityBadgeThreshold) ...[
                  _BadgeChip(
                    label: 'Kaliteli Yorum',
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  _fmtDate(review.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'report') onReport();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text(AppLocalizations.of(context).report),
                    ),
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
            if (review.hasCriteriaRatings) ...[
              const SizedBox(height: 10),
              _CriteriaDisplay(criteriaRatings: review.criteriaRatings),
            ],
            photosAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (urls) {
                if (urls.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _ReviewPhotoGrid(urls: urls),
                );
              },
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
                      AppLocalizations.of(context).businessReviewsQualityLabel(
                        review.qualityScore.toStringAsFixed(1),
                      ),
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
                        label: Text(
                          AppLocalizations.of(context).helpfulCount(
                            review.helpfulCount,
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: onToggleHelpful,
                        icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                        label: Text(
                          AppLocalizations.of(context).helpfulCount(
                            review.helpfulCount,
                          ),
                        ),
                      ),
              ],
            ),
            if (ownerReply != null) ...[
              const SizedBox(height: 10),
              _OwnerReplyBubble(reply: ownerReply!),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerReplyBubble extends StatelessWidget {
  const _OwnerReplyBubble({required this.reply});
  final Map<String, dynamic> reply;

  @override
  Widget build(BuildContext context) {
    final content = reply['content'] as String? ?? '';
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                t.businessReviewsOwnersCanOnlyReply.contains('sahibi')
                    ? 'İşletme Yanıtı'
                    : 'Owner Response',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _ReviewPhotoGrid extends StatelessWidget {
  const _ReviewPhotoGrid({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (context, i) => const SizedBox(width: 6),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _openFullscreen(context, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              urls[i],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, e, stack) => Container(
                width: 80,
                height: 80,
                color: AppColors.card,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (context, e, stack) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary card shown at top of reviews page: overall score + criteria bars.
class _RatingSummarySection extends ConsumerWidget {
  const _RatingSummarySection({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewRatingSummaryProvider(businessId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.ratingCount == 0) return const SizedBox.shrink();
        return _RatingSummaryCard(summary: summary);
      },
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.summary});
  final ReviewRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final overall = summary.avgOverallRating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (overall != null) ...[
                  Text(
                    overall.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniStars(rating: overall),
                      Text(
                        t.reviewsCount(summary.ratingCount),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (summary.hasDistribution) ...[
              const SizedBox(height: 12),
              _StarDistributionBars(summary: summary),
            ],
            if (summary.hasCriteriaAverages) ...[
              const SizedBox(height: 12),
              for (final def in ReviewCatalog.definitions) ...[
                _CriteriaBarRow(
                  label: def.label(t),
                  value: summary.criteriaAverages[def.criterion],
                ),
                const SizedBox(height: 6),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal bar chart for 5→1 star distribution, e.g. ████░ 72%
class _StarDistributionBars extends StatelessWidget {
  const _StarDistributionBars({required this.summary});
  final ReviewRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.distributionDesc.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    return Column(
      children: List.generate(5, (i) {
        final stars = 5 - i;
        final count = summary.distributionDesc[i];
        final fraction = count / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$stars',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.star,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '${(fraction * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MiniStars extends StatelessWidget {
  const _MiniStars({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rating;
        final halfFilled = !filled && (i + 0.5) < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : halfFilled
                  ? Icons.star_half_rounded
                  : Icons.star_border_rounded,
          size: 16,
          color: AppColors.star,
        );
      }),
    );
  }
}

/// Bar-style row for a single criterion average, e.g. "Lezzet ████░ 4.2"
class _CriteriaBarRow extends StatelessWidget {
  const _CriteriaBarRow({required this.label, required this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final fraction = (value! / 5.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.star),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            value!.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
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
    final t = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(
        child: Text(
          t.businessReviewsEmpty,
          style: TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _CriteriaDisplay extends StatelessWidget {
  const _CriteriaDisplay({required this.criteriaRatings});
  final Map<ReviewRatingCriterion, int?> criteriaRatings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filled = ReviewCatalog.definitions
        .where((d) => criteriaRatings[d.criterion] != null)
        .toList();
    if (filled.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final def in filled)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                def.label(t),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final val = criteriaRatings[def.criterion]!;
                return Icon(
                  i < val ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 12,
                  color: i < val ? AppColors.star : AppColors.border,
                );
              }),
            ],
          ),
      ],
    );
  }
}

/// Compact pill badge used inside ReviewCard for verified visit & quality score.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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



