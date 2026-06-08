part of '../business_page.dart';

class _BusinessHeroTrustHeader extends StatelessWidget {
  const _BusinessHeroTrustHeader({required this.business, this.isOpenNow});

  final Business business;
  final bool? isOpenNow;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radius20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: tokens.space16,
              right: tokens.space16,
              bottom: tokens.space16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                        type: StatusBadgeType.verified,
                        label: AppLocalizations.of(context).verified,
                      ),
                      if (isOpenNow != null) ...[
                        const SizedBox(width: 8),
                        _OpenNowHeroBadge(isOpen: isOpenNow!),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${business.category} - ${_locText(context, business.district, business.city)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _OpenNowHeroBadge extends StatelessWidget {
  const _OpenNowHeroBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Açık' : 'Kapalı',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOpen ? Colors.green[200] : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

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
