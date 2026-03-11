import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import 'app_empty_state.dart';

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    super.key,
    this.title,
    this.description,
    this.primaryRoute,
    this.primaryLabel,
    this.secondaryRoute,
    this.secondaryLabel,
  });

  final String? title;
  final String? description;
  final String? primaryRoute;
  final String? primaryLabel;
  final String? secondaryRoute;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmptyState(
                icon: Icons.lock_outline,
                title: title ?? l10n.forbiddenTitle,
                description: description ?? l10n.forbiddenDescription,
                ctaLabel: primaryLabel,
                onCta: primaryRoute == null ? null : () => context.go(primaryRoute!),
              ),
              if (secondaryRoute != null && secondaryLabel != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(secondaryRoute!),
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
