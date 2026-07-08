part of '../discovery_page.dart';

// ─── Discovery shimmer infrastructure ────────────────────────────────────────

/// Dark-mode aware shimmer animation wrapper, scoped to the discovery feature.
///
/// Uses a single [AnimationController] that drives a sweeping [LinearGradient]
/// over all child placeholder shapes via [ShaderMask]. Wrapped in a
/// [RepaintBoundary] so the looping animation never triggers repaints on
/// ancestor widgets.
///
/// Duration: 1200 ms, [Curves.easeInOut], repeating.
class _DiscoveryShimmer extends StatefulWidget {
  const _DiscoveryShimmer({required this.child});

  final Widget child;

  @override
  State<_DiscoveryShimmer> createState() => _DiscoveryShimmerState();
}

class _DiscoveryShimmerState extends State<_DiscoveryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark
        ? const Color(0xFF232638) // slightly lighter dark card surface
        : const Color(0xFFEEECEB); // warm near-white, matches card surface
    final Color highlight = isDark
        ? const Color(0xFF2E3248) // elevated dark surface highlight
        : const Color(0xFFF7F4F2); // warm light highlight

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final pos = _anim.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-2.0 + 4.0 * pos, 0),
              end: Alignment(-1.0 + 4.0 * pos, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Rectangular placeholder block used inside [_DiscoveryShimmer].
/// [color] is opaque — the [ShaderMask] above rewrites it with the gradient.
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius ?? tokens.radius12),
      ),
    );
  }
}

/// Narrow line placeholder — used for text rows inside [_DiscoveryShimmer].
class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({this.width, this.height = 10.0});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

// ─── Discovery shimmer skeleton ───────────────────────────────────────────────

/// Single [BusinessTile]-shaped placeholder card.
///
/// Mirrors [BusinessTile] layout:
///   • 64 × 64 thumbnail box on the left (radius16)
///   • Three text lines on the right (name / category / subtitle)
///   • Two badge pill placeholders at the bottom
///   • Trailing chevron placeholder on the far right
///
/// All sizing uses [AppTokens] — no hardcoded spacing or radii.
class _DiscoverySkeletonCard extends StatelessWidget {
  const _DiscoverySkeletonCard();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(tokens.radius20),
        boxShadow: AppTokens.shadow1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder — matches BusinessTile's 64×64 icon box
          _ShimmerBox(height: 64, width: 64, borderRadius: tokens.radius16),
          SizedBox(width: tokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business name line
                _ShimmerLine(height: 14, width: double.infinity),
                SizedBox(height: tokens.space8),
                // Category row
                _ShimmerLine(height: 10, width: 140),
                SizedBox(height: tokens.space8),
                // Subtitle (district / city)
                _ShimmerLine(height: 10, width: 100),
                SizedBox(height: tokens.space12),
                // Badge row (open status + price level pills)
                Row(
                  children: [
                    _ShimmerBox(height: 20, width: 56, borderRadius: 999),
                    SizedBox(width: tokens.space8),
                    _ShimmerBox(height: 20, width: 36, borderRadius: 999),
                  ],
                ),
              ],
            ),
          ),
          // Trailing chevron placeholder
          Padding(
            padding: EdgeInsets.only(top: tokens.space4),
            child: _ShimmerBox(height: 20, width: 20, borderRadius: 6),
          ),
        ],
      ),
    );
  }
}

/// Renders [count] [_DiscoverySkeletonCard] widgets wrapped in a single
/// [_DiscoveryShimmer] — one animation controller drives all cards
/// simultaneously without spawning per-card controllers.
class _DiscoverySkeletonList extends StatelessWidget {
  const _DiscoverySkeletonList({this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _DiscoveryShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            const _DiscoverySkeletonCard(),
            if (i < count - 1) SizedBox(height: tokens.space12),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton shown when the discovery list is loading with no cached
/// items. Replaces the former [AppSkeletonCard]-based placeholder.
class _DiscoverySkeleton extends StatelessWidget {
  const _DiscoverySkeleton();

  @override
  Widget build(BuildContext context) {
    return const _DiscoverySkeletonList(count: 6);
  }
}

class _DiscoveryMapSkeleton extends StatelessWidget {
  const _DiscoveryMapSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return _DiscoveryShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerLine(width: 120, height: 14),
          SizedBox(height: tokens.space12),
          _ShimmerBox(height: 220),
          SizedBox(height: tokens.space8),
          _ShimmerLine(width: 200, height: 10),
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
