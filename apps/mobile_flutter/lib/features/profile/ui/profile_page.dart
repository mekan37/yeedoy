import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/ui/link_paste_field.dart';
import '../../../features/shared/ui/achievements/achievement_visuals.dart';
import '../../auth/domain/auth_providers.dart';
import '../../price_alerts/domain/price_alert_models.dart';
import '../../price_alerts/domain/price_alerts_provider.dart';
import '../domain/achievement.dart';
import '../domain/achievements_provider.dart';
import '../domain/business_feed_provider.dart';
import '../domain/creator_profile_provider.dart';
import '../domain/daily_micro_task.dart';
import '../domain/daily_micro_task_provider.dart';
import '../domain/moat_signals_provider.dart';
import '../domain/profile_progress_provider.dart';
import '../domain/profile_stats.dart';
import '../domain/profile_stats_provider.dart';
import '../domain/reputation_provider.dart';
import '../domain/user_moat_signals.dart';
import 'profile_settings_page.dart';
import 'components/achievements_grid.dart';
import 'components/profile_identity_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: t.profile),
              Tab(text: t.profileAlertsTab),
              Tab(text: t.profileFeedTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_ProfileTab(), _AlertsTab(), _FeedTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    final statsAsync = ref.watch(myProfileStatsProvider);
    final achievementsAsync = ref.watch(myAchievementsProvider);
    final dailyTaskAsync = ref.watch(myDailyMicroTaskProvider);
    final reputationAsync = ref.watch(myReputationScoreProvider);
    final progressAsync = ref.watch(myProfileProgressProvider);
    final creatorAsync = ref.watch(creatorProfileProvider);
    final moatSignalsAsync = ref.watch(myMoatSignalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProfileStatsProvider);
        ref.invalidate(myAchievementsProvider);
        ref.invalidate(myDailyMicroTaskProvider);
        ref.invalidate(myReputationScoreProvider);
        ref.invalidate(myProfileProgressProvider);
        ref.invalidate(creatorProfileProvider);
        ref.invalidate(myMoatSignalsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileIdentityCard(userEmail: user?.email),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(t.profileSettings),
              subtitle: Text(t.privacySocialSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (user == null) ...[
            _InfoCard(
              title: t.login,
              body: t.profileLoginToSeeContributions,
              actionLabel: t.login,
              onTap: () => context.go('/login?redirect=/profile'),
            ),
            const SizedBox(height: 12),
          ],
          creatorAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (creator) => Card(
              child: SwitchListTile(
                value: creator.isCreator,
                onChanged: user == null
                    ? null
                    : (value) {
                        ref
                            .read(creatorProfileControllerProvider)
                            .setIsCreator(value);
                      },
                title: Text(t.profileCreatorBadgeTitle),
                subtitle: Text(
                  creator.isCreator
                      ? t.profileCreatorBadgeEnabled
                      : t.profileCreatorBadgeDisabled,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          dailyTaskAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (task) => task == null
                ? const SizedBox.shrink()
                : _DailyTaskCard(
                    task: task,
                    segmentHint: _profileSegmentHint(
                      context,
                      moatSignalsAsync.asData?.value?.primarySegment,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.profileAddSocialLinkTitle,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  LinkPasteField(
                    label: t.linkLabel,
                    hintText: t.profileSocialLinksHint,
                    previewTitle: t.socialPreview,
                  ),
                  SizedBox(height: 8),
                  Text(
                    t.profileSocialSaveComingSoon,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.profileStatsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          statsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => _ErrorText(text: '$err'),
            data: (stats) => _StatsGrid(stats: stats),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.profileCommunityTrustTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  reputationAsync.when(
                    loading: () => Text(t.profileCalculating),
                    error: (err, _) => _ErrorText(text: '$err'),
                    data: (score) => Text(t.profileTrustScorePercent(score)),
                  ),
                  const SizedBox(height: 6),
                  progressAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (progress) {
                      if (progress == null) return const SizedBox.shrink();
                      final value = progress.nextLevelXp == 0
                          ? 0.0
                          : (progress.xpInLevel / progress.nextLevelXp).clamp(
                              0.0,
                              1.0,
                            );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.profileLevelXp(progress.level, progress.totalXp),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: value),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          moatSignalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (signals) => signals == null
                ? const SizedBox.shrink()
                : _MoatSignalsCard(signals: signals),
          ),
          const SizedBox(height: 12),
          Text(
            t.profileMyAchievementsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          achievementsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => _ErrorText(text: '$err'),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyText(text: t.profileNoAchievementYet);
              }
              final latestUnlocked = items
                  .where((e) => e.unlocked && e.unlockedAt != null)
                  .fold<Achievement?>(
                    null,
                    (prev, curr) =>
                        prev == null ||
                            curr.unlockedAt!.isAfter(prev.unlockedAt!)
                        ? curr
                        : prev,
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latestUnlocked != null)
                    _LatestAchievementBanner(item: latestUnlocked),
                  const SizedBox(height: 8),
                  AchievementsGrid(items: items),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    if (user == null) {
      return Center(child: Text(t.profileAlertsLoginRequired));
    }

    final eventsAsync = ref.watch(
      myAlertEventsProvider(const AlertEventsParams()),
    );
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: _ErrorText(text: '$err')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: _EmptyText(text: t.profileAlertsEmpty),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _AlertEventTile(item: items[index]),
        );
      },
    );
  }
}

class _FeedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
    if (user == null) {
      return Center(child: Text(t.profileFeedLoginRequired));
    }

    final feedAsync = ref.watch(
      businessFeedProvider(const BusinessFeedParams()),
    );
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: _ErrorText(text: '$err')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: _EmptyText(text: t.profileFeedEmpty),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.businessName),
                subtitle: Text(_feedSubtitle(context, item)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/business/${item.event.businessId}'),
              ),
            );
          },
        );
      },
    );
  }

  String _feedSubtitle(BuildContext context, BusinessFeedItem item) {
    final t = AppLocalizations.of(context);
    final type = item.event.type;
    if (type == 'price_verified') return t.profileFeedEventPriceVerified;
    if (type == 'menu_updated') return t.profileFeedEventMenuUpdated;
    if (type == 'sponsored') return t.profileFeedEventSponsored;
    return t.profileCommunityTrustTitle;
  }
}

class _DailyTaskCard extends StatelessWidget {
  const _DailyTaskCard({required this.task, this.segmentHint});

  final DailyMicroTask task;
  final String? segmentHint;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t.profileDailyTaskTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.completed
                        ? t.profileDailyTaskCompleted
                        : '${task.currentValue}/${task.targetValue}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(color: AppColors.muted),
            ),
            if ((segmentHint ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                segmentHint!,
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.progress,
              color: task.completed ? AppColors.success : AppColors.primary,
              backgroundColor: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

String _profileSegmentHint(BuildContext context, String? segment) {
  final t = AppLocalizations.of(context);
  switch (segment) {
    case 'price_hunter':
      return t.profileSegmentHintPriceHunter;
    case 'photo_proof':
      return t.profileSegmentHintPhotoProof;
    case 'explorer':
      return t.profileSegmentHintExplorer;
    default:
      return t.profileSegmentHintDefault;
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(label: t.profileStatReviews, value: '${stats.reviewsCount}'),
        _StatChip(label: t.profileStatHelpfulVotes, value: '${stats.helpfulReceived}'),
        _StatChip(label: t.profileStatFavorites, value: '${stats.favoritesCount}'),
        _StatChip(label: t.profileStatContributions, value: '${stats.contributionScore}'),
        _StatChip(label: t.profileStatVisits, value: '${stats.visitsCount}'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _LatestAchievementBanner extends StatelessWidget {
  const _LatestAchievementBanner({required this.item});

  final Achievement item;

  @override
  Widget build(BuildContext context) {
    final visual = appAchievementVisualForId(
      item.id,
      fallbackHex: item.colorHex,
    );
    final t = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: FaIcon(visual.icon, color: visual.color, size: 22),
        title: Text(
          t.profileLatestAchievementTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(item.title),
        trailing: const Icon(Icons.celebration_outlined),
      ),
    );
  }
}

class _AlertEventTile extends StatelessWidget {
  const _AlertEventTile({required this.item});

  final AlertEventItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = item.event.matchedPriceCents / 100;
    final previous = item.event.previousPriceCents != null
        ? (item.event.previousPriceCents! / 100).toStringAsFixed(0)
        : null;

    return Card(
      child: ListTile(
        title: Text(item.businessName),
        subtitle: Text(
          previous == null
              ? t.profileAlertCurrentPrice(current.toStringAsFixed(0))
              : t.profileAlertPriceChanged(
                  previous,
                  current.toStringAsFixed(0),
                ),
        ),
        trailing: const Icon(Icons.notifications_active_outlined),
      ),
    );
  }
}

class _MoatSignalsCard extends StatelessWidget {
  const _MoatSignalsCard({required this.signals});

  final UserMoatSignals signals;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final segmentLabel = switch (signals.primarySegment) {
      'price_hunter' => t.profileSegmentPriceHunter,
      'explorer' => t.profileSegmentExplorer,
      'photo_proof' => t.profileSegmentPhotoProof,
      _ => t.profileSegmentBalanced,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.profileMoatSignalsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SignalChip(label: t.profileSignalTrust, value: '%${signals.trustScore}'),
                _SignalChip(
                  label: t.profileSignalAccuracy,
                  value: '%${signals.accuracyScore}',
                ),
                _SignalChip(label: t.profileSignalSegment, value: segmentLabel),
                _SignalChip(
                  label: t.profileSignalSilentQuality,
                  value: '${signals.silentQualityScore}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t.profileMoatTrustedRejectedSpam(
                signals.trustedActions,
                signals.rejectedActions,
                signals.spamSignals,
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              t.profileMoatBehaviorSummary(
                signals.priceActions,
                signals.discoveryActions,
                signals.photoActions,
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (signals.isSilentQuality) ...[
              const SizedBox(height: 6),
              Text(
                t.profileMoatSilentQualityHint,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.label, required this.value});

  final String label;
  final String value;

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
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.danger));
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.muted));
  }
}



