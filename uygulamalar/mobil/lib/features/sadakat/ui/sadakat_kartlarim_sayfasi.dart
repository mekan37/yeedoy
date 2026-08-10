import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/colors.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/sadakat_saglayicisi.dart';

class SadakatKartlarimSayfasi extends ConsumerWidget {
  const SadakatKartlarimSayfasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(myLoyaltyCardsProvider);
    final qrData = ref.watch(myLoyaltyQrDataProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: Text('Sadakat Kartlarım')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myLoyaltyCardsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _QrKartim(qrData: qrData),
            const SizedBox(height: 20),
            cardsAsync.when(
              loading: () => const _LoyaltyCardsSkeleton(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
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
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.loyalty_rounded,
                    title: 'Henüz sadakat kartın yok',
                    description:
                        'Katıldığın işletmelerin sadakat programları burada görünecek.',
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      RepaintBoundary(child: _LoyaltyCardItem(card: card)),
                      const SizedBox(height: 12),
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

class _QrKartim extends StatelessWidget {
  const _QrKartim({required this.qrData});

  final String? qrData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            'Damga/puan kazanmak için işletmede bu kodu gösterin.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (qrData != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: qrData!,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textStrong,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textStrong,
                ),
              ),
            )
          else
            const Text(
              'Kodunuzu görmek için giriş yapın.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          const SizedBox(height: 10),
          const Text(
            'Bu kod size özeldir, paylaşmayın.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LoyaltyCardItem extends StatelessWidget {
  const _LoyaltyCardItem({required this.card});

  final LoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BusinessAvatar(logoUrl: card.logoUrl, businessName: card.businessName),
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
                    Text(
                      card.rewardDesc,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${card.progress} / ${card.rewardThreshold}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: card.progressRatio,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
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
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
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
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          const AppSkeletonCard(lines: 3),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
