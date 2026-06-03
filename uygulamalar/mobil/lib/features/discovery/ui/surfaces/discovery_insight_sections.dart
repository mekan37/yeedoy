part of '../discovery_page.dart';

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
                      onTap: () => context.go('/b/${item.businessId}'),
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
                      mealCardProviders: entry.value.business.mealCardProviders,
                      isOpenNow: entry.value.business.isOpenNow,
                      medianPriceCents: entry.value.business.medianPriceCents,
                      priceLevel: entry.value.business.priceLevel,
                      socialProof: [
                        AppLocalizations.of(context).rankedAt(entry.key + 1),
                        metricLabel(entry.value),
                      ],
                      onTap: () => context.go('/b/${entry.value.business.id}'),
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
