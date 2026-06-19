import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/location/user_location_controller.dart';
import '../../../../core/media/app_image_cache_manager.dart';
import '../../../../core/media/app_network_image.dart';
import '../../../auth/domain/auth_providers.dart';
import '../../../notifications/domain/inbox_provider.dart';
import '../../../taste_twin/domain/taste_twin_controllers.dart';
import '../../../profile/ui/invite_sheet.dart';
import 'location_picker_sheet.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final user = ref.watch(userProvider);
    final loc = ref.watch(userLocationProvider);
    final flags = ref.watch(featureFlagsProvider);
    final unread = ref.watch(inboxUnreadCountProvider);

    final currentPath = GoRouterState.of(context).uri.path;

    String? displayName;
    String? avatarUrl;
    if (user != null) {
      final profile = ref.watch(publicProfileProvider(user.id)).asData?.value;
      final name = profile?.displayName.trim() ?? '';
      displayName = name.isNotEmpty ? name : user.email?.split('@').first;
      final url = profile?.avatarUrl ?? '';
      avatarUrl = url.isNotEmpty ? url : null;
    }

    final locationLabel = [
      loc.city,
      loc.district,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    void close() => Navigator.of(context).pop();
    void go(String path) {
      close();
      context.go(path);
    }

    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => go('/profile'),
              child: Row(
                children: [
                  _Avatar(avatarUrl: avatarUrl, displayName: displayName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba!',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textStrong,
                          ),
                        ),
                        Text(
                          displayName != null
                              ? '$displayName 👋'
                              : t.loginSignupAction,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Location bar ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationLabel.isNotEmpty
                          ? locationLabel
                          : 'Konum seçilmedi',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      close();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const LocationPickerSheet(),
                      );
                    },
                    child: Text(
                      'Değiştir',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Section: Keşfet ──────────────────────────────────────────
            _SectionHeader('Keşfet'),
            const SizedBox(height: 6),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: t.home,
              path: '/',
              currentPath: currentPath,
              onTap: () => go('/'),
            ),
            _DrawerItem(
              icon: Icons.people_outline,
              label: t.smartRecoTitle,
              subtitle: '2 kişi x fiyat',
              path: '/budget-combos',
              currentPath: currentPath,
              onTap: () => go('/budget-combos'),
            ),
            _DrawerItem(
              icon: Icons.notifications_outlined,
              label: t.priceAlerts,
              path: '/price-alerts',
              currentPath: currentPath,
              onTap: () => go('/price-alerts'),
            ),
            _DrawerItem(
              icon: Icons.send_outlined,
              label: t.drawerMySuggestions,
              path: '/my-suggestions',
              currentPath: currentPath,
              onTap: () => go('/my-suggestions'),
            ),
            _DrawerItem(
              icon: Icons.add_circle_outline,
              label: t.suggestBusiness,
              path: '/suggest-business',
              currentPath: currentPath,
              onTap: () => go('/suggest-business'),
            ),
            _DrawerItem(
              icon: Icons.chat_bubble_outline,
              label: unread > 0
                  ? t.drawerInboxWithCount(unread)
                  : t.drawerInbox,
              path: '/inbox',
              currentPath: currentPath,
              onTap: () => go('/inbox'),
            ),
            _DrawerItem(
              icon: Icons.favorite_outline,
              label: t.drawerMyFavorites,
              path: '/favorites',
              currentPath: currentPath,
              onTap: () => go('/favorites'),
            ),
            _DrawerItem(
              icon: Icons.balance_outlined,
              label: t.drawerCompare,
              path: '/compare',
              currentPath: currentPath,
              onTap: () => go('/compare'),
            ),
            if (flags.hasExperimentalNavigation)
              _DrawerItem(
                icon: Icons.science_outlined,
                label: t.drawerExperimental,
                path: '/labs',
                currentPath: currentPath,
                onTap: () => go('/labs'),
              ),

            const SizedBox(height: 20),

            // ── Section: Diğer ──────────────────────────────────────────
            _SectionHeader('Diğer'),
            const SizedBox(height: 6),
            _DrawerItem(
              icon: Icons.location_on_outlined,
              label: 'Konum Seç',
              onTap: () {
                close();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const LocationPickerSheet(),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.search_outlined,
              label: 'Arama & Filtreleme',
              path: '/discover',
              currentPath: currentPath,
              onTap: () => go('/discover'),
            ),
            _DrawerItem(
              icon: Icons.shield_outlined,
              label: t.drawerLegalAndTrust,
              path: '/legal',
              currentPath: currentPath,
              onTap: () => go('/legal'),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: t.settings,
              path: '/profile',
              currentPath: currentPath,
              onTap: () => go('/profile'),
            ),
            if (kDebugMode || AppConfig.devToolsEnabled)
              _DrawerItem(
                icon: Icons.developer_mode_outlined,
                label: 'Developer Tools',
                path: '/dev-tools',
                currentPath: currentPath,
                onTap: () => go('/dev-tools'),
              ),

            const SizedBox(height: 20),

            // ── Invite card ──────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                close();
                final code = (user?.email?.split('@').first ?? 'YEEDOY')
                    .toUpperCase();
                showInviteSheet(context, referralCode: code);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_giftcard_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arkadaşını Davet Et',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Arkadaşını davet et, birlikte kazanın!',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────────────────
            if (user != null)
              GestureDetector(
                onTap: () async {
                  close();
                  await Supabase.instance.client.auth.signOut(
                    scope: SignOutScope.global,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_outlined,
                        size: 20,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        t.logout,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Version ──────────────────────────────────────────────────
            Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl, this.displayName});

  final String? avatarUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: buildAvatarUrl(avatarUrl!, size: 96),
                cacheManager: AppImageCacheManager.instance,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: displayName != null
                  ? Text(
                      displayName![0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.path,
    this.currentPath,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? path;
  final String? currentPath;
  final VoidCallback onTap;

  bool get _isActive =>
      path != null &&
      currentPath != null &&
      (path == '/' ? currentPath == '/' : currentPath!.startsWith(path!));

  @override
  Widget build(BuildContext context) {
    final active = _isActive;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.primary : AppColors.slate,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.textStrong,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
