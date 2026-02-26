import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../taste_twin/domain/taste_twin_controllers.dart';
import '../../taste_twin/domain/taste_twin_models.dart';
import '../domain/hero_controllers.dart';
import '../domain/hero_models.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';

class HeroesPage extends ConsumerWidget {
  const HeroesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final async = ref.watch(heroesProvider);

    return AppScaffold(
      appBar: AppBar(title: Text(t.heroesPageTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(heroesProvider.notifier).refresh(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              t.heroesPageSubtitle,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            async.when(
              loading: () => const _HeroesSkeleton(),
              error: (e, _) => _HeroesError(
                message: AppErrorMapper.message(e),
                onRetry: () =>
                    ref.read(heroesProvider.notifier).refresh(force: true),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    t.heroesPageEmpty,
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                return Column(
                  children: [
                    for (final hero in items) ...[
                      _HeroTile(hero: hero),
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

class _HeroTile extends ConsumerWidget {
  const _HeroTile({required this.hero});
  final HeroEntry hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final profileAsync = ref.watch(publicProfileProvider(hero.userId));
    final profile =
        profileAsync.asData?.value ??
        PublicProfile(displayName: '', avatarUrl: '');
    final name = profile.displayName.isNotEmpty
        ? profile.displayName
        : t.heroesPageUserFallback;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: profile.avatarUrl.isEmpty
                  ? null
                  : NetworkImage(profile.avatarUrl),
              child: profile.avatarUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.heroesPageDonatedMealCount(hero.donatedCount),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatPrice(
                context,
                hero.totalCents,
                currencyCode: hero.currency,
              ),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroesSkeleton extends StatelessWidget {
  const _HeroesSkeleton();

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
              width: 44,
              height: 44,
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
                  Container(height: 10, width: 140, color: AppColors.card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroesError extends StatelessWidget {
  const _HeroesError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.danger)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onRetry, child: Text(t.retry)),
      ],
    );
  }
}

String _formatPrice(
  BuildContext context,
  int? cents, {
  String currencyCode = 'TRY',
}) {
  if (cents == null) return context.l10n.unknown;
  return formatCurrency(
    context,
    cents / 100.0,
    currencyCode: currencyCode,
  );
}


