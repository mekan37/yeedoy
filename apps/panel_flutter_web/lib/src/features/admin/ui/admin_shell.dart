import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/security/app_role_providers.dart';
import '../../../../features/auth/data/auth_service_provider.dart';
import '../../../../features/auth/domain/auth_providers.dart';
import '../domain/admin_access_provider.dart';
import '../domain/admin_new_items_controller.dart';
import '../domain/admin_permissions.dart';
import '../domain/admin_realtime_lifecycle_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static final List<_AdminEntry> _entries = [
    const _AdminEntry(
      index: 0,
      route: '/admin',
      label: 'Genel Bakış',
      description: 'Admin panel genel görünümü ve hızlı aksiyonlar.',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    const _AdminEntry(
      index: 1,
      route: '/admin/reports',
      label: 'Raporlar',
      description: 'Kullanıcı bildirimlerini incele, durum ve atama yönet.',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      badgeKey: 'reports',
    ),
    const _AdminEntry(
      index: 21,
      route: '/admin/appeals',
      label: 'Itirazlar',
      description: 'Moderasyon kararlarina gelen itirazlari degerlendir.',
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel,
    ),
    const _AdminEntry(
      index: 2,
      route: '/admin/growth',
      label: 'Büyüme',
      description: 'Menü linki ve QR trafiğini günlük bazda takip et.',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
    ),
    const _AdminEntry(
      index: 3,
      route: '/admin/claims',
      label: 'Sahiplik Talepleri',
      description: 'İşletme sahipliği taleplerini onayla ya da reddet.',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
      badgeKey: 'claims',
    ),
    const _AdminEntry(
      index: 4,
      route: '/admin/suspended',
      label: 'Askıda Talepleri',
      description: 'Askıda yemek taleplerini doğrula ve sonuçlandır.',
      icon: Icons.volunteer_activism_outlined,
      selectedIcon: Icons.volunteer_activism,
      badgeKey: 'suspended',
    ),
    const _AdminEntry(
      index: 5,
      route: '/admin/price-suggestions',
      label: 'Fiyat Onayları',
      description: 'Fiyat önerilerini değerlendir, onayla veya reddet.',
      icon: Icons.price_check_outlined,
      selectedIcon: Icons.price_check,
      badgeKey: 'price',
    ),
    const _AdminEntry(
      index: 17,
      route: '/admin/receipt-submissions',
      label: 'Fiş Doğrulama',
      description: 'Fiş doğrulama gönderimlerini listele ve kontrol et.',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    const _AdminEntry(
      index: 6,
      route: '/admin/suggestions',
      label: 'İşletme Önerileri',
      description: 'Yeni işletme önerilerini kontrol edip işleme al.',
      icon: Icons.lightbulb_outline,
      selectedIcon: Icons.lightbulb,
      badgeKey: 'suggestions',
    ),
    const _AdminEntry(
      index: 7,
      route: '/admin/businesses',
      label: 'İşletmeler',
      description: 'İşletme kayıtlarını düzenle, doğrula ve güncelle.',
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
    ),
    const _AdminEntry(
      index: 16,
      route: '/admin/business-submissions',
      label: 'İşletme Başvuruları',
      description: 'Yeni işletme başvurularını onayla veya reddet.',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    const _AdminEntry(
      index: 8,
      route: '/admin/sponsorships',
      label: 'Sponsorlu Gösterimler',
      description: 'Sponsorlu işletme gösterimlerini yönet ve durum değiştir.',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
    ),
    const _AdminEntry(
      index: 9,
      route: '/admin/sponsorship-packages',
      label: 'Paketler',
      description: 'Sponsor paketlerini oluştur ve fiyatlandırmayı yönet.',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    const _AdminEntry(
      index: 10,
      route: '/admin/sponsorship-leads',
      label: 'Leadler',
      description: 'Sponsor satış taleplerini takip et ve kapat.',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
    ),
    const _AdminEntry(
      index: 11,
      route: '/admin/verified',
      label: 'Doğrulama',
      description: 'İşletme doğrulama ve premium statüsünü yönet.',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    const _AdminEntry(
      index: 13,
      route: '/admin/tools/locations',
      label: 'Araçlar > Konumlar',
      description: 'Konum verilerini toplu düzelt ve güncelle.',
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
    ),
    const _AdminEntry(
      index: 14,
      route: '/admin/audit',
      label: 'Denetim Kayıtları',
      description: 'Sistem içi işlem kayıtlarını incele.',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    const _AdminEntry(
      index: 15,
      route: '/admin/table-feedback',
      label: 'Masa Geri Bildirim',
      description: 'Masa QR geri bildirimlerini görüntüle ve filtrele.',
      icon: Icons.table_bar_outlined,
      selectedIcon: Icons.table_bar,
    ),
    const _AdminEntry(
      index: 12,
      route: '/admin/group-requests',
      label: 'Grup Talepleri',
      description: 'Grup yemeği taleplerini ve teklifleri gözlemle.',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
    ),
    const _AdminEntry(
      index: 18,
      route: '/admin/dev-tools',
      label: 'Dev Tools',
      description: 'Feature flag ve test override ayarları.',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
    ),
    const _AdminEntry(
      index: 19,
      route: '/admin/b2b-exports',
      label: 'B2B Veri İhracı',
      description:
          'Anonim trend, bölgesel fiyat endeksi ve menü enflasyonu çıktıları.',
      icon: Icons.dataset_outlined,
      selectedIcon: Icons.dataset,
    ),
    const _AdminEntry(
      index: 20,
      route: '/admin/incidents',
      label: 'Kriz Müdahale',
      description: 'Şeffaf log, hazır cevaplar ve hızlı müdahale aksiyonları.',
      icon: Icons.crisis_alert_outlined,
      selectedIcon: Icons.crisis_alert,
    ),
    const _AdminEntry(
      index: 22,
      route: '/admin/temp-uploads',
      label: 'Geçici yükleme inceleme',
      description: 'Bekleyen gecici menu yuklemelerini incele.',
      icon: Icons.upload_file_outlined,
      selectedIcon: Icons.upload_file,
    ),
  ];

  int _indexFromLocation() {
    for (final entry in _entries) {
      if (location.startsWith(entry.route)) return entry.index;
    }
    return 0;
  }

  List<_AdminEntry> _visibleEntries(AppRole? role) {
    if (role == AppRole.communityMod) {
      return _entries
          .where(
            (entry) => canAccessAdminRoute(AppRole.communityMod, entry.route),
          )
          .toList(growable: false);
    }
    return _entries;
  }

  String _projectRef(String url) {
    if (url.isEmpty) return '-';
    final host = Uri.parse(url).host;
    if (host.isEmpty) return '-';
    final parts = host.split('.');
    return parts.isNotEmpty ? parts.first : host;
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '-';
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  int _badgeCount(String? key, AdminNewItemsState newItems) {
    switch (key) {
      case 'reports':
        return newItems.reportsNew;
      case 'claims':
        return newItems.claimsNew;
      case 'suspended':
        return newItems.suspendedClaimsNew;
      case 'price':
        return newItems.priceSuggestionsNew;
      case 'suggestions':
        return newItems.suggestionsNew;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Text('Bu ekran sadece web üzerinde kullanılabilir.'),
        ),
      );
    }

    final adminAsync = ref.watch(adminAccessProvider);
    final roleAsync = ref.watch(appRoleProvider);
    final user = ref.watch(userProvider);
    final newItems = ref.watch(adminNewItemsProvider);
    ref.watch(adminRealtimeLifecycleProvider);
    final projectRef = _projectRef(dotenv.env['SUPABASE_URL'] ?? '');

    return adminAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Admin erişimi doğrulanamadı.')),
      ),
      data: (hasAccess) {
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('403')),
            body: const Center(child: Text('Bu sayfaya erişim iznin yok.')),
          );
        }

        final role = roleAsync.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
        final visibleEntries = _visibleEntries(role);
        final idx = _indexFromLocation();
        final current =
            visibleEntries.where((entry) {
              return location.startsWith(entry.route);
            }).isNotEmpty
            ? visibleEntries.firstWhere(
                (entry) => location.startsWith(entry.route),
              )
            : visibleEntries.first;

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 260,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    for (final entry in visibleEntries)
                      _AdminNavItem(
                        selected: idx == entry.index,
                        icon: entry.icon,
                        selectedIcon: entry.selectedIcon,
                        label: entry.label,
                        badgeCount: _badgeCount(entry.badgeKey, newItems),
                        onTap: () => context.go(entry.route),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.header, AppColors.headerAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                current.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                'Proje: $projectRef • UID: ${_shortId(user?.id)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            user?.email ?? '-',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Çıkış'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminEntry {
  const _AdminEntry({
    required this.index,
    required this.route,
    required this.label,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    this.badgeKey,
  });

  final int index;
  final String route;
  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final String? badgeKey;
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.primary : AppColors.slate;
    final textColor = selected ? AppColors.textStrong : AppColors.slate;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.borderStrong : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: iconColor,
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+$badgeCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


