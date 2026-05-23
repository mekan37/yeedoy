import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/marka/marka_bilesenleri.dart';
import '../../../uygulama/tema/renkler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../domain/benim_onerilerim_kontrolcusu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../domain/oneri.dart';

class MySuggestionsPage extends ConsumerStatefulWidget {
  const MySuggestionsPage({super.key});

  @override
  ConsumerState<MySuggestionsPage> createState() => _MySuggestionsPageState();
}

class _MySuggestionsPageState extends ConsumerState<MySuggestionsPage> {
  final scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
          scrollCtrl.position.maxScrollExtent - 300) {
        ref.read(mySuggestionsControllerProvider.notifier).loadMore();
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
    final st = ref.watch(mySuggestionsControllerProvider);

    return AppScaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: BrandWordmark(height: 26),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(mySuggestionsControllerProvider.notifier).refresh(),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              t.mySuggestionsTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              t.mySuggestionsSubtitle,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),

            if (st.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ErrorState(
                  message: AppErrorMapper.message(st.error),
                  onRetry: () => ref
                      .read(mySuggestionsControllerProvider.notifier)
                      .refresh(),
                ),
              ),

            if (st.isLoading && st.items.isEmpty) ...[
              const _SuggestionsSkeleton(),
            ] else if (st.items.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: _EmptyState(),
              ),
            ] else ...[
              for (final s in st.items) ...[
                RepaintBoundary(child: _SuggestionCard(suggestion: s)),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final BusinessSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final approvedId = (suggestion.approvedBusinessId ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(status: suggestion.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _locText(context, suggestion.district, suggestion.city),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  _fmtDate(suggestion.createdAt),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            if ((suggestion.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                suggestion.adminNote!.trim(),
                style: const TextStyle(color: AppColors.slate),
              ),
            ],
            if (suggestion.status == 'approved' && approvedId.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/isletme/$approvedId'),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(t.viewBusiness),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    String text;
    AppBadgeTone tone;

    switch (status) {
      case 'approved':
        tone = AppBadgeTone.success;
        text = t.statusApproved;
        break;
      case 'rejected':
        tone = AppBadgeTone.danger;
        text = t.statusRejected;
        break;
      default:
        tone = AppBadgeTone.warning;
        text = t.statusPending;
    }

    return AppBadge(label: text, tone: tone);
  }
}

class _SuggestionsSkeleton extends StatelessWidget {
  const _SuggestionsSkeleton();

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 10, color: AppColors.card),
            const SizedBox(height: 8),
            Container(height: 10, width: 140, color: AppColors.card),
            const SizedBox(height: 10),
            Container(height: 10, width: 110, color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.lightbulb_outline,
      title: t.emptyTitle,
      description: t.emptyRegionDescription,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.error_outline,
      title: t.errorOccurred,
      description: message,
      ctaLabel: t.retry,
      onCta: onRetry,
    );
  }
}

String _locText(BuildContext context, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d • $c';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}




