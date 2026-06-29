import 'package:flutter/material.dart';

import '../../../shared/ui/components/app_bottom_nav.dart';
import '../../../shared/ui/components/app_drawer.dart';
import '../../../shared/ui/components/app_top_bar.dart';

class AuthShellScaffold extends StatelessWidget {
  const AuthShellScaffold({
    super.key,
    required this.body,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNav(),
      body: Column(
        children: [
          const SafeArea(bottom: false, child: AppTopBar()),
          Expanded(child: body),
        ],
      ),
    );
  }
}
