import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ayarlar/ozellik_bayraklari.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import 'tasarim_sistemi.dart';

class LabsPage extends ConsumerWidget {
  const LabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    final loggedIn = ref.watch(userProvider.select((user) => user != null));
    final t = context.l10n;

    final entries = <_LabsEntry>[
      if (flags.enablePhotoFeed)
        _LabsEntry(
          title: t.drawerFeed,
          subtitle: t.drawerExperimental,
          route: '/feed',
          icon: Icons.dynamic_feed_outlined,
        ),
      if (flags.enablePhotoFeed)
        _LabsEntry(
          title: t.drawerGourmets,
          subtitle: t.drawerExperimental,
          route: '/gourmets',
          icon: Icons.emoji_events_outlined,
        ),
      if (flags.enablePhotoFeed)
        _LabsEntry(
          title: t.drawerFollowing,
          subtitle: t.drawerExperimental,
          route: '/following',
          icon: Icons.favorite_outline,
          requiresAuth: true,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.budgetComboResultsTitle,
          subtitle: t.drawerExperimental,
          route: '/budget-combos',
          icon: Icons.savings_outlined,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.drawerGroupRequests,
          subtitle: t.drawerExperimental,
          route: '/grup-istekleri',
          icon: Icons.groups_outlined,
          requiresAuth: true,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.drawerTasteTwin,
          subtitle: t.drawerExperimental,
          route: '/taste-twin',
          icon: Icons.psychology_outlined,
          requiresAuth: true,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.drawerHeroes,
          subtitle: t.drawerExperimental,
          route: '/kahramanlar',
          icon: Icons.volunteer_activism_outlined,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.drawerCompare,
          subtitle: t.drawerExperimental,
          route: '/compare',
          icon: Icons.compare_arrows_outlined,
        ),
      if (flags.enableLabs)
        _LabsEntry(
          title: t.suspendedMealsMyClaimsTitle,
          subtitle: t.drawerExperimental,
          route: '/my-suspended',
          icon: Icons.receipt_long_outlined,
          requiresAuth: true,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.drawerExperimental)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: t.discover),
                _StatusChip(label: t.drawerExperimental),
                if (flags.enablePhotoFeed) _StatusChip(label: t.drawerFeed),
                if (flags.enableLabs) _StatusChip(label: t.drawerHeroes),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(entry.icon),
                title: Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  entry.requiresAuth && !loggedIn
                      ? '${entry.subtitle} · ${t.login}'
                      : entry.subtitle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openEntry(
                  context,
                  entry,
                  loggedIn: loggedIn,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (entries.isEmpty)
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: Text(
                  t.drawerExperimental,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(t.discover),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/discover'),
              ),
            ),
        ],
      ),
    );
  }

  void _openEntry(
    BuildContext context,
    _LabsEntry entry, {
    required bool loggedIn,
  }) {
    if (entry.requiresAuth && !loggedIn) {
      final redirect = Uri.encodeComponent(entry.route);
      context.go('/login?redirect=$redirect');
      return;
    }
    context.go(entry.route);
  }
}

class _LabsEntry {
  const _LabsEntry({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    this.requiresAuth = false,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool requiresAuth;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}




