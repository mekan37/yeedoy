import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/feature_flags.dart';
import '../core/constants/app_strings.dart';
import '../core/i18n/app_localizations.dart';
import '../core/location/user_location_controller.dart';
import '../features/notifications/ui/components/notifications_bell.dart';
import '../features/shared/ui/components/app_appbar.dart';
import '../features/shared/ui/components/app_bottom_nav.dart';
import '../features/shared/ui/components/app_drawer.dart';
import '../features/shared/ui/components/location_picker_sheet.dart';
import '../features/shared/ui/design_system.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider);
    final loc = ref.watch(userLocationProvider);
    final titleStyle = context.appText.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          // Second tap within 2s — allow exit
          Navigator.of(context).maybePop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).localeName.startsWith('tr')
                  ? 'Çıkmak için tekrar basın'
                  : 'Press back again to exit',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppAppBar(
          centerTitle: false,
          title: Text(AppStrings.appName, style: titleStyle),
          actions: [
            _LocationPill(
              label: _locationLabel(loc),
              onTap: () => _openLocationSheet(context),
            ),
            if (flags.hasExperimentalNavigation)
              IconButton(
                tooltip: 'Labs',
                icon: const Icon(Icons.science_outlined),
                onPressed: () => context.go('/labs'),
              ),
            IconButton(
              tooltip: 'Bildirim Kutusu',
              onPressed: () => context.go('/inbox'),
              icon: const NotificationsBell(),
            ),
          ],
        ),
        body: widget.child,
        drawer: const AppDrawer(),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  static String _locationLabel(UserLocationState loc) {
    final city = (loc.city ?? '').trim();
    final district = (loc.district ?? '').trim();
    if (district.isNotEmpty) return district;
    if (city.isNotEmpty) return city;
    return 'Şehir seç';
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(right: tokens.space4),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 18),
            SizedBox(width: tokens.space4),
            AppChip(label: label, filled: true, compact: true),
          ],
        ),
      ),
    );
  }
}
