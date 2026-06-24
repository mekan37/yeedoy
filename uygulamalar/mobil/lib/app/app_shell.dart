import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_localizations.dart';
import '../features/shared/ui/components/app_bottom_nav.dart';
import '../features/shared/ui/components/app_drawer.dart';
import '../features/shared/ui/components/app_top_bar.dart';

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
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
        body: Column(
          children: [
            const SafeArea(bottom: false, child: AppTopBar()),
            Expanded(child: widget.child),
          ],
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }
}
