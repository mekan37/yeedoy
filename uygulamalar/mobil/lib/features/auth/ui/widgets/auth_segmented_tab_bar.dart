import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/components/app_segmented_tab_bar.dart';

enum AuthSegmentedTab { login, register }

class AuthSegmentedTabBar extends StatelessWidget {
  const AuthSegmentedTabBar({super.key, required this.selectedTab});

  final AuthSegmentedTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabBar(
      labels: const ['Giriş Yap', 'Kayıt Ol'],
      selectedIndex: selectedTab.index,
      onTap: (index) {
        final target = AuthSegmentedTab.values[index];
        if (target == selectedTab) return;

        context.go(_targetPath(context, target));
      },
    );
  }

  String _targetPath(BuildContext context, AuthSegmentedTab target) {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    final path = target == AuthSegmentedTab.login ? '/login' : '/register';
    return Uri(
      path: path,
      queryParameters: redirect == null ? null : {'redirect': redirect},
    ).toString();
  }
}
