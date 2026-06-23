import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnaKabuk extends ConsumerWidget {
  final Widget child;
  const AnaKabuk({super.key, required this.child});

  // MVP scope: masa siparişi/POS, KDS (mutfak) ve sadakat sekmeleri gizlendi
  // (final stratejik karar raporu §4 — POS/adisyon ve gamification MVP-dışı).
  // Route'lar korunuyor ama navigasyondan kaldırıldı.
  static const _rotalar = [
    '/dashboard',
    '/menu',
    '/ayarlar',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final konum = GoRouterState.of(context).uri.toString();
    final secili = _rotalar.indexWhere((r) => konum.startsWith(r));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: secili < 0 ? 0 : secili,
        onDestinationSelected: (i) => context.go(_rotalar[i]),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Menü',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
