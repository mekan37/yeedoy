import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/security/app_role_providers.dart';
import '../../../core/security/business_rbac.dart';
import '../../../features/auth/domain/auth_providers.dart';
import 'app_scaffold.dart';
import 'owner_panel_feedback.dart';
import 'permission_denied_view.dart';

class OwnerBusinessGuard extends ConsumerWidget {
  const OwnerBusinessGuard({
    super.key,
    required this.businessId,
    required this.builder,
    this.permission = BusinessPermission.businessWrite,
    this.missingBusinessMessage,
    this.noAccessMessage,
  });

  final String businessId;
  final Widget Function(BuildContext context, WidgetRef ref) builder;
  final BusinessPermission permission;
  final String? missingBusinessMessage;
  final String? noAccessMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (businessId.isEmpty) {
      return AppScaffold(
        body: PermissionDeniedView(
          title: l10n.ownerNoBusinessPermissionTitle,
          description:
              missingBusinessMessage ?? l10n.ownerBusinessSelectionRequiredDescription,
          primaryRoute: '/owner/businesses',
          primaryLabel: l10n.ownerGoBusinessesAction,
        ),
      );
    }

    final user = ref.watch(userProvider);
    if (user == null) {
      final redirect = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/isletme-giris?redirect=$redirect');
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final permissionAsync = ref.watch(
      hasBusinessPermissionProvider((businessId, permission)),
    );
    return permissionAsync.when(
      loading: () => const AppScaffold(body: OwnerPanelFeedback.loading()),
      error: (_, _) => AppScaffold(
        body: PermissionDeniedView(
          title: l10n.ownerNoBusinessPermissionTitle,
          description: noAccessMessage ?? l10n.ownerNoBusinessPermissionDescription,
          primaryRoute: '/owner/businesses',
          primaryLabel: l10n.ownerGoBusinessesAction,
        ),
      ),
      data: (hasPermission) {
        if (!hasPermission) {
          return AppScaffold(
            body: PermissionDeniedView(
              title: l10n.ownerNoBusinessPermissionTitle,
              description:
                  noAccessMessage ?? l10n.ownerNoBusinessPermissionDescription,
              primaryRoute: '/owner/businesses',
              primaryLabel: l10n.ownerGoBusinessesAction,
            ),
          );
        }
        return builder(context, ref);
      },
    );
  }
}
