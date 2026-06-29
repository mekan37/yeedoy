import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../shared/ui/components/community_score_explainer_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/favorite_collections_count_provider.dart';
import '../domain/moat_signals_provider.dart';
import '../domain/profile_stats_provider.dart';
import '../domain/reputation_provider.dart';
import '../domain/user_moat_signals.dart';
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
    final reputationAsync = ref.watch(myReputationScoreProvider);
    final moatSignalsAsync = ref.watch(myMoatSignalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProfileStatsProvider);
        ref.invalidate(myReputationScoreProvider);
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
          // ── Güven ─────────────────────────────────────────────────────
          _CommunityTrustCard(reputationAsync: reputationAsync),
          const SizedBox(height: 12),
          // ── Katkı Profili ────────────────────────────────────────────
          moatSignalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (signals) => signals == null
                ? const SizedBox.shrink()
                : _MoatSignalsCard(signals: signals),
          ),
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
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null,
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

// ── Güven ─────────────────────────────────────────────────────────────────────

class _CommunityTrustCard extends StatelessWidget {
  const _CommunityTrustCard({required this.reputationAsync});

  final AsyncValue<int> reputationAsync;

  @override
  Widget build(BuildContext context) {
    final score = reputationAsync.asData?.value ?? 0;

    return _SectionCardShell(
      children: [
        _CardHeader(
          icon: Icons.shield_outlined,
          iconColor: AppColors.info,
          iconBg: AppColors.info.withValues(alpha: 0.1),
          title: 'Güven',
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
      ],
    );
  }
}

// ── Katkı Profili (Moat Signals) ──────────────────────────────────────────────


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
                onTap: () => context.push('/my-reviews'),
              ),
            ),
            SizedBox(width: tokens.space8),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.dynamic_feed_outlined,
                label: 'Akıllı Akış',
                onTap: () => context.go('/feed'),
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
                onTap: () => context.push('/settings'),
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
                onTap: () => context.push('/settings'),
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
                  t.homeGreetingHelloExclaim,
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
            onPressed: () => context.push('/settings'),
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



