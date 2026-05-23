import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../masa_siparisleri/domain/masa_siparisi_bildiricisi.dart';

class AnaKabuk extends ConsumerWidget {
  final Widget child;
  const AnaKabuk({super.key, required this.child});

  static const _rotalar = [
    '/siparisler',
    '/dashboard',
    '/menu',
    '/sadakat',
    '/kds',
    '/ayarlar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final konum = GoRouterState.of(context).uri.toString();
    final secili = _rotalar.indexWhere((r) => konum.startsWith(r));
    final bekleyenSayisi = ref.watch(bekleyenSiparisSayisiProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: secili < 0 ? 0 : secili,
        onDestinationSelected: (i) => context.go(_rotalar[i]),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: bekleyenSayisi > 0,
              label: Text('$bekleyenSayisi'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: bekleyenSayisi > 0,
              label: Text('$bekleyenSayisi'),
              child: const Icon(Icons.receipt_long),
            ),
            label: 'Siparişler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Menü',
          ),
          const NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Sadakat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.soup_kitchen_outlined),
            selectedIcon: Icon(Icons.soup_kitchen),
            label: 'Mutfak',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
