import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../shared/ui/components/community_score_explainer_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/achievement.dart';
import '../domain/achievements_provider.dart';
import '../domain/creator_profile_provider.dart';
import '../domain/daily_micro_task.dart';
import '../domain/daily_micro_task_provider.dart';
import '../domain/favorite_collections_count_provider.dart';
import '../domain/moat_signals_provider.dart';
import '../domain/profile_progress_provider.dart';
import '../domain/profile_stats_provider.dart';
import '../domain/reputation_provider.dart';
import '../domain/user_moat_signals.dart';
import 'profile_settings_page.dart';
import 'components/profile_identity_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ProfileTab();
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(userProvider);
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
          const _ProfileHomeHeader(),
          const SizedBox(height: 12),
          _ProfileHeroCard(userEmail: user?.email),
          const SizedBox(height: 12),
          const _ProfileQuickActionsGrid(),
          const SizedBox(height: 12),
          const _ProfileAccountList(),
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
          // ── İçerik Üretici Rozeti ────────────────────────────────────
          creatorAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (creator) => _CreatorBadgeCard(
              isCreator: creator.isCreator,
              enabled: user != null,
              onChanged: (v) =>
                  ref.read(creatorProfileControllerProvider).setIsCreator(v),
            ),
          ),
          const SizedBox(height: 12),
          // ── Günlük Görevler ──────────────────────────────────────────
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
          // ── Güven & İlerleme ─────────────────────────────────────────
          _CommunityTrustCard(
            reputationAsync: reputationAsync,
            progressAsync: progressAsync,
          ),
          const SizedBox(height: 12),
          // ── Katkı Profili ────────────────────────────────────────────
          moatSignalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (signals) => signals == null
                ? const SizedBox.shrink()
                : _MoatSignalsCard(signals: signals),
          ),
          const SizedBox(height: 12),
          _AchievementsNavCard(achievementsAsync: achievementsAsync),
        ],
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _SectionCardShell extends StatelessWidget {
  const _SectionCardShell({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.textStrong,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.bottom,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textStrong,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (bottom != null) ...[const SizedBox(height: 10), bottom!],
          ],
        ),
      ),
    );
  }
}

Widget _statusBadge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(
    label,
    style: TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: 12,
    ),
  ),
);

// ── İçerik Üretici Rozeti ─────────────────────────────────────────────────────

class _CreatorBadgeCard extends StatelessWidget {
  const _CreatorBadgeCard({
    required this.isCreator,
    required this.enabled,
    required this.onChanged,
  });

  final bool isCreator;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCardShell(
      children: [
        _CardHeader(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          title: 'İçerik Üretici Rozeti',
          trailing: Switch(
            value: isCreator,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: isCreator ? Icons.verified_rounded : Icons.info_outline_rounded,
          iconColor:
              isCreator ? AppColors.success : AppColors.muted,
          iconBg:
              isCreator
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.border.withValues(alpha: 0.5),
          title: isCreator ? 'Rozet Aktif' : 'Rozet Kapalı',
          subtitle: isCreator
              ? 'Toplulukta içerik üreticisi olarak görünüyorsun'
              : 'Etkinleştirerek profilinde öne çık',
          trailing: _statusBadge(
            isCreator ? 'Aktif' : 'Kapalı',
            isCreator ? AppColors.success : AppColors.muted,
          ),
        ),
      ],
    );
  }
}

// ── Güven & İlerleme ──────────────────────────────────────────────────────────

class _CommunityTrustCard extends StatelessWidget {
  const _CommunityTrustCard({
    required this.reputationAsync,
    required this.progressAsync,
  });

  final AsyncValue<int> reputationAsync;
  final AsyncValue<dynamic> progressAsync;

  @override
  Widget build(BuildContext context) {
    final score = reputationAsync.asData?.value ?? 0;
    final progress = progressAsync.asData?.value;
    final xpRatio = progress == null || progress.nextLevelXp == 0
        ? 0.0
        : (progress.xpInLevel / progress.nextLevelXp).clamp(0.0, 1.0);

    return _SectionCardShell(
      children: [
        _CardHeader(
          icon: Icons.shield_outlined,
          iconColor: AppColors.info,
          iconBg: AppColors.info.withValues(alpha: 0.1),
          title: 'Güven & İlerleme',
          trailing: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.muted,
            ),
            onPressed: () => showCommunityScoreExplainerSheet(
              context,
              kind: CommunityScoreKind.userTrust,
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFF1E88E5),
          iconBg: const Color(0xFFE3F2FD),
          title: 'Kullanıcı Güveni',
          subtitle: 'Topluluğa güven sağlayan katkıların',
          trailing: reputationAsync.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _statusBadge('%$score', AppColors.info),
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          title: progress == null
              ? 'Seviye —'
              : 'Seviye ${progress.level}',
          subtitle: progress == null
              ? 'Hesaplanıyor…'
              : '${progress.totalXp} XP toplam  •  ${progress.xpInLevel}/${progress.nextLevelXp} sonraki seviye',
          bottom: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpRatio,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: const Color(0xFFD97706),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Katkı Profili (Moat Signals) ──────────────────────────────────────────────

// ── Achievements nav card ──────────────────────────────────────────────────────

class _AchievementsNavCard extends ConsumerWidget {
  const _AchievementsNavCard({required this.achievementsAsync});
  final AsyncValue<List<Achievement>> achievementsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(myProfileProgressProvider);
    final items = (achievementsAsync.asData?.value ?? <Achievement>[])
        .where((a) => !a.isHidden)
        .toList();
    final unlockedCount = items.where((a) => a.unlocked).length;
    final totalCount = items.length;
    final totalXp = progressAsync.asData?.value?.totalXp ?? 0;
    final pct = totalCount == 0
        ? 0.0
        : (unlockedCount / totalCount).clamp(0.0, 1.0);

    return _SectionCardShell(
      children: [
        _CardRow(
          icon: Icons.workspace_premium_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primarySoft,
          title: 'Başarı Rozetlerim',
          subtitle: '$unlockedCount / $totalCount rozet  •  $totalXp XP',
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          onTap: () => context.push('/achievements'),
          bottom: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}


class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radius12),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.minHitTarget * 1.4),
        padding: EdgeInsets.all(tokens.space12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(tokens.radius12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            SizedBox(height: tokens.space8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileQuickActionsGrid extends StatelessWidget {
  const _ProfileQuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.profileQuickActionsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.favorite_rounded,
                label: t.profileQuickActionFavorites,
                onTap: () => context.go('/favorites'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Yorumlarım',
                onTap: () {/* TODO: navigate to reviews */},
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.card_giftcard_rounded,
                label: 'Sadakat',
                onTap: () => context.push('/loyalty-cards'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.menu_book_rounded,
                label: 'Yemek Günlüğü',
                onTap: () => context.push('/food-journal'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.notifications_outlined,
                label: t.drawerInbox,
                onTap: () => context.go('/inbox'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.settings_outlined,
                label: t.profileSettings,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAccountList extends StatelessWidget {
  const _ProfileAccountList();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.profileAccountSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textStrong,
          ),
        ),
        SizedBox(height: tokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(tokens.radius16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
                title: Text(t.profileSettings),
                subtitle: const Text('Kişisel bilgilerini düzenle'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Adreslerim'),
                subtitle: const Text('Kayıtlı adreslerini yönet'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/account-security'),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Bildirim Tercihleri'),
                subtitle: const Text('Bildirim ayarlarını düzenle'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/inbox'),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(
                  Icons.headset_mic_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Yardım ve Destek'),
                subtitle: const Text('Sık sorulan sorular ve destek'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/legal'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileLocationRow extends ConsumerWidget {
  const _ProfileLocationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(userLocationProvider);
    if (loc.loading || loc.permissionDenied || !loc.hasLocation) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            loc.city!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}


class _ProfileStatsRow extends ConsumerWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tokens = AppTokens.of(context);
    final statsAsync = ref.watch(myProfileStatsProvider);
    final collectionsAsync = ref.watch(myFavoriteCollectionsCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tokens.radius12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCellIcon(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE53935),
                value: statsAsync.asData?.value.favoritesCount,
                label: t.profileStatFavoritesShort,
              ),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _StatCellIcon(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF1E88E5),
                value: statsAsync.asData?.value.reviewsCount,
                label: t.profileStatReviewsShort,
              ),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _StatCellIcon(
                icon: Icons.format_list_bulleted_rounded,
                iconColor: const Color(0xFF43A047),
                value: collectionsAsync.asData?.value,
                label: t.profileStatListsShort,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCellIcon extends StatelessWidget {
  const _StatCellIcon({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '—',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({this.userEmail});

  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: EdgeInsets.all(tokens.space16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(tokens.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileIdentityCard(userEmail: userEmail),
          const _ProfileLocationRow(),
          SizedBox(height: tokens.space12),
          const _ProfileStatsRow(),
        ],
      ),
    );
  }
}

class _ProfileHomeHeader extends StatelessWidget {
  const _ProfileHomeHeader();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba! 👋',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  t.profileHomeTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileSettingsPage(),
              ),
            ),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Daily task definitions ────────────────────────────────────────────────────

class _TaskDef {
  const _TaskDef({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.points,
  });

  final String key;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final int target;
  final int points;
}

const _kDailyTasks = <_TaskDef>[
  _TaskDef(
    key: 'review',
    icon: Icons.chat_bubble_outline_rounded,
    iconColor: Color(0xFFE53935),
    iconBg: Color(0xFFFFEBEE),
    title: '1 yorum yap',
    subtitle: 'Topluluğa değer katar.',
    target: 1,
    points: 20,
  ),
  _TaskDef(
    key: 'photo',
    icon: Icons.camera_alt_outlined,
    iconColor: Color(0xFFFF6D00),
    iconBg: Color(0xFFFFF3E0),
    title: '1 fotoğraf yükle',
    subtitle: 'Lezzetini görselleyle paylaş!',
    target: 1,
    points: 15,
  ),
  _TaskDef(
    key: 'price',
    icon: Icons.price_check_outlined,
    iconColor: Color(0xFF3949AB),
    iconBg: Color(0xFFE8EAF6),
    title: '1 fiyat doğrula',
    subtitle: 'Doğru fiyatlar, güçlü topluluk.',
    target: 1,
    points: 20,
  ),
  _TaskDef(
    key: 'discover',
    icon: Icons.location_on_outlined,
    iconColor: Color(0xFF00897B),
    iconBg: Color(0xFFE0F2F1),
    title: '1 mekan keşfet',
    subtitle: 'Yeedoy\'u keşfet, puan kazan!',
    target: 1,
    points: 25,
  ),
];

// ── Daily task card ────────────────────────────────────────────────────────────

class _DailyTaskCard extends StatelessWidget {
  const _DailyTaskCard({required this.task, this.segmentHint});

  final DailyMicroTask task;
  final String? segmentHint;

  int _currentFor(_TaskDef def) {
    if (task.taskKey.contains(def.key)) return task.currentValue;
    return 0;
  }

  bool _completedFor(_TaskDef def) {
    if (task.taskKey.contains(def.key)) return task.completed;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _kDailyTasks.where((d) => _completedFor(d)).length;
    final totalCount = _kDailyTasks.length;
    final progressValue =
        totalCount == 0 ? 0.0 : completedCount / totalCount;

    return _SectionCardShell(
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              const Text(
                'Günlük Görevler',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textStrong,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/achievements'),
                child: const Text(
                  'İlerleme ödülleri >',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Progress row + bar ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text(
                'Bugünkü ilerleme ',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              Text(
                '$completedCount/$totalCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 5,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ),
        // ── Segment hint ─────────────────────────────────────────────────
        if ((segmentHint ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              segmentHint!,
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        // ── Task rows ────────────────────────────────────────────────────
        for (final def in _kDailyTasks) ...[
          const Divider(height: 1, color: AppColors.border),
          _TaskRow(
            def: def,
            current: _currentFor(def),
            completed: _completedFor(def),
          ),
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.def,
    required this.current,
    required this.completed,
  });

  final _TaskDef def;
  final int current;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: def.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(def.icon, color: def.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textStrong,
                  ),
                ),
                Text(
                  def.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status + points
          if (completed) ...[
            _DailyPill(
              label: 'Tamamlandı',
              color: AppColors.success,
              filled: false,
            ),
            const SizedBox(width: 6),
            _PointsBadge(points: def.points, completed: true),
          ] else ...[
            Text(
              '$current/${def.target}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            _PointsBadge(points: def.points, completed: false),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyPill extends StatelessWidget {
  const _DailyPill({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points, required this.completed});

  final int points;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$points puan',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
    final approvalRate = signals.contributionCount <= 0
        ? 0
        : ((signals.approvedCount * 100) / signals.contributionCount)
              .round()
              .clamp(0, 100);

    return _SectionCardShell(
      children: [
        _CardHeader(
          icon: Icons.analytics_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFFEDE9FE),
          title: t.profileMoatSignalsTitle,
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: Icons.radar_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFE0F2FE),
          title: t.profileSignalSegment,
          subtitle: t.profileSupportSignalsSummary,
          trailing: _statusBadge(segmentLabel, const Color(0xFF0284C7)),
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: Icons.verified_outlined,
          iconColor: AppColors.success,
          iconBg: AppColors.success.withValues(alpha: 0.1),
          title: t.profileSignalAccuracy,
          subtitle: t.profileMoatTrustedRejectedSpam(
            signals.trustedActions,
            signals.rejectedActions,
            signals.spamSignals,
          ),
          trailing: _statusBadge('%${signals.accuracyScore}', AppColors.success),
        ),
        const Divider(height: 1, color: AppColors.border),
        _CardRow(
          icon: Icons.thumb_up_outlined,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          title: t.profileSignalApprovalRate,
          subtitle: t.profileMoatBehaviorSummary(
            signals.priceActions,
            signals.discoveryActions,
            signals.photoActions,
          ),
          trailing: _statusBadge(
            '%$approvalRate',
            approvalRate >= 70 ? AppColors.success : AppColors.warning,
          ),
        ),
        if (signals.isSilentQuality) ...[
          const Divider(height: 1, color: AppColors.border),
          _CardRow(
            icon: Icons.stars_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.success.withValues(alpha: 0.1),
            title: t.profileSignalSilentQuality,
            subtitle: t.profileMoatSilentQualityHint,
            trailing: _statusBadge(
              '${signals.silentQualityScore}',
              AppColors.success,
            ),
          ),
        ],
      ],
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



