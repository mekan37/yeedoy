import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../design_system.dart';

Future<void> showQuickLoginSheet(
  BuildContext context, {
  String? redirectPath,
}) async {
  final redirectRaw = redirectPath ?? GoRouterState.of(context).uri.toString();
  final redirect = Uri.encodeComponent(redirectRaw);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final t = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.quickLoginTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(t.quickLoginDescription),
              const SizedBox(height: 12),
              AppButton(
                label: t.quickLoginAction,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/login?redirect=$redirect');
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                label: t.notNow,
                fullWidth: true,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
