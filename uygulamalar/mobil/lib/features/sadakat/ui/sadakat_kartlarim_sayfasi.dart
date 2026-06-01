import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/sadakat_saglayicisi.dart';

// Tier renkleri
Color _tierColor(LoyaltyTier tier) => switch (tier) {
  LoyaltyTier.bronz  => const Color(0xFFCD7F32),
  LoyaltyTier.gumus  => const Color(0xFF9E9E9E),
  LoyaltyTier.altin  => const Color(0xFFFFC107),
  LoyaltyTier.platin => const Color(0xFF6C63FF),
};

class SadakatKartlarimSayfasi extends ConsumerWidget {
  const SadakatKartlarimSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(myLoyaltyCardsProvider);
    return AppScaffold(
      appBar: const AppAppBar(title: Text('Sadakat Kartlarım')),
      body: cardsAsync.when(
        loading: () => const _LoyaltyCardsSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppErrorMapper.message(e),
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(myLoyaltyCardsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return const AppEmptyState(
              icon: Icons.loyalty_rounded,
              title: 'Henüz sadakat kartın yok',
              description:
                  'Henüz sadakat programı puanın yok. Favori işletmelerin check-in yaparak başla!',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myLoyaltyCardsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: cards.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) => RepaintBoundary(
                child: _LoyaltyCardItem(
                  card: cards[index],
                  onTap: () =>
                      context.push('/isletme/${cards[index].businessId}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoyaltyCardItem extends StatelessWidget {
  const _LoyaltyCardItem({required this.card, required this.onTap});

  final LoyaltyCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = card.rewardThresholdPts - card.points;
    final rewardLabel = _rewardLabel(card);
    final progress = (card.progressPct / 100.0).clamp(0.0, 1.0);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BusinessAvatar(
                logoUrl: card.logoUrl,
                businessName: card.businessName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _TierBadge(tier: card.tier),
                        const SizedBox(width: 6),
                        Text(
                          '${card.lifetimePoints} toplam puan',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${card.points} / ${card.rewardThresholdPts} puan',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%${card.progressPct}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? '$remaining puana ulaşınca $rewardLabel'
                : 'Ödüle ulaştınız! $rewardLabel',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          // Next tier progress
          if (card.tier != LoyaltyTier.platin) ...[
            const SizedBox(height: 10),
            _NextTierRow(card: card),
          ],
        ],
      ),
    );
  }

  String _rewardLabel(LoyaltyCard card) {
    if (card.rewardType == 'discount_pct') {
      return '%${card.rewardValue} indirim';
    }
    if (card.rewardType == 'free_item') {
      return 'Ücretsiz ürün';
    }
    return '${card.rewardValue} indirim';
  }
}

class _TierBadge extends StatelessWidget {
  final LoyaltyTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NextTierRow extends StatelessWidget {
  final LoyaltyCard card;
  const _NextTierRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final tiers = LoyaltyTier.values;
    final currentIdx = tiers.indexOf(card.tier);
    if (currentIdx >= tiers.length - 1) return const SizedBox.shrink();

    final nextTier = tiers[currentIdx + 1];
    final nextThreshold = nextTier.thresholdPts;
    final ptsToNext = nextThreshold - card.lifetimePoints;
    final progress = (card.lifetimePoints / nextThreshold).clamp(0.0, 1.0);
    final nextColor = _tierColor(nextTier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${nextTier.label} için $ptsToNext puan kaldı',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const Spacer(),
            _TierBadge(tier: nextTier),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: nextColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(nextColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({required this.logoUrl, required this.businessName});

  final String? logoUrl;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          memCacheWidth: 80,
          memCacheHeight: 80,
          placeholder: (ctx, url) => const SizedBox(width: 40, height: 40),
          errorWidget: (ctx, url, err) => _Initials(name: businessName),
        ),
      );
    }
    return _Initials(name: businessName);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _LoyaltyCardsSkeleton extends StatelessWidget {
  const _LoyaltyCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => const AppSkeletonCard(lines: 3),
    );
  }
}
