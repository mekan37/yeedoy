part of '../business_page.dart';

class _BusinessHeroTrustHeader extends ConsumerWidget {
  const _BusinessHeroTrustHeader({
    required this.business,
    required this.heroCollapse,
  });

  final Business business;
  final ValueNotifier<double> heroCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(business.id));
    final showMenuVerified = trustAsync.value?.menuSource == 'owner';
    const collapsedHeight = 56.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedHeight = constraints.maxWidth * 10 / 16;
        return ValueListenableBuilder<double>(
          valueListenable: heroCollapse,
          builder: (context, progress, _) {
            final height =
                expandedHeight + (collapsedHeight - expandedHeight) * progress;
            // Image and verified badges fade out over the first 70% of the
            // collapse so the photo is fully gone before the bar settles.
            final imageOpacity = (1 - progress / 0.7).clamp(0.0, 1.0);
            final radius = tokens.radius20 * (1 - progress);
            return ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                height: height,
                color: Color.lerp(Colors.transparent, AppColors.card, progress),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageOpacity > 0)
                      Opacity(opacity: imageOpacity, child: _buildHeroImage()),
                    if (imageOpacity > 0)
                      Opacity(
                        opacity: imageOpacity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: tokens.space12,
                      left: tokens.space12,
                      child: _HeroOverlayButton(
                        icon: Icons.arrow_back,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        progress: progress,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/discover');
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: tokens.space12,
                      right: tokens.space12,
                      child: Row(
                        children: [
                          _HeroOverlayButton(
                            icon: Icons.share_outlined,
                            tooltip: AppLocalizations.of(context).share,
                            progress: progress,
                            onPressed: () =>
                                unawaited(_shareBusiness(context, business)),
                          ),
                          SizedBox(width: tokens.space8),
                          _FavoriteToggleButton(
                            businessId: business.id,
                            overlay: true,
                            progress: progress,
                          ),
                        ],
                      ),
                    ),
                    if ((business.isVerified || showMenuVerified) &&
                        imageOpacity > 0)
                      Positioned(
                        bottom: tokens.space12,
                        left: tokens.space12,
                        right: tokens.space12,
                        child: Opacity(
                          opacity: imageOpacity,
                          child: Wrap(
                            spacing: tokens.space8,
                            runSpacing: tokens.space8,
                            children: [
                              if (business.isVerified)
                                _HeroBadgeChip(
                                  icon: Icons.verified_rounded,
                                  label: t.verified,
                                ),
                              if (showMenuVerified)
                                _HeroBadgeChip(
                                  icon: Icons.verified_outlined,
                                  label: t.businessBadgeMenuVerified,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroImage() {
    final remote =
        _normalizeImageUrl(
          business.heroImageUrl ??
              business.coverImageUrl ??
              business.imageUrl ??
              business.logoUrl,
        ) ??
        '';
    // Deterministic Hero tag: 'business-image-<id>'
    // Matching tag must be applied on any source widget (list card, smart feed)
    // that shows the same business image to enable the shared-element transition.
    final heroTag = 'business-image-${business.id}';
    if (remote.isNotEmpty) {
      return Hero(
        tag: heroTag,
        child: AppNetworkImage(
          url: remote,
          fit: BoxFit.cover,
          variant: AppImageVariant.medium,
        ),
      );
    }
    return Hero(
      tag: heroTag,
      child: Image.asset(
        CategoryAssets.resolve(business.category),
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BusinessInfoPanel extends StatelessWidget {
  const _BusinessInfoPanel({required this.business, this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        tokens.space16,
        tokens.space16,
        tokens.space16,
        tokens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tokens.radius24),
          topRight: Radius.circular(tokens.radius24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.report,
                onPressed: () => _openReportSheet(context, business.id),
                icon: const Icon(Icons.flag_outlined, color: AppColors.muted),
              ),
            ],
          ),
          SizedBox(height: tokens.space8),
          Wrap(
            spacing: tokens.space8,
            runSpacing: tokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (business.reviewsCount > 0)
                _BadgeChip(
                  icon: Icons.star_rounded,
                  label:
                      '${business.avgRating.toStringAsFixed(1)} (${business.reviewsCount})',
                  color: AppColors.warning,
                ),
              if (isOpenNow != null)
                _BadgeChip(
                  icon: Icons.schedule,
                  label: isOpenNow! ? t.openNow : t.closedNow,
                  color: isOpenNow! ? AppColors.success : AppColors.danger,
                ),
            ],
          ),
          SizedBox(height: tokens.space8),
          Text(
            '${business.category} · ${_locText(context, business.district, business.city)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _BusinessInfoRow(business: business),
          _BusinessBadgeChipRow(business: business),
          _BusinessDescription(description: business.description),
        ],
      ),
    );
  }
}

class _HeroOverlayButton extends StatelessWidget {
  const _HeroOverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.progress = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color iconColor;

  /// Hero collapse progress (0 = expanded photo, 1 = collapsed bar). Used to
  /// fade the circular overlay background out and the icon color from white
  /// to the normal text color so the buttons stay legible once the photo is
  /// gone.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(
      Colors.black.withValues(alpha: 0.35),
      Colors.transparent,
      progress,
    );
    final color = Color.lerp(iconColor, AppColors.text, progress);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _HeroBadgeChip extends StatelessWidget {
  const _HeroBadgeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteToggleButton extends ConsumerWidget {
  const _FavoriteToggleButton({
    required this.businessId,
    this.overlay = false,
    this.progress = 0,
  });

  final String businessId;
  final bool overlay;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(businessId));
    final tooltip = isFavorited ? t.favoriteAdded : t.addToFavorites;
    final icon = isFavorited ? Icons.favorite : Icons.favorite_border;

    Future<void> handleToggle() async {
      if (!isLoggedIn) {
        await showQuickLoginSheet(context, redirectPath: '/b/$businessId');
        return;
      }
      try {
        HapticFeedback.lightImpact();
        await ref
            .read(favoritesControllerProvider.notifier)
            .toggleFavorite(businessId);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppErrorMapper.message(error))));
      }
    }

    if (overlay) {
      return _HeroOverlayButton(
        icon: icon,
        tooltip: tooltip,
        iconColor: isFavorited ? AppColors.danger : Colors.white,
        progress: progress,
        onPressed: () => unawaited(handleToggle()),
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: () => unawaited(handleToggle()),
      icon: Icon(icon, color: isFavorited ? AppColors.primary : AppColors.text),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessBadgeChipRow extends ConsumerWidget {
  const _BusinessBadgeChipRow({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));

    final showPopular = trendingAsync.value?.isNotEmpty ?? false;

    if (!showPopular) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: tokens.space12),
      child: Wrap(
        spacing: tokens.space8,
        runSpacing: tokens.space8,
        children: [
          _BadgeChip(
            icon: Icons.local_fire_department_outlined,
            label: t.businessBadgePopular,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _BusinessDescription extends StatelessWidget {
  const _BusinessDescription({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.space12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BusinessInfoRow extends ConsumerWidget {
  const _BusinessInfoRow({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(
      discoverySearchProvider.select((s) => (s.userLat, s.userLng)),
    );
    final userLat = loc.$1;
    final userLng = loc.$2;

    double? distanceKm;
    if (business.lat != null &&
        business.lng != null &&
        userLat != null &&
        userLng != null) {
      distanceKm =
          _haversineKm(userLat, userLng, business.lat!, business.lng!);
    }

    final walkMinutes = distanceKm != null
        ? (distanceKm / 4.5 * 60).round().clamp(1, 99)
        : null;

    final priceInfo = _priceInfo(business.priceLevel);

    if (distanceKm == null && priceInfo == null) return const SizedBox.shrink();

    final tokens = AppTokens.of(context);
    final parts = <String>[];

    if (distanceKm != null) {
      final distText = distanceKm < 1
          ? '${(distanceKm * 1000).round()} m'
          : '${distanceKm.toStringAsFixed(1)} km';
      parts.add('📍 $distText');
      if (walkMinutes != null) parts.add('~$walkMinutes dk yürüme');
    }

    if (priceInfo != null) {
      parts.add('${priceInfo.$1} ${priceInfo.$2}');
    }

    return Padding(
      padding: EdgeInsets.only(top: tokens.space8),
      child: Text(
        parts.join(' · '),
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    );
  }

  static (String, String)? _priceInfo(String? level) {
    switch (level) {
      case 'budget': return ('₺', 'Ekonomik');
      case 'mid': return ('₺₺', 'Orta');
      case 'premium': return ('₺₺₺', 'Üst Düzey');
      default: return null;
    }
  }
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _deg2rad(double deg) => deg * (pi / 180);

class _TopStatCard extends StatelessWidget {
  const _TopStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.circleValue,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final double? circleValue;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space12,
        vertical: tokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (circleValue != null)
            TrustScoreIndicator(
              score: (circleValue! * 100).round(),
              size: 52,
              showLabel: false,
            )
          else
            Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            value + subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityVerifiedCard extends StatelessWidget {
  const _CommunityVerifiedCard({required this.usersToday});

  final int usersToday;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space12,
        vertical: tokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radius20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).communityVerified,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(
                    context,
                  ).confirmedByUsersToday(usersToday),
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}
