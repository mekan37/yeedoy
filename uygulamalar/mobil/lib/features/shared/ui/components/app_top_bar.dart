import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/notifications/ui/components/notifications_bell.dart';
import '../../../../app/theme/app_tokens.dart';

/// Shared in-content top bar for routes that hide [AppAppBar] via
/// `AppShell.hideAppBar`. Renders hamburger (drawer) on the left and the
/// notification bell on the right — identical to the Keşfet top bar.
///
/// Wrap in `SafeArea(bottom: false)` at the call site.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menü',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Bildirim Kutusu',
            onPressed: () => context.go('/inbox'),
            icon: const NotificationsBell(),
          ),
        ],
      ),
    );
  }
}
