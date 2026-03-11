import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../components/permission_denied_view.dart';

class ForbiddenPage extends ConsumerWidget {
  const ForbiddenPage({
    super.key,
    this.panel,
    this.from,
  });

  final String? panel;
  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(userProvider);
    final normalizedPanel = (panel ?? '').trim().toLowerCase();
    final primaryRoute = switch (normalizedPanel) {
      'admin' => user == null ? '/isletme-giris' : '/',
      'owner' => user == null ? '/isletme-giris' : '/owner/businesses',
      _ => '/',
    };
    final primaryLabel = switch (normalizedPanel) {
      'admin' => user == null ? l10n.login : l10n.forbiddenBackHomeAction,
      'owner' => user == null ? l10n.login : l10n.forbiddenGoBusinessesAction,
      _ => l10n.forbiddenBackHomeAction,
    };

    final routeInfo = (from ?? '').trim();
    final description = routeInfo.isEmpty
        ? l10n.forbiddenDescription
        : l10n.forbiddenDescriptionWithRoute(routeInfo);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forbiddenTitle)),
      body: PermissionDeniedView(
        description: description,
        primaryRoute: primaryRoute,
        primaryLabel: primaryLabel,
      ),
    );
  }
}
