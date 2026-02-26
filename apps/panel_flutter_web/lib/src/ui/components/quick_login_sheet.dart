import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Devam etmek için giriş yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bu işlem için hesap gerekiyor. Giriş yapabilir veya şimdi geçebilirsin.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/login?redirect=$redirect');
                  },
                  child: const Text('Hızlı giriş'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Şimdi değil'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

