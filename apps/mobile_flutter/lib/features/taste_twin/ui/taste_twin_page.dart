import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../auth/domain/auth_providers.dart';
import '../../gourmets/domain/gourmet_controllers.dart';
import '../domain/taste_twin_controllers.dart';
import '../domain/taste_twin_models.dart';

class TasteTwinPage extends ConsumerWidget {
  const TasteTwinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    if (user == null) {
      return AppScaffold(
        appBar: AppBar(title: Text(t.tasteTwinTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.tasteTwinLoginRequired),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => context.go('/login?redirect=/taste-twin'),
                child: Text(t.login),
              ),
            ],
          ),
        ),
      );
    }

    final st = ref.watch(tasteMatchesProvider);

    return AppScaffold(
      appBar: AppBar(title: Text(t.tasteTwinTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(tasteMatchesProvider.notifier).loadInitial(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              t.tasteTwinSubtitle,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
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
                      onPressed: () =>
                          ref.read(tasteMatchesProvider.notifier).loadInitial(),
                      child: Text(t.retry),
                    ),
                  ],
                ),
              ),
            if (st.loading && st.items.isEmpty)
              const _MatchSkeleton()
            else if (!st.loading && st.items.isEmpty)
              _EmptyState(message: t.tasteTwinNoMatches)
            else ...[
              for (final m in st.items) ...[
                _MatchCard(match: m),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});
  final TasteMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final profileAsync = ref.watch(publicProfileProvider(match.userId));
    final avatarUrl = profileAsync.asData?.value.avatarUrl ?? match.avatarUrl;
    final name = profileAsync.asData?.value.displayName.isNotEmpty == true
        ? profileAsync.asData!.value.displayName
        : match.displayName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
              child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    t.tasteTwinMatchSummary(
                      match.similarityPercent,
                      match.overlapCount,
                    ),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.tasteTwinSignalHint,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  if (match.reviewSimilarity != null ||
                      match.signalSimilarity != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _debugSimilarityText(context, match),
                      style: const TextStyle(color: AppColors.slate, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _openRecommendations(context, match),
              child: Text(t.tasteTwinViewSuggestions),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchSkeleton extends StatelessWidget {
  const _MatchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
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
                  Container(height: 10, width: 160, color: AppColors.card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(height: 10, width: width, color: AppColors.card),
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

void _openRecommendations(BuildContext context, TasteMatch match) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecommendationSheet(match: match),
  );
}

class _RecommendationSheet extends ConsumerStatefulWidget {
  const _RecommendationSheet({required this.match});
  final TasteMatch match;

  @override
  ConsumerState<_RecommendationSheet> createState() =>
      _RecommendationSheetState();
}

class _RecommendationSheetState extends ConsumerState<_RecommendationSheet> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final match = widget.match;
    final async = ref.watch(tasteRecommendationsProvider(match.userId));
    final user = ref.watch(userProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.tasteTwinRecommendationsTitle(match.displayName),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    if (user == null) {
                      context.go('/login?redirect=/taste-twin');
                      return;
                    }
                    final next = !_isFollowing;
                    setState(() => _isFollowing = next);
                    try {
                      await ref
                          .read(followControllerProvider.notifier)
                          .toggle(match.userId);
                    } catch (e) {
                      if (!context.mounted) return;
                      setState(() => _isFollowing = !next);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppErrorMapper.message(e))),
                      );
                    }
                  },
                  child: Text(
                    _isFollowing
                        ? t.favoritesFollowingAction
                        : t.tasteTwinFollowGourmet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppErrorMapper.message(e),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(
                          tasteRecommendationsProvider(match.userId).notifier,
                        )
                        .refresh(force: true),
                    child: Text(t.retry),
                  ),
                ],
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    t.tasteTwinNoSuggestionsYet,
                    style: const TextStyle(color: AppColors.muted),
                  );
                }
                return Column(
                  children: [
                    _OverlapSection(otherUserId: match.userId),
                    const SizedBox(height: 12),
                    _DivergenceSection(otherUserId: match.userId),
                    const SizedBox(height: 12),
                    for (final rec in items) ...[
                      _RecommendationCard(rec: rec),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec});
  final TasteRecommendation rec;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rec.businessName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              _locText(context, rec.district, rec.city),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _matchRatingText(context, rec),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              rec.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => context.go('/b/${rec.businessId}'),
                child: Text(AppLocalizations.of(context).go),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _locText(BuildContext context, String district, String city) {
  final d = district.trim();
  final c = city.trim();
  if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d • $c';
}

class _OverlapSection extends ConsumerWidget {
  const _OverlapSection({required this.otherUserId});
  final String otherUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final reviewAsync = ref.watch(tasteOverlapProvider(otherUserId));
    final signalAsync = ref.watch(tasteSignalOverlapProvider(otherUserId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.tasteTwinWhyMatchedTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(t.tasteTwinReviewOverlapTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        reviewAsync.when(
          loading: () => const _ReasonSkeleton(),
          error: (e, _) => _ReasonError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref
                .read(tasteOverlapProvider(otherUserId).notifier)
                .refresh(force: true),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                t.tasteTwinNoSampleYet,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final ex in items) ...[
                  _ReasonRow(
                    businessId: ex.businessId,
                    businessName: ex.businessName,
                    myRating: ex.myRating,
                    otherRating: ex.otherRating,
                    myReviewCreatedAt: ex.myReviewCreatedAt,
                    onTap: ex.businessId.isEmpty
                        ? null
                        : () => context.go('/b/${ex.businessId}'),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          t.tasteTwinMenuSignalOverlapTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          t.tasteTwinMenuSignalOverlapHint,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        signalAsync.when(
          loading: () => const _ReasonSkeleton(),
          error: (e, _) => _ReasonError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref
                .read(tasteSignalOverlapProvider(otherUserId).notifier)
                .refresh(force: true),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                t.tasteTwinNoSampleYet,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final ex in items) ...[
                  _SignalReasonRow(
                    businessId: ex.businessId,
                    businessName: ex.businessName,
                    mySignal: ex.mySignal,
                    otherSignal: ex.otherSignal,
                    onTap: ex.businessId.isEmpty
                        ? null
                        : () => context.go('/b/${ex.businessId}'),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DivergenceSection extends ConsumerWidget {
  const _DivergenceSection({required this.otherUserId});
  final String otherUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(tasteDivergenceProvider(otherUserId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.tasteTwinDivergenceTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        async.when(
          loading: () => const _ReasonSkeleton(),
          error: (e, _) => _ReasonError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref
                .read(tasteDivergenceProvider(otherUserId).notifier)
                .refresh(force: true),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                t.tasteTwinNoSampleYet,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final ex in items) ...[
                  _ReasonRow(
                    businessId: ex.businessId,
                    businessName: ex.businessName,
                    myRating: ex.myRating,
                    otherRating: ex.otherRating,
                    myReviewCreatedAt: null,
                    onTap: ex.businessId.isEmpty
                        ? null
                        : () => context.go('/b/${ex.businessId}'),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.businessId,
    required this.businessName,
    required this.myRating,
    required this.otherRating,
    required this.myReviewCreatedAt,
    this.onTap,
  });

  final String businessId;
  final String businessName;
  final int myRating;
  final int otherRating;
  final DateTime? myReviewCreatedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(
              businessName,
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            t.tasteTwinRatingComparison(myRating, otherRating),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          if (myReviewCreatedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              t.tasteTwinYouAt(_relativeShort(context, myReviewCreatedAt!)),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignalReasonRow extends StatelessWidget {
  const _SignalReasonRow({
    required this.businessId,
    required this.businessName,
    required this.mySignal,
    required this.otherSignal,
    this.onTap,
  });

  final String businessId;
  final String businessName;
  final int mySignal;
  final int otherSignal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Text(
              businessName,
              style: const TextStyle(fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppLocalizations.of(context).tasteTwinSignalComparison(
              mySignal,
              otherSignal,
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReasonError extends StatelessWidget {
  const _ReasonError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.danger)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).retry),
        ),
      ],
    );
  }
}

class _ReasonSkeleton extends StatelessWidget {
  const _ReasonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonLine(width: 200),
        SizedBox(height: 6),
        _SkeletonLine(width: 180),
        SizedBox(height: 6),
        _SkeletonLine(width: 160),
      ],
    );
  }
}

String _matchRatingText(BuildContext context, TasteRecommendation rec) {
  final t = AppLocalizations.of(context);
  final base = t.tasteTwinMatchRated(rec.rating);
  final at = rec.matchReviewCreatedAt;
  if (at == null) return base;
  return t.tasteTwinRatedAt(_relativeLong(context, at), base);
}

String _debugSimilarityText(BuildContext context, TasteMatch match) {
  final t = AppLocalizations.of(context);
  final review = match.reviewSimilarity;
  final signal = match.signalSimilarity;
  final reviewPct = review == null ? null : (review * 100).round().clamp(0, 100);
  final signalPct = signal == null ? null : (signal * 100).round().clamp(0, 100);
  if (reviewPct != null && signalPct != null) {
    return t.tasteTwinDebugReviewAndSignal(reviewPct, signalPct);
  }
  if (reviewPct != null) return t.tasteTwinDebugReviewOnly(reviewPct);
  if (signalPct != null) return t.tasteTwinDebugSignalOnly(signalPct);
  return '';
}

String _relativeShort(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inDays < 1) return t.tasteTwinTodayLower;
  if (diff.inDays == 1) return t.tasteTwinYesterdayLower;
  if (diff.inDays < 30) return t.smartFeedDaysAgo(diff.inDays);
  final months = (diff.inDays / 30).floor();
  return t.suspendedMealsMonthsAgo(months);
}

String _relativeLong(BuildContext context, DateTime time) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time);
  if (diff.inDays < 1) return t.today;
  if (diff.inDays == 1) return t.yesterday;
  return t.smartFeedDaysAgo(diff.inDays);
}

