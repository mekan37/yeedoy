import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/feature_flags.dart';
import '../core/constants/app_strings.dart';
import '../core/location/user_location_controller.dart';
import '../features/notifications/domain/push_notification_lifecycle_provider.dart';
import '../features/notifications/ui/components/notifications_bell.dart';
import '../src/ui/components/app_appbar.dart';
import '../src/ui/components/app_bottom_nav.dart';
import '../src/ui/components/app_drawer.dart';
import '../src/ui/components/location_picker_sheet.dart';
import '../src/ui/design_system.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushNotificationLifecycleProvider);
    final loc = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: AppAppBar(
        centerTitle: false,
        title: const Text(
          AppStrings.appName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          _LocationPill(
            label: _locationLabel(loc),
            onTap: () => _openLocationSheet(context),
          ),
          if (FeatureFlags.enablePhotoFeed)
            IconButton(
              tooltip: 'Feed',
              icon: const Icon(Icons.dynamic_feed_outlined),
              onPressed: () => context.go('/feed'),
            ),
          IconButton(
            tooltip: 'Bildirim Kutusu',
            onPressed: () => context.go('/inbox'),
            icon: const NotificationsBell(),
          ),
        ],
      ),
      body: child,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(),
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
    if (city.isEmpty && district.isEmpty) return 'Şehir seç';
    if (city.isEmpty) return district;
    if (district.isEmpty) return city;
    return '$district • $city';
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: 6),
            AppChip(label: label, filled: true),
          ],
        ),
      ),
    );
  }
}

