import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../features/profile/ui/profile_settings_page.dart';
import '../../features/owner_businesses/domain/owner_business_providers.dart';
import '../../features/owner_businesses/domain/owner_business_state.dart';

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAccessAsync = ref.watch(isOwnerProvider);
    return ownerAccessAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _forbidden(context),
      data: (canAccess) {
        if (!canAccess) return _forbidden(context);
        return _buildAuthorizedShell(context, ref);
      },
    );
  }

  Widget _buildAuthorizedShell(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 1024;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _OwnerSidebar(location: location),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  const _OwnerHeader(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('İşletme Paneli')),
      drawer: const _OwnerDrawer(),
      body: child,
    );
  }

  Widget _forbidden(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('403')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu sayfaya erişim izniniz yok.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/discover'),
              child: const Text('Keşfet sayfasına dön'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerHeader extends ConsumerWidget {
  const _OwnerHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(ownerBusinessesProvider);
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);

    businessesAsync.whenData((items) {
      if (selectedId == null && items.isNotEmpty) {
        ref.read(selectedOwnerBusinessIdProvider.notifier).state =
            items.first.businessId;
      }
    });

    return Container(
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
          const Text(
            'İşletme Paneli',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: businessesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                final current = selectedId ?? items.first.businessId;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<String>(
                      initialValue: current,
                      iconEnabledColor: Colors.white,
                      dropdownColor: AppColors.card,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      items: [
                        for (final b in items)
                          DropdownMenuItem(
                            value: b.businessId,
                            child: Text('${b.businessName} - ${b.district}'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        ref
                                .read(selectedOwnerBusinessIdProvider.notifier)
                                .state =
                            value;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          TextButton.icon(
            onPressed: () => context.go('/owner/businesses'),
            icon: const Icon(Icons.storefront_outlined, color: Colors.white),
            label: const Text(
              'İşletmelerim',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerSidebar extends ConsumerWidget {
  const _OwnerSidebar({required this.location});
  final String location;

  int _indexFromLocation() {
    if (location.startsWith('/owner/businesses')) return 1;
    if (location.startsWith('/owner/menus')) return 2;
    if (location.startsWith('/owner/price-suggestions')) return 3;
    if (location.startsWith('/owner/suspended')) return 4;
    if (location.startsWith('/owner/requests')) return 5;
    if (location.startsWith('/owner/perks')) return 6;
    if (location.startsWith('/owner/audit')) return 7;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _indexFromLocation();
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);
    return SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _OwnerNavItem(
            selected: idx == 0,
            icon: Icons.dashboard_outlined,
            label: 'Genel Bakış',
            onTap: () => context.go('/owner'),
          ),
          _OwnerNavItem(
            selected: idx == 1,
            icon: Icons.storefront_outlined,
            label: 'İşletmelerim',
            onTap: () => context.go('/owner/businesses'),
          ),
          _OwnerNavItem(
            selected: idx == 2,
            icon: Icons.menu_book_outlined,
            label: 'Menü Yönetimi',
            onTap: () => context.go('/owner/menus'),
          ),
          _OwnerNavItem(
            selected: idx == 3,
            icon: Icons.price_check_outlined,
            label: 'Fiyat Önerileri',
            onTap: () => _goBusinessRoute(
              context,
              '/owner/price-suggestions',
              selectedId,
            ),
          ),
          _OwnerNavItem(
            selected: idx == 4,
            icon: Icons.volunteer_activism_outlined,
            label: 'Askıda Talepleri',
            onTap: () =>
                _goBusinessRoute(context, '/owner/suspended', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 5,
            icon: Icons.groups_outlined,
            label: 'Talepler',
            onTap: () => context.go('/owner/requests'),
          ),
          _OwnerNavItem(
            selected: idx == 6,
            icon: Icons.card_giftcard_outlined,
            label: 'İkram/Kampanya',
            onTap: () => _goBusinessRoute(context, '/owner/perks', selectedId),
          ),
          _OwnerNavItem(
            selected: idx == 7,
            icon: Icons.receipt_long_outlined,
            label: 'Denetim',
            onTap: () => context.go('/owner/audit'),
          ),
          _OwnerNavItem(
            selected: false,
            icon: Icons.settings_outlined,
            label: 'Profil Ayarları',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _goBusinessRoute(BuildContext context, String base, String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      context.go('/owner/businesses');
      return;
    }
    context.go('$base?businessId=$businessId');
  }
}

class _OwnerDrawer extends ConsumerWidget {
  const _OwnerDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedOwnerBusinessIdProvider);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'İşletme Paneli',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Genel Bakış'),
              onTap: () => context.go('/owner'),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('İşletmelerim'),
              onTap: () => context.go('/owner/businesses'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Menü Yönetimi'),
              onTap: () => context.go('/owner/menus'),
            ),
            ListTile(
              leading: const Icon(Icons.price_check_outlined),
              title: const Text('Fiyat Önerileri'),
              onTap: () => _goBusinessRoute(
                context,
                '/owner/price-suggestions',
                selectedId,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Askıda Talepleri'),
              onTap: () =>
                  _goBusinessRoute(context, '/owner/suspended', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Talepler'),
              onTap: () => context.go('/owner/requests'),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('İkram/Kampanya'),
              onTap: () =>
                  _goBusinessRoute(context, '/owner/perks', selectedId),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Denetim'),
              onTap: () => context.go('/owner/audit'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Profil Ayarları'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goBusinessRoute(BuildContext context, String base, String? businessId) {
    if (businessId == null || businessId.isEmpty) {
      context.go('/owner/businesses');
      return;
    }
    context.go('$base?businessId=$businessId');
  }
}

class _OwnerNavItem extends StatelessWidget {
  const _OwnerNavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
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
