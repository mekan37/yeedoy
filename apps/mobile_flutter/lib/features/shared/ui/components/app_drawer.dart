import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/brand/brand_widgets.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../notifications/domain/inbox_provider.dart';
import 'app_profile_action.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider);
    final t = context.l10n;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.header, AppColors.headerAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const BrandWordmark(height: 24, inverse: true),
            ),
            const Gap(12),
            const AppProfileAction(),
            const Gap(16),
            _Section(
              title: t.discover,
              children: [
                _LinkTile(
                  icon: Icons.explore_outlined,
                  label: t.discover,
                  onTap: () => context.go('/discover'),
                ),
                _LinkTile(
                  icon: Icons.trending_up_outlined,
                  label: t.drawerTopBusinesses,
                  onTap: () => context.go('/top-businesses'),
                ),
              ],
            ),
            const Gap(8),
            _Section(
              title: t.drawerSocial,
              children: [
                _LinkTile(
                  icon: Icons.people_outline,
                  label: t.drawerGourmets,
                  onTap: () => context.go('/gourmets'),
                ),
                _LinkTile(
                  icon: Icons.favorite_outline,
                  label: t.drawerFollowing,
                  onTap: () => context.go('/following'),
                ),
              ],
            ),
            if (FeatureFlags.enableLabs) ...[
              const Gap(8),
              _Section(
                title: t.drawerExperimental,
                children: [
                  _LinkTile(
                    icon: Icons.dynamic_feed_outlined,
                    label: t.drawerFeed,
                    onTap: () => context.go('/feed'),
                  ),
                  _LinkTile(
                    icon: Icons.psychology_outlined,
                    label: t.drawerTasteTwin,
                    onTap: () => context.go('/taste-twin'),
                  ),
                  _LinkTile(
                    icon: Icons.emoji_events_outlined,
                    label: t.drawerHeroes,
                    onTap: () => context.go('/heroes'),
                  ),
                  _LinkTile(
                    icon: Icons.groups_outlined,
                    label: t.drawerGroupRequests,
                    onTap: () => context.go('/group-requests'),
                  ),
                  _LinkTile(
                    icon: Icons.compare_arrows_outlined,
                    label: t.drawerCompare,
                    onTap: () => context.go('/compare'),
                  ),
                ],
              ),
            ],
            if (kDebugMode || AppConfig.devToolsEnabled) ...[
              const Gap(8),
              _Section(
                title: 'Developer',
                children: [
                  _LinkTile(
                    icon: Icons.developer_mode_outlined,
                    label: 'Developer Tools',
                    onTap: () => context.go('/dev-tools'),
                  ),
                ],
              ),
            ],
            const Gap(8),
            _Section(
              title: t.drawerQuickTools,
              children: [
                _LinkTile(
                  icon: Icons.auto_awesome_outlined,
                  label: t.drawerSmartSuggestionShortcut,
                  onTap: () => context.go('/discover'),
                ),
                _LinkTile(
                  icon: Icons.notifications_active_outlined,
                  label: t.priceAlerts,
                  onTap: () => context.go('/profile?tab=alerts'),
                ),
              ],
            ),
            const Gap(8),
            _Section(
              title: t.drawerAccount,
              children: [
                _LinkTile(
                  icon: Icons.favorite_outline,
                  label: t.drawerMyFavorites,
                  onTap: () => context.go('/favorites'),
                ),
                _LinkTile(
                  icon: Icons.person_outline,
                  label: t.profile,
                  onTap: () => context.go('/profile'),
                ),
                _LinkTile(
                  icon: Icons.inbox_outlined,
                  label: unread > 0
                      ? t.drawerInboxWithCount(unread)
                      : t.drawerInbox,
                  onTap: () => context.go('/inbox'),
                ),
                _LinkTile(
                  icon: Icons.lightbulb_outline,
                  label: t.drawerMySuggestions,
                  onTap: () => context.go('/my-suggestions'),
                ),
                _LinkTile(
                  icon: Icons.volunteer_activism_outlined,
                  label: t.drawerSuspendedMeals,
                  onTap: () => context.go('/my-suspended'),
                ),
                _LinkTile(
                  icon: Icons.policy_outlined,
                  label: t.drawerLegalAndTrust,
                  onTap: () => context.go('/legal'),
                ),
              ],
            ),
            const Gap(16),
            Text(
              AppStrings.appName,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Gap(8),
          ...children,
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: AppColors.muted,
      ),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

