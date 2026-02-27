import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';

const _playStoreUrl = String.fromEnvironment(
  'PLAY_STORE_URL',
  defaultValue: 'https://play.google.com/store/apps/details?id=com.yeedoy.app',
);
const _appStoreUrl = String.fromEnvironment(
  'APP_STORE_URL',
  defaultValue: 'https://apps.apple.com/app/id0000000000',
);
const _webNextUrl = String.fromEnvironment(
  'WEB_NEXT_URL',
  defaultValue: 'http://localhost:3000',
);

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Canli menu, fiyat seffafligi ve topluluk dogrulama platformu.',
                    style: TextStyle(fontSize: 18, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openExternal(_playStoreUrl),
                        icon: const Icon(Icons.android),
                        label: const Text('Google Play'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openExternal(_appStoreUrl),
                        icon: const Icon(Icons.phone_iphone),
                        label: const Text('App Store'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openExternal(_webNextUrl),
                        icon: const Icon(Icons.public),
                        label: const Text('QR Menu Web (Next.js)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Isletme Alani',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Isletme veya admin hesabinla giris yaparak panele eris.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton(
                                onPressed: () => context.go('/isletme-giris'),
                                child: const Text('Isletme Girisi'),
                              ),
                              OutlinedButton(
                                onPressed: () => context.go('/isletme-kayit'),
                                child: const Text('Isletme Kaydi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openExternal(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
