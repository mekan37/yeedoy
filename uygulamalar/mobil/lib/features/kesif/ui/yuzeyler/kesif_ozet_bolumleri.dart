part of '../kesif_sayfasi.dart';

class _DiscoverySkeleton extends StatelessWidget {
  const _DiscoverySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (i) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AppSkeletonCard(),
        );
      }),
    );
  }
}

class _DiscoveryMapSkeleton extends StatelessWidget {
  const _DiscoveryMapSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonLine(width: 120, height: 14),
        const SizedBox(height: 10),
        const AppSkeletonBox(height: 220),
        const SizedBox(height: 8),
        const AppSkeletonLine(width: 200, height: 10),
      ],
    );
  }
}

// ─── Bugünün Spesiyalleri ──────────────────────────────────────────────────────
class BugunSpesiyalBolumu extends ConsumerWidget {
  const BugunSpesiyalBolumu({super.key, this.city, this.lat, this.lng});

  final String? city;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (city: city, lat: lat, lng: lng);
    final async = ref.watch(todaySpecialsProvider(args));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Bugünün Spesiyalleri',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${items.length} işletme',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final item in items) ...[
              _SpesiyelKarti(item: item),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _SpesiyelKarti extends StatelessWidget {
  const _SpesiyelKarti({required this.item});
  final TodaySpecialItem item;

  @override
  Widget build(BuildContext context) {
    final price = item.priceValue;
    final distText = item.distanceKm != null
        ? (item.distanceKm! < 1
            ? '${(item.distanceKm! * 1000).round()} m'
            : '${item.distanceKm!.toStringAsFixed(1)} km')
        : null;

    return AppCard(
      onTap: () => context.go('/isletme/${item.businessId}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)} ₺',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.businessName,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (distText != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        distText,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if ((item.specialNote ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.specialNote!,
                    style: const TextStyle(
                      color: AppColors.primaryStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalPriceIndexSection extends StatelessWidget {
  const _RegionalPriceIndexSection({required this.title, required this.items});

  final String title;
  final AsyncValue<List<RegionalPriceIndexItem>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 8),
        items.when(
          loading: () => const AppSkeletonCard(),
          error: (_, _) => Text(
            AppLocalizations.of(context).priceIndexLoadFailed,
            style: const TextStyle(color: AppColors.muted),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                AppLocalizations.of(context).noPriceIndexDataInArea,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final item in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights_outlined,
                            color: AppColors.textStrong,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.category.isEmpty
                                  ? AppLocalizations.of(context).general
                                  : item.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).medianPriceLabel(
                              _formatPrice(context, item.medianPriceCents),
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PriceAnomalySection extends StatelessWidget {
  const _PriceAnomalySection({required this.title, required this.items});

  final String title;
  final AsyncValue<List<PriceAnomalyItem>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 8),
        items.when(
          loading: () => const AppSkeletonCard(),
          error: (_, _) => Text(
            AppLocalizations.of(context).anomalyListLoadFailed,
            style: const TextStyle(color: AppColors.muted),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                AppLocalizations.of(context).noPriceAnomalyLast30Days,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final item in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => context.go('/isletme/${item.businessId}'),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.menuItemName}  ${item.changePct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MicroTrendSection extends StatelessWidget {
  const _MicroTrendSection({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.metricLabel,
    required this.rankLabelPrefix,
  });

  final String title;
  final String emptyText;
  final AsyncValue<List<TrendBusiness>> items;
  final String Function(TrendBusiness item) metricLabel;
  final String rankLabelPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 8),
        items.when(
          loading: () => Column(
            children: const [
              AppSkeletonCard(),
              SizedBox(height: 10),
              AppSkeletonCard(),
            ],
          ),
          error: (err, _) => Text(
            AppLocalizations.of(context).sectionLoadFailed,
            style: const TextStyle(color: AppColors.muted),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                emptyText,
                style: const TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final entry in list.asMap().entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BusinessTile(
                      name: entry.value.business.name,
                      category: entry.value.business.category,
                      subtitle:
                          _shortLocation(
                            entry.value.business.district,
                            entry.value.business.city,
                          ) ??
                          (entry.value.business.city ?? ''),
                      distanceKm: entry.value.business.distanceKm,
                      qualityScore: entry.value.business.qualityScore,
                      isOpenNow: entry.value.business.isOpenNow,
                      mealCardProviders: entry.value.business.mealCardProviders,
                      socialProof: [
                        AppLocalizations.of(context).rankedAt(entry.key + 1),
                        metricLabel(entry.value),
                      ],
                      onTap: () => context.go('/isletme/${entry.value.business.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}


