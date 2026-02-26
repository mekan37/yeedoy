import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/constants/app_strings.dart';
import '../../../app/brand/brand_widgets.dart';
import '../../../app/theme/colors.dart';
import '../../../core/security/app_role_providers.dart';
import '../../features/admin/domain/admin_access_provider.dart';
import '../../../features/notifications/domain/inbox_provider.dart';
import 'app_profile_action.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(adminAccessProvider);
    final isOwner = ref.watch(isOwnerProvider).asData?.value ?? false;
    final unread = ref.watch(inboxUnreadCountProvider);
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
            adminAsync.when(
              data: (isAdmin) {
                if (!isAdmin) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8),
                    _Section(
                      title: 'Admin',
                      children: [
                        _LinkTile(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Admin Panel',
                          onTap: () async {
                            if (kIsWeb) {
                              context.go('/admin');
                              return;
                            }
                            final uri = Uri.parse(AppConfig.adminWebUrl);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                        _LinkTile(
                          icon: Icons.table_restaurant_outlined,
                          label: 'Masa Geri Bildirimleri',
                          onTap: () => context.go('/admin/table-feedback'),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const Gap(16),
            _Section(
              title: 'Keşfet',
              children: [
                _LinkTile(
                  icon: Icons.explore_outlined,
                  label: 'Keşfet',
                  onTap: () => context.go('/discover'),
                ),
                _LinkTile(
                  icon: Icons.trending_up_outlined,
                  label: 'Top İşletmeler',
                  onTap: () => context.go('/top-businesses'),
                ),
              ],
            ),
            const Gap(8),
            _Section(
              title: 'Sosyal',
              children: [
                _LinkTile(
                  icon: Icons.people_outline,
                  label: 'Lezzet uzmanları',
                  onTap: () => context.go('/gourmets'),
                ),
                _LinkTile(
                  icon: Icons.favorite_outline,
                  label: 'Takip',
                  onTap: () => context.go('/following'),
                ),
              ],
            ),
            if (FeatureFlags.enableLabs) ...[
              const Gap(8),
              _Section(
                title: 'Deneysel',
                children: [
                  _LinkTile(
                    icon: Icons.dynamic_feed_outlined,
                    label: 'Akış',
                    onTap: () => context.go('/feed'),
                  ),
                  _LinkTile(
                    icon: Icons.psychology_outlined,
                    label: 'Tat eşi',
                    onTap: () => context.go('/taste-twin'),
                  ),
                  _LinkTile(
                    icon: Icons.emoji_events_outlined,
                    label: 'Kahramanlar',
                    onTap: () => context.go('/heroes'),
                  ),
                  _LinkTile(
                    icon: Icons.groups_outlined,
                    label: 'Grup Talepleri',
                    onTap: () => context.go('/group-requests'),
                  ),
                  _LinkTile(
                    icon: Icons.compare_arrows_outlined,
                    label: 'Karşılaştır',
                    onTap: () => context.go('/compare'),
                  ),
                  if (kDebugMode)
                    _LinkTile(
                      icon: Icons.translate_outlined,
                      label: 'Translations',
                      onTap: () => context.go('/labs/translations'),
                    ),
                ],
              ),
            ],
            const Gap(8),
            _Section(
              title: 'Hızlı Araçlar',
              children: [
                _LinkTile(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Akıllı Öneri (2 kişi / 600 TL)',
                  onTap: () => context.go('/discover'),
                ),
                if (isOwner)
                  _LinkTile(
                    icon: Icons.qr_code_2_outlined,
                    label: 'QR Menü Oluştur / Yazdır',
                    onTap: () => context.go('/owner/menus'),
                  ),
                _LinkTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Fiyat Alarmları',
                  onTap: () => context.go('/profile?tab=alerts'),
                ),
              ],
            ),
            const Gap(8),
            _Section(
              title: 'Hesap',
              children: [
                _LinkTile(
                  icon: Icons.favorite_outline,
                  label: 'Favorilerim',
                  onTap: () => context.go('/favorites'),
                ),
                _LinkTile(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  onTap: () => context.go('/profile'),
                ),
                _LinkTile(
                  icon: Icons.inbox_outlined,
                  label: unread > 0
                      ? 'Bildirim Kutusu ($unread)'
                      : 'Bildirim Kutusu',
                  onTap: () => context.go('/inbox'),
                ),
                _LinkTile(
                  icon: Icons.lightbulb_outline,
                  label: 'Önerilerim',
                  onTap: () => context.go('/my-suggestions'),
                ),
                _LinkTile(
                  icon: Icons.verified_outlined,
                  label: 'Başvurularım',
                  onTap: () => context.go('/my-claims'),
                ),
                if (isOwner)
                  _LinkTile(
                    icon: Icons.storefront_outlined,
                    label: 'İşletmelerim',
                    onTap: () => context.go('/owner/businesses'),
                  ),
                _LinkTile(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Askıda',
                  onTap: () => context.go('/my-suspended'),
                ),
                _LinkTile(
                  icon: Icons.policy_outlined,
                  label: 'Yasal ve Güven',
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

