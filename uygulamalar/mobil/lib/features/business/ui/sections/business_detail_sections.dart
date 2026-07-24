part of '../business_page.dart';

class BusinessReviewsSection extends ConsumerWidget {
  const BusinessReviewsSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final detailAsync = ref.watch(businessDetailProvider(businessId));
    return AppCard(
      child: detailAsync.when(
        loading: () => const AppSkeletonCard(),
        error: (error, _) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.reviewsLoadFailed,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessDetailProvider(businessId)),
        ),
        data: (detail) {
          if (detail.latestReviews.isEmpty) {
            return AppEmptyState(
              icon: Icons.reviews_outlined,
              title: t.noReviews,
              description: t.leaveFirstReviewHelp,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.recentReviews,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.latestReviews.length} ${t.reviewsCountSuffix}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final review in detail.latestReviews)
                ListTile(
                  key: ValueKey(review.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    review.title?.trim().isEmpty == false
                        ? review.title!
                        : t.reviewFallbackTitle,
                  ),
                  subtitle: Text(
                    review.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class BusinessMealCardsSection extends ConsumerWidget {
  const BusinessMealCardsSection({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(
      businessMealCardProvidersProvider(businessId),
    );
    return providersAsync.maybeWhen(
      data: (providers) {
        if (providers.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Geçerli Yemek Kartları',
                style: context.sectionTitleStyle,
              ),
              const SizedBox(height: 6),
              Text(
                'Bu işletmede kabul edilen kartlar aşağıda listelenir.',
                style: context.captionStyle,
              ),
              const SizedBox(height: 10),
              MealCardBadgeRow(providers: providers),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessPerksSection extends ConsumerWidget {
  const BusinessPerksSection({
    super.key,
    required this.businessId,
    required this.businessName,
  });
  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final perksAsync = ref.watch(businessPerksProvider(businessId));
    return perksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (perks) {
        if (perks.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.activeCampaigns,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      Uri(
                        path: '/perks/$businessId',
                        queryParameters: {'name': businessName},
                      ).toString(),
                    ),
                    child: const Text('Tümünü gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PerksSummaryLine(businessId: businessId),
              _AmenitiesSummaryLine(businessId: businessId),
              _CheckinsSummaryLine(businessId: businessId),
              _NewItemsSummaryLine(businessId: businessId),
            ],
          ),
        );
      },
    );
  }
}

class _PerksSummaryLine extends ConsumerWidget {
  const _PerksSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perksAsync = ref.watch(businessPerksProvider(businessId));
    return perksAsync.when(
      loading: () => const AppSkeletonLine(width: 160),
      error: (_, _) => const SizedBox.shrink(),
      data: (perks) => Text(
        perks.isEmpty
            ? AppLocalizations.of(context).noActiveCampaign
            : '${perks.length} ${AppLocalizations.of(context).activeCampaignCountLabel}',
        style: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _AmenitiesSummaryLine extends ConsumerWidget {
  const _AmenitiesSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenitiesAsync = ref.watch(businessAmenitiesProvider(businessId));
    return amenitiesAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noAmenityInfo
              : '${items.length} ${AppLocalizations.of(context).amenityCountLabel}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CheckinsSummaryLine extends ConsumerWidget {
  const _CheckinsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(businessRecentCheckinsProvider(businessId));
    return checkinsAsync.maybeWhen(
      data: (count) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          count <= 0
              ? AppLocalizations.of(context).noLocationVerificationData
              : '${AppLocalizations.of(context).lastLocationVerification}: $count',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _NewItemsSummaryLine extends ConsumerWidget {
  const _NewItemsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newItemsAsync = ref.watch(businessNewItemsProvider(businessId));
    return newItemsAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noNewProductRecord
              : '${AppLocalizations.of(context).newProduct}: ${items.length}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessReviewPhotosSection extends ConsumerWidget {
  const BusinessReviewPhotosSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessReviewPhotosProvider(businessId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (urls) {
        if (urls.isEmpty) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        final isLocTr = t.localeName.startsWith('tr');
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isLocTr ? 'Topluluk Fotoğrafları' : 'Community Photos',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (urls.length >= 6)
                    TextButton(
                      onPressed: () => _openAllPhotos(context, urls),
                      child: Text(
                        isLocTr ? 'Tümünü gör' : 'See all',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _openAllPhotos(context, urls, initial: i),
                    child: AppNetworkImage(
                      url: urls[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      variant: AppImageVariant.thumb,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAllPhotos(
    BuildContext context,
    List<String> urls, {
    int initial = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            _BusinessPhotosViewer(urls: urls, initialIndex: initial),
      ),
    );
  }
}

class _BusinessPhotosViewer extends StatefulWidget {
  const _BusinessPhotosViewer({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_BusinessPhotosViewer> createState() => _BusinessPhotosViewerState();
}

class _BusinessPhotosViewerState extends State<_BusinessPhotosViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocTr = AppLocalizations.of(context).localeName.startsWith('tr');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          isLocTr
              ? 'Fotoğraf ${_current + 1} / ${widget.urls.length}'
              : 'Photo ${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: AppNetworkImage(
              url: widget.urls[i],
              variant: AppImageVariant.original,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class BusinessFrequentTagsSection extends ConsumerWidget {
  const BusinessFrequentTagsSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(_businessFrequentTagsProvider(businessId));
    return tagsAsync.maybeWhen(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        final t = AppLocalizations.of(context);
        final isLocTr = t.localeName.startsWith('tr');
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLocTr ? 'Sıkça Bahsedilen' : 'Frequently Mentioned',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(
                        tag.count >= 5 ? '${tag.tag} (${tag.count})' : tag.tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.primarySoft,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
