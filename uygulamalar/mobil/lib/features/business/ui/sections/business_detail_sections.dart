part of '../business_page.dart';

class BusinessHeaderSection extends ConsumerWidget {
  const BusinessHeaderSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _BusinessIdentityCard(business: business),
        const SizedBox(height: 8),
        _BusinessHeaderCompactContainer(business: business),
      ],
    );
  }
}

class _BusinessIdentityCard extends StatelessWidget {
  const _BusinessIdentityCard({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${business.category} - ${_locText(context, business.district, business.city)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BusinessHeaderCompactContainer extends ConsumerWidget {
  const _BusinessHeaderCompactContainer({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final (openNow, closeText) = ref.watch(
      _businessHoursProvider(business.id).select((async) {
        return async.maybeWhen(
          data: (today) {
            if (today == null) return (null, t.noTime);
            return (
              _isOpenNow(today.open, today.close, DateTime.now()),
              today.close ?? t.noTime,
            );
          },
          orElse: () => (null, t.noTime),
        );
      }),
    );
    final topItems = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value ?? const [];
        if (items.isEmpty) return const <String>[];
        return items
            .map((e) => e.itemName.trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .toList(growable: false);
      }),
    );
    final topItemPriceCents = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return null;
        return items.first.priceCents;
      }),
    );
    final topItemCurrency = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return 'TRY';
        return items.first.currency;
      }),
    );
    final firstMenuId = ref.watch(
      businessMenusProvider(business.id).select((async) {
        final menus = async.asData?.value;
        if (menus == null || menus.isEmpty) return null;
        return menus.first.id;
      }),
    );
    final lastVerifiedText = _daysAgoText(context, business.lifecycleUpdatedAt);
    final topItemsText = topItems.isEmpty ? t.unknown : topItems.join(', ');

    return BusinessHeaderCompact(
      isOpenNow: openNow,
      closingTimeText: closeText,
      averagePriceText: _formatPriceWithCurrency(
        context,
        topItemPriceCents,
        topItemCurrency,
      ),
      topItemsText: topItemsText,
      lastVerifiedText: lastVerifiedText,
      onDirectionsTap: () {
        unawaited(
          _openDirections(
            businessName: business.name,
            address: business.address,
            lat: business.lat,
            lng: business.lng,
          ),
        );
      },
      onMenuTap: () {
        if (firstMenuId == null) return;
        context.go('/b/${business.id}/menu/$firstMenuId');
      },
    );
  }
}

class BusinessActionsSection extends ConsumerWidget {
  const BusinessActionsSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(business.id));

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () async {
                if (!isLoggedIn) {
                  await showQuickLoginSheet(
                    context,
                    redirectPath: '/b/${business.id}',
                  );
                  return;
                }
                try {
                  HapticFeedback.lightImpact();
                  await ref
                      .read(favoritesControllerProvider.notifier)
                      .toggleFavorite(business.id);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppErrorMapper.message(error))),
                  );
                }
              },
              icon: Icon(isFavorited ? Icons.star : Icons.star_border),
              label: Text(isFavorited ? t.favoriteAdded : t.addToFavorites),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/b/${business.id}/review'),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(t.writeReview),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessTrustSection extends ConsumerWidget {
  const BusinessTrustSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(businessId));
    return trustAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (error, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.trustDataUnavailable,
        description:
            '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessTrustProvider(businessId)),
      ),
      data: (trust) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.freshnessAndTrust,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _TrustLine(
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.success,
                label: t.menuUpdatedLabel,
                value:
                    '${t.updatedDaysAgo(_daysAgo(trust.menuUpdatedAt))} ${t.versionAndSource(trust.menuVersion, _menuSourceLabel(context, trust.menuSource))}',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.price_check_outlined,
                iconColor: AppColors.success,
                label: t.lastPriceVerification,
                value:
                    '${t.verifiedDaysAgo(_daysAgo(trust.lastPriceVerifiedAt))} (${trust.lastPriceVerifiedPeople} ${t.usersLabel})',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.shield_outlined,
                iconColor: trust.trustScore >= 75
                    ? AppColors.warning
                    : AppColors.danger,
                label: t.communityScoreDataTrustLabel,
                value: '${trust.trustScore}/100',
              ),
              const SizedBox(height: 12),
              Text(
                t.last3MonthsPriceChange,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              _PriceChangeMiniChart(points: trust.priceChanges3m),
            ],
          ),
        );
      },
    );
  }
}

class BusinessHoursSection extends ConsumerWidget {
  const BusinessHoursSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hoursAsync = ref.watch(_businessHoursProvider(businessId));
    return hoursAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (_, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.hoursInfoUnavailable,
        description: t.connectionProblemTryAgain,
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessHoursProvider(businessId)),
      ),
      data: (today) {
        if (today == null) {
          return AppEmptyState(
            icon: Icons.schedule_outlined,
            title: t.hoursInfoMissing,
            description: t.addHoursHelp,
            ctaLabel: t.reportHoursInfo,
            onCta: () => _openReportSheet(context, businessId),
          );
        }
        final openNow = _isOpenNow(today.open, today.close, DateTime.now());
        return AppCard(
          child: Row(
            children: [
              Icon(
                openNow ? Icons.schedule : Icons.schedule_outlined,
                color: openNow ? AppColors.success : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  openNow
                      ? '${t.openNow} - ${_hoursText(context, today.open, today.close)}'
                      : '${t.closedNow} - ${_hoursText(context, today.open, today.close)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusinessMenusSection extends ConsumerWidget {
  const BusinessMenusSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final menusAsync = ref.watch(businessMenusProvider(businessId));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.menus,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          menusAsync.when(
            loading: () => const AppSkeletonLine(width: 140),
            error: (error, _) => AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.menusLoadFailed,
              description:
                  '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
              ctaLabel: AppLocalizations.of(context).retry,
              onCta: () => ref.invalidate(businessMenusProvider(businessId)),
            ),
            data: (menus) {
              if (menus.isEmpty) {
                return AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: t.noMenu,
                  description: t.addFirstMenuHelp,
                  ctaLabel: AppLocalizations.of(context).addFirstMenuCta,
                  onCta: () => _openReportSheet(context, businessId),
                );
              }
              return Column(
                children: [
                  for (final menu in menus)
                    ListTile(
                      key: ValueKey(menu.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(menu.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/b/$businessId/menu/${menu.id}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class BusinessCrowdSection extends ConsumerStatefulWidget {
  const BusinessCrowdSection({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<BusinessCrowdSection> createState() => _BusinessCrowdSectionState();
}

class _BusinessCrowdSectionState extends ConsumerState<BusinessCrowdSection> {
  bool _submitting = false;

  Future<void> _report(String crowd) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(businessCrowdProvider(widget.businessId).notifier)
          .submitPresence(crowd);
      ref.invalidate(businessCrowdProvider(widget.businessId));
    } catch (_) {
      // silent — best-effort crowd report
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final crowdAsync = ref.watch(businessCrowdProvider(widget.businessId));
    return AppCard(
      child: crowdAsync.when(
        loading: () => const AppSkeletonLine(width: 150),
        error: (error, s) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.crowdInfoUnavailable,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessCrowdProvider(widget.businessId)),
        ),
        data: (status) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, color: AppColors.textStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.liveCrowdLabel(status.state),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (status.userCanReport) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _CrowdChip(
                    label: 'Sakin',
                    icon: Icons.sentiment_satisfied_outlined,
                    onTap: _submitting ? null : () => _report('quiet'),
                  ),
                  _CrowdChip(
                    label: 'Orta',
                    icon: Icons.sentiment_neutral_outlined,
                    onTap: _submitting ? null : () => _report('moderate'),
                  ),
                  _CrowdChip(
                    label: 'Kalabalık',
                    icon: Icons.sentiment_very_dissatisfied_outlined,
                    onTap: _submitting ? null : () => _report('busy'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Şu anki kalabalığı bildirerek diğer kullanıcılara yardım et.',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CrowdChip extends StatelessWidget {
  const _CrowdChip({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

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
              ctaLabel: t.writeFirstReview,
              onCta: () => context.go('/b/$businessId/review'),
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
              for (final review in detail.latestReviews.take(3))
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
    final providersAsync = ref.watch(businessMealCardProvidersProvider(businessId));
    return providersAsync.maybeWhen(
      data: (providers) {
        if (providers.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geçerli Yemek Kartları',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bu işletmede kabul edilen kartlar aşağıda listelenir.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
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
    final hasPerks = perksAsync.asData?.value.isNotEmpty ?? false;
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
              if (hasPerks)
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

class BusinessFooterSection extends StatelessWidget {
  const BusinessFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppLocalizations.of(context).reportInfoErrorPrefix} ${_fmtDate(DateTime.now())}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PriceChangeMiniChart extends StatelessWidget {
  const _PriceChangeMiniChart({required this.points});
  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final values = points.length == 3 ? points : [0, 0, 0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: maxValue <= 0
                          ? 6
                          : (8 + (values[i] / maxValue) * 42).clamp(8, 52),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${values[i]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 8),
        ],
      ],
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
                      onPressed: () =>
                          _openAllPhotos(context, urls),
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

  void _openAllPhotos(BuildContext context, List<String> urls,
      {int initial = 0}) {
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
  const _BusinessPhotosViewer(
      {required this.urls, required this.initialIndex});
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
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (context, e, stack) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
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
