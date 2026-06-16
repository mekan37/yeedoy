import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../core/media/app_network_image.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/smart_reco_models.dart';
import '../domain/smart_reco_provider.dart';

enum _PriceRange {
  under200,
  r200_400,
  r400_600,
  r600_1000,
  over1000;

  int get maxCents => switch (this) {
        _PriceRange.under200 => 20000,
        _PriceRange.r200_400 => 40000,
        _PriceRange.r400_600 => 60000,
        _PriceRange.r600_1000 => 100000,
        _PriceRange.over1000 => 200000,
      };

  String get label => switch (this) {
        _PriceRange.under200 => '₺200 altı',
        _PriceRange.r200_400 => '₺200–400',
        _PriceRange.r400_600 => '₺400–600',
        _PriceRange.r600_1000 => '₺600–1.000',
        _PriceRange.over1000 => '₺1.000 üzeri',
      };
}

class SmartRecommendationPage extends ConsumerStatefulWidget {
  const SmartRecommendationPage({super.key});

  @override
  ConsumerState<SmartRecommendationPage> createState() =>
      _SmartRecommendationPageState();
}

class _SmartRecommendationPageState
    extends ConsumerState<SmartRecommendationPage> {
  int _partySize = 2;
  _PriceRange _selectedRange = _PriceRange.r400_600;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loc = ref.watch(userLocationProvider);
    final query = SmartRecoQuery(
      city: loc.city ?? '',
      district: loc.district ?? '',
      partySize: _partySize,
      budgetMaxCents: _selectedRange.maxCents,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SafeArea(bottom: false, child: AppTopBar()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.smartRecoTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.smartRecoSubtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InputCard(
            partySize: _partySize,
            selectedRange: _selectedRange,
            onPartySizeChanged: (v) => setState(() => _partySize = v),
            onRangeChanged: (v) => setState(() => _selectedRange = v),
          ),
        ),
        const SizedBox(height: 16),
        _ResultsSection(query: query),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.partySize,
    required this.selectedRange,
    required this.onPartySizeChanged,
    required this.onRangeChanged,
  });

  final int partySize;
  final _PriceRange selectedRange;
  final ValueChanged<int> onPartySizeChanged;
  final ValueChanged<_PriceRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Kişi sayısı',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: partySize > 1
                    ? () => onPartySizeChanged(partySize - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                iconSize: 28,
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$partySize',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              IconButton(
                onPressed: partySize < 8
                    ? () => onPartySizeChanged(partySize + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                iconSize: 28,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Bütçe aralığı',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              DropdownButton<_PriceRange>(
                value: selectedRange,
                underline: const SizedBox.shrink(),
                items: _PriceRange.values
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRangeChanged(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({required this.query});

  final SmartRecoQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final async = ref.watch(smartRecoProvider(query));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: async.when(
        loading: () => Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: AppSkeletonCard(),
            ),
          ),
        ),
        error: (e, _) => Text(
          AppErrorMapper.message(e),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (items) {
          if (items.isNotEmpty) {
            ref.read(analyticsRepositoryProvider).logEvent(
              eventName: AppEvents.smartRecoSearch,
              source: 'smart_reco',
              meta: {'count': items.length},
            );
          }
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off_outlined,
              title: t.smartRecoEmptyTitle,
              description: t.smartRecoEmptyDesc,
            );
          }
          return Column(
            children: [
              for (final item in items) ...[
                RepaintBoundary(
                  child: _SmartBusinessCard(item: item),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              _ShuffleTile(query: query),
            ],
          );
        },
      ),
    );
  }
}

class _SmartBusinessCard extends ConsumerWidget {
  const _SmartBusinessCard({required this.item});

  final SmartRecommendation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          ref.read(analyticsRepositoryProvider).logEvent(
            eventName: AppEvents.smartRecoBusinessOpen,
            businessId: item.businessId,
            source: 'smart_reco',
          );
          context.go('/b/${item.businessId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 80,
                      child: item.imageUrl != null
                          ? AppNetworkImage(
                              url: item.imageUrl!,
                              variant: AppImageVariant.thumb,
                              width: 100,
                              height: 80,
                            )
                          : Container(color: AppColors.cardAlt),
                    ),
                    if (item.discountPct != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '%${item.discountPct} indirim',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textStrong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.cuisine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.cuisine!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.distanceKm != null) ...[
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.originalTotalCents != null) ...[
                          Text(
                            _formatCents(item.originalTotalCents!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatCents(item.totalCents),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleTile extends ConsumerWidget {
  const _ShuffleTile({required this.query});

  final SmartRecoQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          ref.read(analyticsRepositoryProvider).logEvent(
            eventName: AppEvents.smartRecoShuffle,
            source: 'smart_reco',
          );
          ref.read(smartRecoRepositoryProvider).clearReadCache();
          ref.refresh(smartRecoProvider(query));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(
                Icons.shuffle_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                t.smartRecoShuffleLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.smartRecoShuffleDesc,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCents(int cents) {
  final tl = cents ~/ 100;
  final kr = cents % 100;
  if (kr == 0) return '₺$tl';
  return '₺$tl,${kr.toString().padLeft(2, '0')}';
}
