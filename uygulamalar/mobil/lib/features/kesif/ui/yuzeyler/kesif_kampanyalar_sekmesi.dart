part of '../kesif_sayfasi.dart';

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final campaignParams = ref.watch(
      discoverySearchProvider.select(
        (s) => (
          lat: s.userLat,
          lng: s.userLng,
          radiusKm: s.radiusKm,
          city: s.city,
          district: s.district,
        ),
      ),
    );
    final campaignsAsync = ref.watch(
      nearbyCampaignsProvider((
        lat: campaignParams.lat,
        lng: campaignParams.lng,
        radiusKm: campaignParams.radiusKm,
        city: campaignParams.city,
        district: campaignParams.district,
        limit: 24,
      )),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          nearbyCampaignsProvider((
            lat: campaignParams.lat,
            lng: campaignParams.lng,
            radiusKm: campaignParams.radiusKm,
            city: campaignParams.city,
            district: campaignParams.district,
            limit: 24,
          )),
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            sliver: SliverList.list(
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: AppColors.textStrong,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.nearbyCampaignsAndAnnouncements,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                campaignsAsync.when(
                  loading: () => const _DiscoverySkeleton(),
                  error: (e, _) => AppCard(
                    child: Text(
                      AppErrorMapper.message(e),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.campaign_outlined,
                        title: t.noNearbyCampaign,
                        description: t.noActiveAnnouncementInArea,
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items) ...[
                          _CampaignCard(item: item),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({required this.item});

  final NearbyCampaign item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final subtitleParts = <String>[
      if ((item.district ?? '').trim().isNotEmpty) item.district!.trim(),
      if ((item.city ?? '').trim().isNotEmpty) item.city!.trim(),
      if (item.distanceKm != null) '${item.distanceKm!.toStringAsFixed(1)} km',
      '${t.remainingLabel}: ${_campaignTimeLeft(context, item.expiresAt)}',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BusinessTile(
            name: item.businessName,
            category: t.campaign,
            subtitle: subtitleParts.join('  '),
            badgeText: t.active,
            onTap: () {
              unawaited(
                _logDiscoveryClick(
                  ref.read(analyticsRepositoryProvider),
                  businessId: item.businessId,
                  source: 'campaign',
                ),
              );
              context.go('/isletme/${item.businessId}');
            },
            trailingAction: const Icon(Icons.chevron_right),
          ),
          if ((item.caption ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.caption!.trim(),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}


