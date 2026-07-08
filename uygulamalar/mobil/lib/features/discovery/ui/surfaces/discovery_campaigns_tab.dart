part of '../discovery_page.dart';

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
    final params = (
      lat: campaignParams.lat,
      lng: campaignParams.lng,
      radiusKm: campaignParams.radiusKm,
      city: campaignParams.city,
      district: campaignParams.district,
      limit: 24,
    );
    final campaignsAsync = ref.watch(nearbyCampaignsProvider(params));
    final filter = ref.watch(campaignsFilterProvider);
    final query = ref.watch(campaignsSearchQueryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(nearbyCampaignsProvider(params));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            sliver: SliverList.list(
              children: [
                const _CampaignsHeaderRow(),
                const SizedBox(height: 12),
                const _CampaignsSearchField(),
                const SizedBox(height: 12),
                const _CampaignFilterChips(),
                const SizedBox(height: 16),
                campaignsAsync.when(
                  loading: () => const _DiscoverySkeleton(),
                  error: (e, _) => AppCard(
                    child: Text(
                      AppErrorMapper.message(e),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  data: (items) {
                    final filtered = applyCampaignFilter(items, filter)
                        .where((c) => _campaignMatchesQuery(c, query))
                        .toList();
                    if (filtered.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.campaign_outlined,
                        title: t.noNearbyCampaign,
                        description: t.noActiveAnnouncementInArea,
                      );
                    }

                    NearbyCampaign? hero;
                    for (final c in filtered) {
                      if (c.isFeatured) {
                        hero = c;
                        break;
                      }
                    }
                    final rest = hero == null
                        ? filtered
                        : filtered
                              .where((c) => c.storyId != hero!.storyId)
                              .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hero != null) ...[
                          SizedBox(
                            height: 200,
                            child: _CampaignHeroCard(item: hero),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (rest.isNotEmpty) ...[
                          Text(
                            t.campaignsNearbyHeader,
                            style: context.sectionTitleStyle,
                          ),
                          const SizedBox(height: 12),
                          for (final item in rest) ...[
                            _CampaignCard(item: item, params: params),
                            const SizedBox(height: 10),
                          ],
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

bool _campaignMatchesQuery(NearbyCampaign item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return item.businessName.toLowerCase().contains(q) ||
      (item.caption ?? '').toLowerCase().contains(q);
}

class _CampaignsHeaderRow extends StatelessWidget {
  const _CampaignsHeaderRow();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.campaignsGreeting,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                t.tabCampaigns,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const NotificationsBell(),
      ],
    );
  }
}

class _CampaignsSearchField extends ConsumerStatefulWidget {
  const _CampaignsSearchField();

  @override
  ConsumerState<_CampaignsSearchField> createState() =>
      _CampaignsSearchFieldState();
}

class _CampaignsSearchFieldState extends ConsumerState<_CampaignsSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(campaignsSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      onChanged: (value) =>
          ref.read(campaignsSearchQueryProvider.notifier).setQuery(value),
      decoration: InputDecoration(
        hintText: t.campaignsSearchPlaceholder,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _CampaignFilterChips extends ConsumerWidget {
  const _CampaignFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final selected = ref.watch(campaignsFilterProvider);
    final entries = <(CampaignFilter, String)>[
      (CampaignFilter.all, t.campaignFilterAll),
      (CampaignFilter.soon, t.campaignFilterSoon),
      (CampaignFilter.today, t.campaignFilterToday),
      (CampaignFilter.food, t.campaignFilterFood),
      (CampaignFilter.dessert, t.campaignFilterDessert),
      (CampaignFilter.discount20, t.campaignFilterDiscount20),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries) ...[
            CategoryChip(
              label: entry.$2,
              selected: selected == entry.$1,
              onTap: () => ref
                  .read(campaignsFilterProvider.notifier)
                  .setFilter(entry.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CampaignHeroCard extends StatelessWidget {
  const _CampaignHeroCard({required this.item});

  final NearbyCampaign item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(tokens.radius20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/b/${item.businessId}'),
        child: Stack(
          children: [
            if (item.mediaThumbUrl != null)
              Positioned.fill(
                child: AppNetworkImage(
                  url: item.mediaThumbUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.campaignsFeaturedBadge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      if (item.discountPercent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          t.campaignDiscountLabel(item.discountPercent!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${t.remainingLabel}: ${_campaignTimeLeft(context, item.expiresAt)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: tokens.space16,
              right: tokens.space16,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({required this.item, required this.params});

  final NearbyCampaign item;
  final NearbyCampaignsParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final remaining = _campaignTimeLeft(context, item.expiresAt);
    final urgent = item.expiresAt.difference(DateTime.now()).inHours < 2;

    return AppCard(
      onTap: () {
        unawaited(
          _logDiscoveryClick(
            ref.read(analyticsRepositoryProvider),
            businessId: item.businessId,
            source: 'campaign',
          ),
        );
        context.go('/b/${item.businessId}');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.mediaThumbUrl != null
                    ? AppNetworkImage(
                        url: item.mediaThumbUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.primarySoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              if (item.discountPercent != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%${item.discountPercent}',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.caption ?? '').trim().isEmpty
                      ? item.businessName
                      : item.caption!.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.businessName,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.distanceKm != null) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: urgent ? AppColors.danger : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      remaining,
                      style: TextStyle(
                        color: urgent ? AppColors.danger : AppColors.muted,
                        fontSize: 12,
                        fontWeight: urgent ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (user != null)
                IconButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(nearbyCampaignsProvider(params).notifier)
                          .toggleSaved(item.storyId);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppErrorMapper.message(e))),
                      );
                    }
                  },
                  icon: Icon(
                    item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: item.isSaved ? AppColors.primary : AppColors.muted,
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}
