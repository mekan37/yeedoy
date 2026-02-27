import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/app_role_providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import 'app_scaffold.dart';

class OwnerBusinessGuard extends ConsumerWidget {
  const OwnerBusinessGuard({
    super.key,
    required this.businessId,
    required this.builder,
    this.missingBusinessMessage = 'İşletme bulunamadı.',
    this.noAccessMessage = 'Bu işletme için yetkiniz yok.',
  });

  final String businessId;
  final Widget Function(BuildContext context, WidgetRef ref) builder;
  final String missingBusinessMessage;
  final String noAccessMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (businessId.isEmpty) {
      return AppScaffold(body: Center(child: Text(missingBusinessMessage)));
    }

    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login?redirect=$redirect');
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canManageAsync = ref.watch(canManageBusinessProvider(businessId));
    return canManageAsync.when(
      loading: () =>
          const AppScaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => AppScaffold(body: Center(child: Text(noAccessMessage))),
      data: (canManage) {
        if (!canManage) {
          return AppScaffold(body: Center(child: Text(noAccessMessage)));
        }
        return builder(context, ref);
      },
    );
  }
}
