part of '../kesif_sayfasi.dart';

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: label, tone: AppBadgeTone.neutral);
  }
}

class _V4GrowthHubCard extends ConsumerStatefulWidget {
  const _V4GrowthHubCard();

  @override
  ConsumerState<_V4GrowthHubCard> createState() => _V4GrowthHubCardState();
}

class _V4GrowthHubCardState extends ConsumerState<_V4GrowthHubCard> {
  bool _loggedNearMiss = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(myProfileProgressProvider, (_, next) {
      unawaited(_maybeLogNearMiss(next.asData?.value));
    }, fireImmediately: true);
  }

  Future<void> _maybeLogNearMiss(ProfileProgress? progress) async {
    if (_loggedNearMiss || progress == null) return;
    final remaining = progress.nextLevelXp - progress.xpInLevel;
    if (remaining <= 0 || remaining > 20) return;
    _loggedNearMiss = true;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.achievementNearMiss,
          source: 'discovery_growth_hub',
          clientId: clientId,
          meta: {'remaining_xp': remaining, 'level': progress.level},
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final progressAsync = ref.watch(myProfileProgressProvider);
    final progress = progressAsync.asData?.value;
    final levelText = progress == null ? 'Seviye' : 'Seviye ${progress.level}';
    final xpText = progress == null ? null : '${progress.totalXp} XP';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_2_outlined, color: AppColors.textStrong),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.quickShortcuts,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.quickShortcutsSubtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _V4Pill(t.trustScoreLabel),
              _V4Pill(t.savedItems),
              _V4Pill(t.createGroup),
              _V4Pill(t.notifications),
              _V4Pill(t.newPlaces),
            ],
          ),
          const SizedBox(height: 10),
          if (xpText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$levelText  $xpText',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(levelText),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/favorites'),
                icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                label: Text(t.savedItems),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/labs'),
                icon: const Icon(Icons.how_to_vote_outlined, size: 18),
                label: Text(t.myFriendGroup),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/inbox'),
                icon: const Icon(Icons.inbox_outlined, size: 18),
                label: Text(t.notifications),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/labs'),
                icon: const Icon(Icons.emoji_events_outlined, size: 18),
                label: Text(t.tasteExperts),
              ),
            ],
          ),
        ],
      ),
    );
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

class _V4Pill extends StatelessWidget {
  const _V4Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
        ),
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

