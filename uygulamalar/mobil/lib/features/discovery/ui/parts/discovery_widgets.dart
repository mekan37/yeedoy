part of '../discovery_page.dart';

/// Compact pill/segment style replacement for the default Material [TabBar]
/// used to switch between Önerilenler / Kampanyalar / Yemekler.
class _DiscoveryPillTabBar extends StatelessWidget {
  const _DiscoveryPillTabBar({required this.t});

  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.space16,
        0,
        tokens.space16,
        tokens.space8,
      ),
      child: AppSegmentedTabBar(
        labels: [t.tabRecommended, t.tabCampaigns, t.tabFoods],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: label, tone: AppBadgeTone.neutral);
  }
}

class _DiscoveryLabsHubCard extends StatelessWidget {
  const _DiscoveryLabsHubCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.drawerExperimental,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SmallBadge(t.budgetComboResultsTitle),
                    _SmallBadge(t.drawerGroupRequests),
                    _SmallBadge(t.drawerHeroes),
                    _SmallBadge(t.drawerTasteTwin),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.go('/labs'),
            child: Text(t.view),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeConfig {
  const _StatusBadgeConfig(this.label, this.type);
  final String label;
  final StatusBadgeType type;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.config});
  final _StatusBadgeConfig config;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(type: config.type, label: config.label);
  }
}
