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
    final heroesAsync = ref.watch(heroesProvider);
    final weeklyAsync = ref.watch(weeklyLeaderboardProvider);
    final isTr = t.localeName.startsWith('tr');

    Future<void> onRefresh() async {
      await Future.wait([
        ref.read(heroesProvider.notifier).refresh(force: true),
        ref.read(weeklyLeaderboardProvider.notifier).refresh(),
      ]);
    }

    return AppScaffold(
      appBar: AppBar(title: Text(t.heroesPageTitle)),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            // ── Weekly Leaderboard ───────────────────────────────────────
            Text(
              isTr ? 'Haftalık En İyi Katkıcılar' : 'Weekly Top Contributors',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTr
                  ? 'Son 7 günde en çok fiyat doğrulayan, yorum yazan ve fotoğraf ekleyenler'
                  : 'Most price verifications, reviews, and photos in the past 7 days',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            weeklyAsync.when(
              loading: () => const _HeroesSkeleton(),
              error: (e, _) => _HeroesError(
                message: AppErrorMapper.message(e),
                onRetry: () =>
                    ref.read(weeklyLeaderboardProvider.notifier).refresh(),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      isTr
                          ? 'Bu hafta henüz katkı yok.'
                          : 'No contributions this week yet.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      _WeeklyLeaderboardTile(
                        entry: entries[i],
                        rank: i + 1,
                        isTr: isTr,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // ── All-time Heroes ──────────────────────────────────────────
            Text(
              isTr ? 'Tüm Zamanlar Kahramanları' : 'All-Time Heroes',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.heroesPageSubtitle,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            heroesAsync.when(
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

class _WeeklyLeaderboardTile extends ConsumerWidget {
  const _WeeklyLeaderboardTile({
    required this.entry,
    required this.rank,
    required this.isTr,
  });

  final WeeklyLeaderboardEntry entry;
  final int rank;
  final bool isTr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(entry.userId));
    final profile =
        profileAsync.asData?.value ??
        PublicProfile(displayName: '', avatarUrl: '');
    final name = profile.displayName.isNotEmpty
        ? profile.displayName
        : (isTr ? 'Kullanıcı' : 'User');

    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                medal,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundImage: profile.avatarUrl.isEmpty
                  ? null
                  : NetworkImage(profile.avatarUrl),
              child:
                  profile.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isTr
                        ? '${entry.verifyCount} doğrulama · ${entry.reviewCount} yorum · ${entry.photoCount} fotoğraf'
                        : '${entry.verifyCount} verif · ${entry.reviewCount} reviews · ${entry.photoCount} photos',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.cardAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${entry.weeklyScore} puan',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: rank <= 3 ? AppColors.primary : AppColors.textStrong,
                ),
              ),
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


