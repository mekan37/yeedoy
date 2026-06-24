import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  // Returns -1 when no standard tab is active (e.g. /contribute).
  int _indexFromLocation(Uri uri) {
    final path = uri.path;
    if (path.startsWith('/discover') && uri.queryParameters['view'] == 'map') {
      return 1;
    }
    if (path.startsWith('/favorites')) return 2;
    if (path.startsWith('/profile')) return 3;
    if (path.startsWith('/discover')) return 0;
    return -1;
  }

  void _goBranch(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/discover');
      case 1:
        context.go('/discover?view=map');
      case 2:
        context.go('/favorites');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return const SizedBox.shrink();
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final idx = _indexFromLocation(uri);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bar background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
              ),
            ),
            // 4 nav items with empty center slot
            Row(
              children: [
                Expanded(
                  child: _NavItem(
                    label: t.discover,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    selected: idx == 0,
                    onTap: () => _goBranch(context, 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: t.map,
                    icon: Icons.map_outlined,
                    selectedIcon: Icons.map_rounded,
                    selected: idx == 1,
                    onTap: () => _goBranch(context, 1),
                  ),
                ),
                // Empty space for the center button
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _NavItem(
                    label: t.favorites,
                    icon: Icons.favorite_outline,
                    selectedIcon: Icons.favorite,
                    selected: idx == 2,
                    onTap: () => _goBranch(context, 2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    label: t.profile,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    selected: idx == 3,
                    onTap: () => _goBranch(context, 3),
                  ),
                ),
              ],
            ),
            // Floating center QR button
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => context.go('/contribute'),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Standard nav item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
