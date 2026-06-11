part of '../discovery_page.dart';

class _DiscoveryGreetingHeader extends ConsumerWidget {
  const _DiscoveryGreetingHeader({String? subtitle}) : _subtitle = subtitle;

  final String? _subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);

    String? displayName;
    if (user != null) {
      final profileAsync = ref.watch(publicProfileProvider(user.id));
      final name = profileAsync.asData?.value.displayName.trim() ?? '';
      if (name.isNotEmpty) displayName = name;
    }

    final greeting = displayName != null
        ? t.discoveryGreetingHello(displayName)
        : t.discoveryGreetingHelloAnon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle ?? t.discoveryGreetingSubtitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// Estimates a walking-time range from [distanceKm] using a 4-5 km/h
/// walking speed. Returns null for non-positive distances. Falls back to
/// a single value (via [AppLocalizations.timeMinutes]) when the rounded
/// bounds collapse to the same minute.
String? _walkingEtaLabel(AppLocalizations t, double distanceKm) {
  if (distanceKm <= 0) return null;
  final minMinutes = (distanceKm * 12).ceil();
  final maxMinutes = (distanceKm * 15).ceil();
  if (maxMinutes <= minMinutes) return t.timeMinutes(minMinutes);
  return t.etaRangeMinutes(minMinutes, maxMinutes);
}

class _ForYouBusinessCard extends StatelessWidget {
  const _ForYouBusinessCard({
    required this.item,
    required this.imageAsset,
    required this.ratingLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String ratingLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final distanceKm = item.distanceKm ?? 0.4;
    final distance = t.distanceKm(double.parse(distanceKm.toStringAsFixed(1)));
    final eta = _walkingEtaLabel(t, distanceKm);
    final priceSymbol = priceLevelSymbol(item.priceLevel, item.medianPriceCents);

    return AppCard(
      padding: const EdgeInsets.all(0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(tokens.radius20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: tokens.space8,
                top: tokens.space8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.solidStar,
                        size: 11,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: tokens.space8,
                top: tokens.space8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onFavoriteTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.primary : AppColors.muted,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space12,
              tokens.space12,
              tokens.space12,
              tokens.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: tokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                    ),
                    if (item.isOpenNow != null) ...[
                      SizedBox(width: tokens.space8),
                      OpenStatusBadge(isOpen: item.isOpenNow!),
                    ],
                  ],
                ),
                SizedBox(height: tokens.space8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              eta == null ? distance : '$distance • $eta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (priceSymbol != null) ...[
                      SizedBox(width: tokens.space8),
                      PriceLevelBadge(symbol: priceSymbol),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryPromoBanner extends StatelessWidget {
  const _DiscoveryPromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(tokens.radius20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radius20),
        child: Padding(
          padding: EdgeInsets.all(tokens.space16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.whatToEatTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.whatToEatDescription,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.arrowRight,
                  color: AppColors.onPrimary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreshLinkCard extends StatelessWidget {
  const _FreshLinkCard({required this.item, required this.onTap});

  final Embed item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = item.provider.toLowerCase();
    final (icon, color, label) = switch (provider) {
      'youtube' => (Icons.play_circle_fill_rounded, Colors.red, 'YouTube'),
      'instagram' => (Icons.camera_alt_rounded, Colors.pink, 'Instagram'),
      'facebook' => (Icons.facebook_rounded, Colors.blue, 'Facebook'),
      _ => (
        Icons.link_rounded,
        AppColors.muted,
        AppLocalizations.of(context).link,
      ),
    };
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : AppLocalizations.of(context).untitledLink;
    final ownerType = item.ownerType.toLowerCase() == 'business'
        ? AppLocalizations.of(context).businessLabel
        : AppLocalizations.of(context).profile;
    return SizedBox(
      width: 220,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              ownerType,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _agoText(context, item.createdAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

String _agoText(BuildContext context, DateTime value) {
  final t = AppLocalizations.of(context);
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 60) return t.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.timeHoursAgo(diff.inHours);
  return t.timeDaysAgo(diff.inDays);
}

class _PremiumFilterChip extends StatelessWidget {
  const _PremiumFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.filledPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool filledPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usePrimary = selected && filledPrimary;
    final bg = usePrimary ? AppColors.primary : AppColors.card;
    final textColor = usePrimary ? AppColors.onPrimary : AppColors.textStrong;
    final borderColor = usePrimary ? AppColors.primary : AppColors.borderStrong;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryUpdateCard extends StatelessWidget {
  const _DiscoveryUpdateCard({
    required this.item,
    required this.imageAsset,
    required this.timeLabel,
    required this.onTap,
  });

  final BusinessCardModel item;
  final String imageAsset;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SerendipityCard extends StatelessWidget {
  const _SerendipityCard({required this.onPick});

  final void Function(_SerendipityKind kind) onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.surpriseDiscoveryTitle,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            t.surpriseDiscoverySubtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.randomGood),
                icon: const Icon(Icons.shuffle),
                label: Text(t.randomButGood),
              ),
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.unexpected),
                icon: const Icon(Icons.explore_outlined),
                label: Text(t.outsideYourUsual),
              ),
              OutlinedButton.icon(
                onPressed: () => onPick(_SerendipityKind.valueSurprise),
                icon: const Icon(Icons.savings_outlined),
                label: Text(t.pricePerformanceSurprise),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SponsoredSkeleton extends StatelessWidget {
  const _SponsoredSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeletonCard(),
        SizedBox(height: 10),
        AppSkeletonCard(),
        SizedBox(height: 6),
      ],
    );
  }
}

class _TodayPickCard extends StatelessWidget {
  const _TodayPickCard({required this.item, required this.onRetry});

  final MenuItemSearchResult item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(context, item.priceCents);
    final status = _statusBadge(context, item.priceStatus);
    final locationText = _shortLocation(item.district, item.city);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  priceText,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _StatusBadge(config: status),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.businessName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (item.distanceKm != null)
                  Text(
                    '${item.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (locationText != null) ...[
              const SizedBox(height: 4),
              Text(
                locationText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _openMenuItem(context, item),
                    child: Text(AppLocalizations.of(context).go),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: Text(AppLocalizations.of(context).restart),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
