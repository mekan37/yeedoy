import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../contribute/ui/contribute_entry.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  int _indexFromLocation(Uri uri) {
    final path = uri.path;
    final mapViewSelected =
        path.startsWith('/discover') && uri.queryParameters['view'] == 'map';
    if (mapViewSelected) return 1;
    if (path.startsWith('/favorites')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }

  void _goBranch(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/discover?view=map');
        break;
      case 2:
        context.go('/favorites');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  void _openQrAction(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.qrAction,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: ContributeFab()),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return const SizedBox.shrink();
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final idx = _indexFromLocation(uri);

    return SafeArea(
      top: false,
      child: Container(
        height: 84,
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
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
                const SizedBox(width: 72),
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
            Positioned(
              top: 6,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _openQrAction(context),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
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
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

